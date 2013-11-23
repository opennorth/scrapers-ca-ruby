require File.expand_path(File.join('..', 'utils.rb'), __dir__)

class Montreal < GovernmentProcessor
  attr_reader :organization_ids

  def initialize(*args)
    super

    @organization_ids ||= {}
  end

  # @return [Hash] a hash in which keys are Élection Montréal numeric
  #   identifiers and values are OCD type IDs
  def boroughs_by_number
    @boroughs_by_number ||= begin
      {}.tap do |hash|
        CSV.parse(get('https://raw.github.com/opencivicdata/ocd-division-ids/master/mappings/country-ca-numeric/ca_qc_montreal_arrondissements.csv').force_encoding('UTF-8')) do |row|
          hash[row[1].to_i] = row[0].split(':').last
        end
      end
    end
  end

  # @return [Hash] a hash in which keys are names and values are OCD type IDs
  def boroughs_by_name
    @boroughs_by_name ||= begin
      {}.tap do |hash|
        CSV.parse(get('https://raw.github.com/opencivicdata/ocd-division-ids/master/identifiers/country-ca/census_subdivision-montreal-arrondissements.csv').force_encoding('UTF-8')) do |row|
          hash[row[1]] = row[0].split(':').last
        end
      end
    end
  end
end

require_relative 'organizations'
require_relative 'posts'
require_relative 'people'

GovernmentProcessor.add_scraping_task(:organizations)
GovernmentProcessor.add_scraping_task(:posts)
GovernmentProcessor.add_scraping_task(:people)

Pupa::Runner.new(Montreal, {
  database: 'mycityhall',
  expires_in: 604800, # 1 week
}).run(ARGV)
