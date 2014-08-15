require File.expand_path(File.join('..', 'utils.rb'), __dir__)

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
    to_h.slice(:screen_name)
  end

  def to_s
    screen_name
  end
end

class Canada < GovernmentProcessor
  # The Bloc Québécois, Green Party and Independents are done manually. Several
  # MPs are not linked from their party websites and are done manually.
  def scrape_manual
    screen_names = %w(
      andrebellavance
      claude_patry
    ) + # Bloc Québécois
    %w(
      brucehyer
      elizabethmay
    ) + # Green Party
    %w(
      brentrathgeber
      mpdeandelmastro
      fortjf
      mperreaultnpd
    ) + # Independent
    %w(
      bradtrostcpc
      brianstorseth
      f_lapointe
      galipeauorleans
      gschellenberger
      keithashfield11
      mackaycpc
      petergoldring
    ) + # Inactive, also davidmcguinty from scrape_liberal
    %w(
      barrydevolin_mp
      bryanhayesmp
      christianparad
      danalbas
      davidtilson
      honrobnicholson
      jacquesgourde
      jayaspinmp
      joe_preston
      joycebatemanmp
      kellyblockcpc
      leonaaglukkaq
      mpeveadams
      mpmikea
      pierrepoilievre
      pmharper
      scottreidcpc
      shellyglovermin
      susantruppe
      terenceyoungmp
    ) + # Conservative
    %w(
      honstephanedion
      judyfootemp
      scottandrewsmp
    ) + # Liberal
    %w(
      fboivinnpd
      jtremblaynpd
      thomasmulcair
    ) # NDP

    screen_names.each do |screen_name|
      dispatch(TwitterUser.new(screen_name: screen_name))
    end
  end


  def scrape_conservative
    get('http://www.conservative.ca/?page_id=35').xpath('//option').each do |option|
      get("http://www.conservative.ca/?page_id=35&lang=en&pr=#{option[:value].gsub(' ', '+')}").xpath('//a[@class="mpname"]').each do |a|
        url = get(a[:href]).at_xpath('//div[@id="sidebar"]//a[@target="_blank"]')[:href]
        if url.empty?
          warn("No URL found at #{a[:href]}")
        else
          twitter_url(url)
        end
      end
    end
  end

  def scrape_liberal
    get('http://www.liberal.ca/mp/').xpath('//table//td[1]//a').each do |a|
      url = get(a[:href]).at_xpath('//a[@target="_blank"]')
      if url
        twitter_url(url[:href].sub(/www\.(?=\w+\.liberal\.ca)/, ''), backup_url: "http://#{a[:href].split('/')[-1].gsub('-', '')}.liberal.ca/")
      else
        warn("No URL found at #{a[:href]}")
      end
    end
  end

  def scrape_ndp
    get('http://www.ndp.ca/ourcaucus').xpath('//table//a').each do |a|
      twitter_url(a[:href])
    end
  end

  def update
    names = JSON.parse(Faraday.get('http://represent.opennorth.ca/representatives/house-of-commons/?limit=0').body)['objects'].map do |object|
      object['name']
    end

    # Set the ID if none is set.
    arguments = connection.raw_connection[:twitter_users].find(id: {'$exists' => false}).map do |user|
      user['screen_name']
    end

    arguments.each_slice(100) do |slice|
      twitter.users(*slice).each do |user|
        connection.raw_connection[:twitter_users].find(screen_name: Regexp.new(user.screen_name, 'i')).update('$set' => {id: user.id.to_s})
      end
    end

    # Update the screen name.
    arguments = connection.raw_connection[:twitter_users].find.map do |user|
      user['id'].to_i
    end

    arguments.each_slice(100) do |slice|
      twitter.users(*slice).each do |user|
        name = user.name.
          # Remove prefix.
          sub(/\A(?:Dr|Hon)\. /, '').
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
          gsub(/[^A-ZÉÈÎa-zçéèô'. -]/, '').
          squeeze(' ').strip

        # Some Twitter names have no spaces between words. Don't split "MacKay".
        name = name.split(/ |(?<=[a-z]{3})(?=[A-Z])|(?<=\.)(?! )/).map do |part|
          if part[/[A-ZÉÈÎ]/]
            part
          else
            part.capitalize
          end
        end.join(' ')

        name = TWITTER_NAME_MAP.fetch(name, name)

        connection.raw_connection[:twitter_users].find(id: user.id.to_s).update('$set' => {
          screen_name: user.screen_name,
          name: name,
        })

        unless names.include?(name)
          error("Not an MP: #{name} https://twitter.com/#{user.screen_name}")
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
  end

private

  TWITTER_NAME_MAP = {
    'Alexandrine' => 'Alexandrine Latendresse',
    'Anne Minh Thu Quach' => 'Anne Minh-Thu Quach',
    'Elaine Michaud' => 'Élaine Michaud',
    'Genest-Jourdain' => 'Jonathan Genest-Jourdain',
    'Gord Brown' => 'Gordon Brown',
    'Jinny Sims' => 'Jinny Jogindera Sims',
    'Marjolaine Boutin-S.' => 'Marjolaine Boutin-Sweet',
    'Moore Christine' => 'Christine Moore',
    'T. Benskin' => 'Tyrone Benskin',
  }

  def twitter
    @twitter ||= Twitter::REST::Client.new do |config|
      config.consumer_key = ENV['TWITTER_CONSUMER_KEY']
      config.consumer_secret = ENV['TWITTER_CONSUMER_SECRET']
    end
  end

  BAD_SCREEN_NAME = [
    # Twitter
    'search',
    'share',
    # Conservative
    'pmharper', # http://www.robertgoguen.ca
    'pmwebupdates',
    'socdevsoc',
    # Liberal
    'liberal_party',
    'parti_liberal',
    'm_ignatieff', # http://dominicleblanc.liberal.ca
  ]

  # The official party websites have errors.
  SCREEN_NAME_MAP = {
    'dianeablonczymp' => 'dianeablonczy',
    'edholdermp' => 'edholder_mp',
    'jayaspin' => 'jayaspinmp',
    'joyce_bateman' => 'joycebatemanmp',
    'judyfoote' => 'judyfootemp',
    'justinpjtrudeau' => 'justintrudeau',
    'npdlavallesiles' => 'francoispilon',
    'sdionliberal' => 'honstephanedion',
  }

  def twitter_url(url, backup_url: nil)
    if url
      begin
        response = client.get do |req|
          req.url url
          req.options.timeout = 5
          req.options.open_timeout = 5
        end

        last_url = URI.parse(url)
        begin
          new_url = nil
          if [301, 302, 303].include?(response.status)
            new_url = response.headers.fetch('Location')
          elsif response.env[:raw_body][/^window\.location="([^"]+)";$/] # http://www.johnmckayliberal.ca
            new_url = $1
          elsif meta = response.body.at_xpath('//meta[translate(@http-equiv,"ABCDEFGHIJKLMNOPQRSTUVWXYZ","abcdefghijklmnopqrstuvwxyz")="refresh"]')
            new_url = meta[:content].match(/url=(.+)/i)[1]
          end
          if new_url
            parsed = URI.parse(new_url)
            parsed.scheme ||= last_url.scheme
            parsed.host ||= last_url.host
            response = client.get(parsed.to_s)
            last_url = parsed
          end
        end while new_url

        doc = response.body

        if doc
          # * <area> tag on http://www.johnmckayliberal.ca
          # * empty data-via attribute on http://www.charmaineborg.info
          # * "twitter-user" if highlighting another user in a tweet
          a = doc.xpath('//*[contains(@href,"twitter.com/")]').reject do |a|
            a[:href]['twitter.com/share'] && a['data-via'].blank? || a[:class] == 'twitter-user' || a[:href]['/search/']
          end.first

          screen_name = nil
          if a
            screen_name = a['href'].match(%r{twitter.com/(?:#!/)?@?(\w+)})[1]
            if screen_name == 'share' && a['data-via']
              screen_name = a['data-via'].sub(/\A@/, '')
            end
          elsif response.env[:raw_body][/\.setUser\('([^']+)'\)/]
            screen_name = $1
          elsif backup_url
            twitter_url(backup_url)
          end
          if screen_name
            screen_name.downcase!
            if BAD_SCREEN_NAME.include?(screen_name)
              warn("Ignoring #{screen_name} at #{url}")
            else
              dispatch(TwitterUser.new(screen_name: SCREEN_NAME_MAP.fetch(screen_name, screen_name)))
            end
          end
        else
          warn("Unhandled redirect #{url}")
        end
      rescue Faraday::ConnectionFailed
        if backup_url
          twitter_url(backup_url)
        elsif url['mp.ca'] # http://www.lauriehawnmp.ca
          twitter_url(url.sub(/mp(?=\.ca\b)/, ''))
        elsif url['.ca'] # http://www.bradbutt.ca
          twitter_url(url.sub(/(?=\.ca\b)/, 'mp'))
        elsif url['.com'] # http://www.blainecalkinsmp.com
          twitter_url(url.sub('.com', '.ca'))
        else
          error("Server not found #{url}")
        end
      rescue Faraday::TimeoutError, Errno::ETIMEDOUT
        error("Timeout #{url}")
      end
    end
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

runner.add_action(name: 'id', description: 'Set Twitter user IDs, if not set')
runner.add_action(name: 'update', description: 'Update Twitter screen names')
runner.run(ARGV)
