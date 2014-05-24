require File.expand_path(File.join('..', 'utils.rb'), __dir__)

class NovaScotia < GovernmentProcessor
  def initialize(*args)
    super

    # A map between speaker names and URLs, for cases where we have only a name,
    # and to have consistent URLs for names.
    @speaker_urls = {}

    # A map between URLs and person IDs.
    @speaker_ids = {}
  end
end

class Debate
  include Pupa::Model
  include Pupa::Concerns::Timestamps
  include Pupa::Concerns::Sourceable
  include ActiveModel::Validations

  attr_accessor :name, :docTitle, :docNumber, :docDate, :docDate_date,
    :docProponent, :legislature, :legislature_value, :session, :session_value
  dump :name, :docTitle, :docNumber, :docDate, :docDate_date,
    :docProponent, :legislature, :legislature_value, :session, :session_value

  def fingerprint
    to_h.slice(:docNumber)
  end

  def to_s
    docTitle
  end
end

class Section
  include Pupa::Model
  include Pupa::Concerns::Timestamps
  include ActiveModel::Validations

  attr_accessor :identifier, :heading, :section_id
  attr_reader :section

  dump :identifier, :heading, :section_id, :section

  foreign_key :section_id
  foreign_object :section

  validates_presence_of :heading

  def fingerprint
    to_h.slice(:identifier, :section_id)
  end

  def to_s
    heading
  end
end

class Speech
  include Pupa::Model
  include Pupa::Concerns::Timestamps
  include ActiveModel::Validations

  # @return [Integer] the index of the paragraph within the debate
  attr_accessor :index
  # @return [String] the Akoma Ntoso element for the paragraph
  attr_accessor :element
  # @return [Time] a local time
  attr_accessor :time
  # @return [String] the label for the person speaking
  attr_accessor :from
  # @return [String] the HTML of the paragraph
  attr_accessor :html
  # @return [String] a clean version of the paragraph
  attr_accessor :text
  # @return [Boolean] whether the speech is a voting division
  attr_accessor :division
  # @return [Boolean] whether the speaker's name was hyperlinked
  attr_accessor :fuzzy
  # @return [String] the ID of the person speaking
  attr_accessor :person_id
  # @return [String] the ID of the debate to which this speech belongs
  attr_accessor :debate_id

  dump :index, :element, :time, :from, :html, :text, :division, :fuzzy, :person_id, :debate_id
  foreign_key :debate_id, :person_id

  validates_numericality_of :index
  validates_inclusion_of :element, in: %w(recordedTime speech narrative other), allow_blank: true
  validates_presence_of :debate_id

  def person=(person)
    @person = {_type: 'pupa/person'}.merge(person)
  end

  def fingerprint
    to_h.slice(:index, :debate_id)
  end

  def to_s
    "#{from}: #{html}"
  end
end

require_relative 'constants'
require_relative 'people'
require_relative 'speeches'

NovaScotia.add_scraping_task(:people)
NovaScotia.add_scraping_task(:speeches)

runner = Pupa::Runner.new(NovaScotia, {
  database_url: 'mongodb://localhost:27017/sayit',
  expires_in: 604800, # 1 week
})
runner.run(ARGV)
