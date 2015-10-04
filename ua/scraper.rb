# coding: utf-8
require File.expand_path(File.join('..', 'utils.rb'), __dir__)

class RegistryEntry
  include Pupa::Model

  attr_accessor :name, :organization_name, :membership_label, :description, :timespan

  dump :name, :organization_name, :membership_label, :description, :timespan

  def fingerprint
    to_h
  end

  def to_s
    name
  end
end

class Check
  include Pupa::Model

  attr_accessor :type, :identifier, :data

  dump :type, :identifier, :data

  def fingerprint
    to_h.slice(:type, :identifier)
  end

  def to_s
    data.values.join('/')
  end
end

class Translation
  include Pupa::Model

  attr_accessor :text, :language, :en, :response

  dump :text, :language, :en, :response

  def fingerprint
    to_h.slice(:text, :language)
  end

  def to_s
    text[0, 100]
  end
end

class Ukraine < Pupa::Processor
  def scrape_register_entries
    map = {
      # Last name, first name, middle name
      "Прізвище, ім'я, по батькові" => :name,
      # Affiliation
      'Місце роботи' => :organization_name,
      # Position on the application of the provisions of the Law of Ukraine "On cleaning power"
      'Посада на час застосування положення Закону України «Про очищення влади»' => :membership_label,
      # Information on the test results
      'Відомості про результати перевірки' => :description,
      # The time during which a person covered by the prohibition of the Law of Ukraine "On cleaning power"
      'Час протягом якого на особу поширюється заборона, передбачена Законом України "Про очищення влади"' => :timespan,
    }

    get('http://lustration.minjust.gov.ua/register/open_list').xpath('//span').each do |span|
      doc = post('http://lustration.minjust.gov.ua/register/open', {
        fio: span.attributes.fetch('data_name').value,
        date: span.attributes.fetch('data_date').value,
      })

      data = {}
      key = nil
      value = nil
      expected = 'th'
      doc.xpath('//th|//td').each do |node|
        unless expected == node.name
          error("expected node #{expected}, got #{node.name}")
        end
        case node.name
        when 'th'
          key = map.fetch(node.text)
          expected = 'td'
        when 'td'
          data[key] = node.text.strip
          expected = 'th'
        end
      end

      dispatch(RegistryEntry.new(data))
    end
  end

  def scrape_checks
    list = get('http://lustration.minjust.gov.ua/main/checking')
    { 'acting2' => 'acting',
      'applicants2' => 'applicants',
    }.each do |id,path|
      list.xpath(%(//div[@id="#{id}"]//tr/@data-bind)).each do |attribute|
        detail = get("http://lustration.minjust.gov.ua/checking/#{path}/#{attribute.value}")

        data = {}
        detail.xpath('//table[contains(@class,"table")]//tr').each do |tr|
          value = tr.xpath('./td[2]').text.strip
          data[tr.xpath('./td[1]').text] = case value
          when /\A\d{2}.\d{2}.\d{4}\z/
            Date.strptime(value, '%d.%m.%Y')
          when '-'
            nil
          else
            value
          end
        end
        dispatch(Check.new(type: path, identifier: attribute.value, data: data))
      end
    end
  end

  def scrape_translations
    max_attempts = 5
    translations = connection.raw_connection['translations']
    register_entries = connection.raw_connection['registry_entries']

    register_entries.find.each do |entry|
      entry.except('_id', '_type').each do |_,value|
        unless translations.find(text: value).first
          attempts = 0
          begin
            response = client.post do |request|
              request.url 'https://www.googleapis.com/language/translate/v2'
              request.headers['X-HTTP-Method-Override'] = 'GET'
              request.body = {
                key: ENV['API_KEY'],
                q: value,
                source: 'uk',
                target: 'en',
              }
            end
            
            dispatch(Translation.new({
              text: value,
              language: 'uk',
              en: response.body['data']['translations'][0]['translatedText'],
              response: response.body,
            }))
          rescue Faraday::ClientError => e
            # Note that the quota in the console is measured in characters, not in requests as displayed.
            # @see https://console.developers.google.com/project/
            if e.response[:body]['error']['errors'].any?{|error| error['reason'] == 'userRateLimitExceeded'} && attempts < max_attempts
              # @see https://developers.google.com/analytics/devguides/reporting/core/v3/coreErrors#backoff
              delay = 2 ** attempts + rand
              warn("sleeping #{delay.round(1)}s")
              sleep delay
              attempts += 1
              retry
            else
              error(e.response[:body])
              raise
            end
          end
        end
      end
    end
  end

  def print
    connection.raw_connection['translations'].find.each do |translation|
      puts "#{translation['text'].ljust(100)} #{translation['en']}"
    end
  end

  def csv
    messages = Set.new
    { 'registry_entries' => [
        'name',
        'organization_name',
        'membership_label',
        'description',
        'timespan',
      ],
      'checks' => [
        'type',
        'identifier',
        'Регіон',
        'Категорія органу перевірки',
        'Назва органу перевірки',
        'Реквізити рішення про проведення перевірки',
        'ПІБ особи, щодо якої здійснюється перевірка',
        'Посада',
        'Дата подання Заяви про застосування заборон, визначених законом', # "acting" only
        'Дата подання Заяви про не застосування заборон, визначених законом',
        'Повідомлення керівника органу про початок проведення перевірки', # "acting" only
        'Дата надання запиту для перевірки',
        'Орган, до якого направлено запит',
        'Дата отримання відповіді на запит',
        'Висновок про результати перевірки',
        'Сканкопія заяви',
        'Сканкопія декларації',
      ],
    }.each do |collection_name,keys|
      CSV.open(File.expand_path(File.join('.', "#{collection_name}.csv"), __dir__), 'wb') do |csv|
        query = connection.raw_connection[collection_name].find
        csv << keys
        query.each do |object|
          data = get_data(collection_name, object)
          csv << keys.map{|key| data[key]}
          unless data.keys == keys
            message = "unrecognized keys: #{data.keys - keys}, missing keys: #{keys - data.keys}"
            unless messages.include?(message)
              error(message)
              messages.add(message)
            end
          end
        end
      end
    end
  end

private

  def get_data(collection_name, object)
    if collection_name == 'checks'
      object.slice('type', 'identifier').merge(object['data'])
    else
      object.except('_id', '_type')
    end
  end
end

Ukraine.add_scraping_task(:register_entries)
Ukraine.add_scraping_task(:checks)
Ukraine.add_scraping_task(:translations)

options = {
  database_url: ENV['MONGOLAB_URI'] || 'mongodb://localhost:27017/pupa',
}

runner = Pupa::Runner.new(Ukraine, options)

runner.add_action(name: 'print', description: 'Print translations.')
runner.add_action(name: 'csv', description: 'Export CSVs.')

runner.run(ARGV)

__END__
Feb 25
16:00-17:30 1.5
Feb 26
01:20-02:20 1
Mar 9
13:35-14:20 0.75
