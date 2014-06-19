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
  # @return [Integer] the heading's number
  attr_accessor :num_title
  # @return [Time] a local time
  attr_accessor :time
  # @return [String] the label for the person speaking
  attr_accessor :from
  # @return [String] the ID of the person speaking
  attr_accessor :from_id
  # @return [String] the label for the person being spoken to
  attr_accessor :to
  # @return [String] the ID of the person being spoken to
  attr_accessor :to_id
  # @return [String] the HTML of the paragraph
  attr_accessor :html
  # @return [String] a clean version of the paragraph
  attr_accessor :text
  # @return [Boolean] whether the speech is a division or a resolution
  attr_accessor :note
  # @return [Boolean] whether the speaker's name was hyperlinked
  attr_accessor :fuzzy
  # @return [String] the ID of the debate to which this speech belongs
  attr_accessor :debate_id

  dump :index, :element, :num_title, :time, :from, :from_id, :to, :to_id, :html, :text, :note, :fuzzy, :debate_id
  foreign_key :debate_id, :from_id

  validates_numericality_of :index
  validates_inclusion_of :element, in: %w(recordedTime speech narrative other), allow_blank: true
  validates_presence_of :debate_id

  def fingerprint
    to_h.slice(:index, :debate_id)
  end

  def to_s
    "#{from}: #{html}"
  end
end