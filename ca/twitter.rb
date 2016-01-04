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

class Canada
  TIMEOUT_DELAY = 5

  # The Bloc Québécois, Green Party and Independents are done manually. Several
  # MPs are not linked from their party websites and are done manually.
  def scrape_manual
    MANUAL_SCREEN_NAMES.each do |screen_name|
      dispatch(TwitterUser.new(screen_name: screen_name))
    end

    SCREEN_NAME_MAP_COPY.each do |screen_name|
      info("Can delete #{screen_name} from SCREEN_NAME_MAP")
    end

    NON_MP_SCREEN_NAMES_COPY.each do |screen_name|
      info("Can delete #{screen_name} from NON_MP_SCREEN_NAMES")
    end
  end

  def scrape_conservative
    Nokogiri::HTML(get('http://www.conservative.ca/?member=mps')).xpath('//a[contains(@class,"team-list-person-block")]').each do |a|
      process(a['data-website'])
    end
  end

  def scrape_liberal
    get('http://www.liberal.ca/mp/').xpath('//a[starts-with(@href,"http")][div[@class="icon-twitter"]]').each do |a|
      dispatch(TwitterUser.new(screen_name: get_screen_name(a)))
    end
  end

  def scrape_ndp
    get('http://www.ndp.ca/team').xpath('//a[@class="candidate-twitter"]').each do |a|
      dispatch(TwitterUser.new(screen_name: get_screen_name(a)))
    end
  end

  def update
    connection.raw_connection[:twitter_users].find(screen_name: {'$in' => NON_MP_SCREEN_NAMES + SCREEN_NAME_MAP.keys}).delete_many

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
          connection.raw_connection[:twitter_users].find(screen_name: Regexp.new(Regexp.escape(user.screen_name), 'i')).update_one('$set' => {id: user.id.to_s})
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
        connection.raw_connection[:twitter_users].find(id: id).update_one('$unset' => {id: ''})
      end

      users.each do |user|
        name = user.name.
          # Remove prefix.
          sub(/\A(?:Dr\.|Elect\b|Hon\b\.?|Ministre\b) ?/, '').
          # Remove parenthetical.
          sub(/ \([^)]+\)/, '').
          # Remove suffixes.
          sub(/,.+/, '').
          sub(/(?:député\/)?M\.?P\.?/, '').
          sub(/ ?(?:NDP|NPD)\b/, '').
          sub(/ \d+/, '').
          # Remove infix initials.
          sub(/ [A-Z]\./, '').
          # Remove Chinese characters. https://twitter.com/joycemurray
          gsub(/[^A-ZÇÉÈÜÎÔa-zçéèëîô'. -]/, '').
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
        TWITTER_NAME_MAP_COPY.delete(name)
        name = TWITTER_NAME_MAP.fetch(name, name)

        connection.raw_connection[:twitter_users].find(id: user.id.to_s).update_one('$set' => {
          screen_name: user.screen_name,
          name: name,
        })

        unless names.include?(name)
          warn("Not an MP: #{name} https://twitter.com/#{user.screen_name}")
          connection.raw_connection[:twitter_users].find(screen_name: user.screen_name).delete_many
        end
        if user.statuses_count.zero?
          warn("No tweets #{user.screen_name}")
        elsif user.status.created_at < Time.now - 31556940 # 1 year
          if user.verified?
            info("Old tweets #{user.screen_name} (verified)")
          else
            warn("Old tweets #{user.screen_name}")
          end
        end
        unless user.verified?
          screen_name = user.screen_name.downcase
          if MANUAL_SCREEN_NAMES.include?(screen_name) || SCREEN_NAME_MAP.values.include?(screen_name)
            info("Not verified https://twitter.com/#{user.screen_name} (manual source)")
          else
            debug("Not verified https://twitter.com/#{user.screen_name}")
          end
        end
      end
    end

    # Delete any Twitter users that were not found.
    connection.raw_connection[:twitter_users].find(id: {'$exists' => false}).delete_many

    TWITTER_NAME_MAP_COPY.each do |name|
      info("Can delete #{name} from TWITTER_NAME_MAP")
    end
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
    if url && !url.empty?
      begin
        unless url[/\Ahttp/]
          url = "http://#{url}"
        end

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
            a['href']['twitter.com/share'] && a['data-via'].blank? || a['class'] == 'twitter-user' || a['href']['?q='] ||
              ((screen_name = get_screen_name(a)) && NON_MP_SCREEN_NAMES.include?(screen_name) && (NON_MP_SCREEN_NAMES_COPY.delete(screen_name) || true))
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
            SCREEN_NAME_MAP_COPY.delete(screen_name)
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
    screen_name.downcase!
    SCREEN_NAME_MAP_COPY.delete(screen_name)
    SCREEN_NAME_MAP.fetch(screen_name, screen_name)
  end
end
