require File.expand_path(File.join('..', 'utils.rb'), __dir__)

require_relative 'constants'

=begin
export TWITTER_CONSUMER_KEY=...
export TWITTER_CONSUMER_SECRET=...
ruby ca/scraper.rb -q -a update -a scrape -a import -a update

We first discover Twitter screen names from party websites, and then assign an
ID if none is set. We then use the IDs to keep the screen names up-to-date.

The following users are not found on the party websites and have no tweets.

* alicewongcanada
* bobdechert
* emichaudnpd
* gordbrown
* maximebernier
* peterstoffermp
* stellaambler
* tomlukiwski
=end

class TwitterUser
  include Pupa::Model

  attr_accessor :id, :screen_name, :name

  dump :id, :screen_name, :name

  def fingerprint
    {
      screen_name: Regexp.new(Regexp.escape(screen_name), 'i'),
    }
  end

  def to_s
    screen_name
  end
end

class Canada < Pupa::Processor
  TIMEOUT_DELAY = 5

  # The Bloc Québécois, Green Party and Independents are done manually. Several
  # MPs are not linked from their party websites and are done manually.
  def scrape_manual
    MANUAL_SCREEN_NAMES.each do |screen_name|
      dispatch(TwitterUser.new(screen_name: screen_name))
    end
  end

  def scrape_conservative
    get('http://www.conservative.ca/team/members-of-parliament/').xpath('//option').each do |option|
      get("http://www.conservative.ca/team/members-of-parliament/?pr=#{option[:value].gsub(' ', '+')}").xpath('//a[@class="mpname"]').each do |a|
        url = get(a[:href]).at_xpath('//div[@id="sidebar"]//a[@target="_blank"]')[:href]
        if url.empty?
          warn("No URL found at #{a[:href]}")
        else
          if URI.parse(url).path.empty?
            url += '/'
          end
          process(url, backup_url: BACKUP_URLS[url])
        end
      end
    end
  end

  def scrape_liberal
    get('http://www.liberal.ca/mp/').xpath('//table//td[1]//a[string(@href)]').each do |a|
      backup_url = "http://#{a[:href].split('/')[-1].gsub('-', '')}.liberal.ca"
      url = get(a[:href]).at_xpath('//a[@target="_blank"]')
      if url
        # Remove the incorrect "www." part of liberal.ca subdomains.
        url = url[:href].sub(/www\.(?=\w+\.liberal\.ca)/, '')
        if url == backup_url
          process(url)
        else
          process(url, backup_url: backup_url)
        end
      else
        process(backup_url)
      end
    end
  end

  def scrape_ndp
    get('http://www.ndp.ca/ourcaucus').xpath('//table//a').each do |a|
      process(a[:href])
    end
  end

  def update
    connection.raw_connection[:twitter_users].find(screen_name: {'$in' => NON_MP_SCREEN_NAMES + SCREEN_NAME_MAP.keys}).remove_all

    names = JSON.parse(Faraday.get('https://represent.opennorth.ca/representatives/house-of-commons/?limit=0').body)['objects'].map do |object|
      object['name']
    end

    # Collect screen names of Twitter users without a Twitter ID.
    screen_names = connection.raw_connection[:twitter_users].find(id: {'$exists' => false}).map do |user|
      user['screen_name']
    end

    # Set a Twitter user's ID if none is set.
    screen_names.each_slice(100) do |slice|
      begin
        users = twitter.users(*slice)
        (slice.map(&:downcase) - users.map{|user| user.screen_name.downcase}).each do |screen_name|
          warn("Not found #{screen_name}")
        end
        users.each do |user|
          connection.raw_connection[:twitter_users].find(screen_name: Regexp.new(Regexp.escape(user.screen_name), 'i')).update('$set' => {id: user.id.to_s})
        end
      rescue Twitter::Error::NotFound
        warn("Not found #{slice.join(', ')}")
      end
    end

    # Collect Twitter IDs.
    ids = connection.raw_connection[:twitter_users].find(id: {'$exists' => true}).map do |user|
      user['id'].to_i
    end

    # Update screen names of Twitter users with Twitter IDs.
    ids.each_slice(100) do |slice|
      users = twitter.users(*slice)
      (slice.map(&:to_s) - users.map{|user| user.id.to_s}).each do |id|
        connection.raw_connection[:twitter_users].find(id: id).update('$unset' => {id: ''})
      end
      users.each do |user|
        name = user.name.
          # Remove prefix.
          sub(/\A(?:Dr\.|Hon\.|Ministre) /, '').
          # Remove parenthetical.
          sub(/ \([^)]+\)/, '').
          # Remove suffixes.
          sub(/,.+/, '').
          sub(/(?:député\/)?M\.?P\.?/, '').
          sub(/ (?:NDP|NPD)\b/, '').
          sub(/ \d+/, '').
          # Remove infix initials.
          sub(/ [A-Z]\./, '').
          # Remove Chinese characters. https://twitter.com/joycemurray
          gsub(/[^A-ZÇÉÈÎÔa-zçéèîô'. -]/, '').
          squeeze(' ').
          strip.
          # Remove ending punctuation.
          sub(/\.\z/, '')

        # Some Twitter names have no spaces between words, but don't split "MacKay".
        name = name.split(/ |(?<=[a-z]{3})(?=[A-Z])|(?<=\.)(?! )/).map do |part|
          if part[/[A-ZÇÉÈÎÔ]/]
            part
          else
            part.capitalize
          end
        end.join(' ')

        # Some Twitter names are irrecoverably malformed.
        name = TWITTER_NAME_MAP.fetch(name, name)

        connection.raw_connection[:twitter_users].find(id: user.id.to_s).update('$set' => {
          screen_name: user.screen_name,
          name: name,
        })

        unless names.include?(name)
          warn("Not an MP: #{name} https://twitter.com/#{user.screen_name}")
          connection.raw_connection[:twitter_users].find(screen_name: user.screen_name).remove_all
        end
        if user.statuses_count.zero?
          warn("No tweets #{user.screen_name}")
        elsif user.status.created_at < Time.now - 31556940 # 1 year
          warn("Old tweets #{user.screen_name}")
        end
        unless user.verified?
          info("Not verified #{user.screen_name}")
        end
      end
    end

    # Delete any Twitter users that were not found.
    connection.raw_connection[:twitter_users].find(id: {'$exists' => false}).remove_all
  end

private

  def twitter
    @twitter ||= Twitter::REST::Client.new do |config|
      config.consumer_key = ENV['TWITTER_CONSUMER_KEY']
      config.consumer_secret = ENV['TWITTER_CONSUMER_SECRET']
    end
  end

  # Dispatches a TwitterUser.
  def process(url, backup_url: nil, visited: [])
    if url
      begin
        last_url = URI.parse(url)

        if last_url.path.empty?
          last_url.path = '/'
        end

        if visited.include?(last_url.to_s) && backup_url
          last_url = URI.parse(backup_url)
        end

        url = last_url.to_s

        # @note The redirection loop (either here or below) sometimes false-positives...
        if visited.include?(url)
          return warn("Redirection loop #{url}: #{visited.join(', ')}")
        end
        visited << url
        response = client.get do |req|
          req.url url
          req.options.timeout = TIMEOUT_DELAY
          req.options.open_timeout = TIMEOUT_DELAY
        end

        # Loop until we no longer have redirects.
        begin
          new_url = nil

          # Check for a redirect.
          if [301, 302, 303].include?(response.status)
            new_url = response.headers.fetch('Location')
          elsif response.env[:raw_body][/^window\.location="([^"]+)";$/] # http://www.johnmckayliberal.ca
            new_url = $1
          elsif response.body # www.merrifieldmp.com has no body
            meta = response.body.at_xpath('//meta[translate(@http-equiv,"ABCDEFGHIJKLMNOPQRSTUVWXYZ","abcdefghijklmnopqrstuvwxyz")="refresh"]')
            if meta
              new_url = meta[:content].match(/url=(.+)/i)[1]
            end
          end

          # If a redirect is found.
          if new_url
            parsed = URI.parse(new_url)
            parsed.scheme ||= last_url.scheme
            parsed.host ||= last_url.host
            parsed.port ||= last_url.port
            parsed.fragment ||= last_url.fragment
            last_url = parsed

            if last_url.port == 80
              last_url.port = nil
            end
            if last_url.path == ''
              last_url.path = '/'
            end

            if visited.include?(last_url.to_s) && backup_url
              last_url = URI.parse(backup_url)
            end

            new_url = last_url.to_s

            if visited.include?(new_url)
              return warn("Redirection loop #{new_url}: #{visited.join(', ')}")
            end
            visited << new_url
            response = client.get do |req|
              req.url new_url
              req.options.timeout = TIMEOUT_DELAY
              req.options.open_timeout = TIMEOUT_DELAY
            end
          end
        end while new_url

        doc = response.body

        if doc
          # * <area> tag on http://www.johnmckayliberal.ca
          as = doc.xpath('//*[contains(@href,"twitter.com/")]')

          # * empty data-via attribute on http://www.charmaineborg.info
          # * "twitter-user" if highlighting another user in a tweet
          a = as.reject do |a|
            a['href']['twitter.com/share'] && a['data-via'].blank? || a['class'] == 'twitter-user' || a['href']['?q='] || BAD_SCREEN_NAMES.include?(get_screen_name(a))
          end.first

          screen_name = nil
          if a
            screen_name = get_screen_name(a)
          elsif response.env[:raw_body][/\.setUser\('([^']+)'\)/]
            screen_name = $1.downcase
          elsif backup_url
            process(backup_url, visited: visited)
          end

          if screen_name
            dispatch(TwitterUser.new(screen_name: SCREEN_NAME_MAP.fetch(screen_name, screen_name)))
          end
        else
          warn("Unhandled redirect or empty body #{url}")
        end
      rescue Faraday::ConnectionFailed, Faraday::TimeoutError, Errno::ETIMEDOUT
        backup_url ||= if url['mp.ca'] # http://www.lauriehawnmp.ca
          url.sub(/mp(?=\.ca\b)/, '')
        elsif url['.ca'] # http://www.bradbutt.ca
          url.sub(/(?=\.ca\b)/, 'mp')
        elsif url['.com'] # http://www.blainecalkinsmp.com
          url.sub('.com', '.ca')
        end

        if backup_url
          process(backup_url, visited: visited)
        else
          error("Server not found #{url}")
        end
      rescue Faraday::ClientError => e
        # 5xx errors occur regularly, so we downgrade to warning to limit email alerts.
        warn("#{e.class} #{e.message} #{url}")
      end
    end
  end

  def get_screen_name(a)
    screen_name = a['href'].match(%r{twitter.com/(?:#!/)?@?(\w*)})[1]
    if screen_name == 'share' && a['data-via']
      screen_name = a['data-via'].sub(/\A@/, '')
    end
    screen_name.downcase
  end
end

Canada.add_scraping_task(:manual)
Canada.add_scraping_task(:conservative)
Canada.add_scraping_task(:liberal)
Canada.add_scraping_task(:ndp)

options = {
  database_url: ENV['MONGOLAB_URI'] || 'mongodb://localhost:27017/pupa',
  expires_in: 604800, # 1 week
}

if ENV['REDISCLOUD_URL']
  options[:output_dir] = ENV['REDISCLOUD_URL']
end

if ENV['MEMCACHIER_SERVERS']
  options[:cache_dir] = "memcached://#{ENV['MEMCACHIER_SERVERS']}"
  options[:memcached_username] = ENV['MEMCACHIER_USERNAME']
  options[:memcached_password] = ENV['MEMCACHIER_PASSWORD']
end

runner = Pupa::Runner.new(Canada, options)

runner.add_action(name: 'update', description: 'Update Twitter screen names')
runner.run(ARGV)
