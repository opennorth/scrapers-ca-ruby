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
    to_h.slice(:docDate_date, :docNumber)
  end

  def to_s
    docTitle
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
  # @return [Integer] the label for the speech
  attr_accessor :heading
  # @return [Integer] the label for the number of the heading or speech
  attr_accessor :num
  # @return [Integer] the number of the heading or speech
  attr_accessor :num_title
  # @return [Time] a local time
  attr_accessor :time
  # @return [String] the label for the person speaking
  attr_accessor :from
  # @return [String] the role of the person speaking
  attr_accessor :from_as
  # @return [String] the ID of the person speaking
  attr_accessor :from_id
  # @return [String] the label for the person being spoken to
  attr_accessor :to
  # @return [String] the role of the person being spoken to
  attr_accessor :to_as
  # @return [String] the ID of the person being spoken to
  attr_accessor :to_id
  # @return [String] the HTML of the paragraph
  attr_accessor :html
  # @return [String] a clean version of the paragraph
  attr_accessor :text
  # @return [Boolean] whether the speech is a division
  attr_accessor :division
  # @return [Boolean] whether the speaker's name was hyperlinked
  attr_accessor :fuzzy
  # @return [String] the ID of the debate to which this speech belongs
  attr_accessor :debate_id

  dump :index, :element, :heading, :num, :num_title, :time, :from, :from_as, :from_id, :to, :to_as, :to_id, :html, :text, :division, :fuzzy, :debate_id
  foreign_key :debate_id, :from_id

  validates_numericality_of :index
  validates_inclusion_of :element, in: %w(answer narrative other question recordedTime speech), allow_blank: true
  validates_presence_of :debate_id

  def fingerprint
    to_h.slice(:index, :debate_id)
  end

  def to_s
    "#{from}: #{html}"
  end
end
