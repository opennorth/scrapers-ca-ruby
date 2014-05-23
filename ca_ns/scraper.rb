require File.expand_path(File.join('..', 'utils.rb'), __dir__)

class Debate
  include Pupa::Model
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
  include ActiveModel::Validations

  attr_accessor :index, :time, :from, :html, :text, :division, :person_id, :debate_id
  attr_reader :person

  dump :index, :time, :from, :html, :text, :division, :person_id, :debate_id, :person

  foreign_key :debate_id, :person_id
  foreign_object :person

  validates_numericality_of :index
  validates_presence_of :text

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

class NovaScotia < GovernmentProcessor
end

require_relative 'people'
require_relative 'speeches'

NovaScotia.add_scraping_task(:people)
NovaScotia.add_scraping_task(:speeches)

runner = Pupa::Runner.new(NovaScotia, {
  database: 'mycityhall',
  expires_in: 604800, # 1 week
})
runner.run(ARGV)
