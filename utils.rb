require 'bundler/setup'

require 'csv'

require 'active_model'
require 'pupa'
require 'zip/zip'

class GovernmentProcessor < Pupa::Processor
  def unzip(url)
    Tempfile.open('pupa') do |f|
      f.binmode
      f.write(get(url))
      f.rewind

      Zip::ZipFile.open(f) do |zipfile|
        yield zipfile
      end
    end
  end
end

class Pupa::Person
  include ActiveModel::Validations

  validates_inclusion_of :honorific_prefix, in: %w(Monsieur Madame)
  validates_format_of :email, with: /\A[a-z.-]+@ville.montreal.qc.ca\z/, allow_blank: true
  validates_format_of :image, with: %r{\Ahttp://ville.montreal.qc.ca/pls/portal/docs/PAGE/COLLECTIONS_GENERALES/MEDIA/Images/Public/[\w-]+\.(?:JPG|jpg)\z}
  validates_inclusion_of :gender, in: %w(male female)
  validate :validate_contact_details

  def validate_contact_details
    contact_details.each do |contact_detail|
      case contact_detail[:type]
      when 'voice', 'fax'
        if contact_detail[:value]['poste']
          contact_detail[:value].sub!(/\A(\d{3}).(\d{3}).(\d{4}),? poste (\d+)\z/, '\1-\2-\3 x\4')
        else
          contact_detail[:value].sub!(/\A(\d{3}).(\d{3}).(\d{4})\z/, '\1-\2-\3')
        end
      when 'address'
        # Normalize newlines, and remove commas and spaces at line endings.
        contact_detail[:value] = contact_detail[:value].split(/[, ]*\r\n/).join("\n")
        # Normalize whitespace, apostrophes and province.
        contact_detail[:value].squeeze!(' ')
        contact_detail[:value].gsub!('’', "'")
        contact_detail[:value].sub!(/, Québec\b/, ' (Québec)')
        # Remove unnecessary address parts.
        contact_detail[:value].sub!(/Bureau des élus de (?:Pointe-aux-Trembles|Rivière-des-Prairies)\n/, '')
        # Add a comma after the street number.
        contact_detail[:value].sub!(/\A(\d+) /, '\1, ')
        # Correct typographical errors.
        contact_detail[:value].sub!(/\bLasalle\b/, 'LaSalle')
        contact_detail[:value].sub!(/\nbureau\b/, 'Bureau')
        contact_detail[:value].sub!(/\bQu\.bec\b/, 'Québec')
        # Add a new line before the city and province line.
        contact_detail[:value].sub!(/ (?=(?:Anjou|L'Île-Bizard|Lachine|LaSalle|Montréal|Montréal-Nord|Outremont|Pierrefonds|Saint-Laurent|Saint-Léonard) \(Québec\))/, "\n")
      end
    end

    contact_details.each do |contact_detail|
      case contact_detail[:type]
      when 'voice', 'fax'
        unless contact_detail[:value][/\A514-\d{3}-\d{4}(?: x\d+)?\z/]
          errors.add(:contact_details, "contain an invalid phone number: #{contact_detail[:value]}")
        end
      when 'email'
        unless contact_detail[:value][/\A[a-z.-]+@ville.montreal.qc.ca\z/]
          errors.add(:contact_details, "contain an invalid email address: #{contact_detail[:value]}")
        end
      when 'address'
        unless contact_detail[:value][/\A[\dAB-]+, (?:avenue|boul\.|boulevard|ch\.|montée|rue) [^\n]+(?:\n\d+e étage|\n(?:Bureau|Suite) [\dAB.-]+)?\n(?:Anjou|L'Île-Bizard|Lachine|LaSalle|Montréal|Montréal-Nord|Outremont|Pierrefonds|Saint-Laurent|Saint-Léonard) \(Québec\)\nH[0-9][ABCEGHJKLMNPRSTVWXYZ] [0-9][ABCEGHJKLMNPRSTVWXYZ][0-9]\z/]
          errors.add(:contact_details, "contain an invalid address: #{contact_detail[:value]}")
        end
      end
    end
  end
end

class Pupa::Membership
  attr_reader :person, :post
  foreign_object :person, :post
  dump :person, :post

  def person=(person)
    @person = {_type: 'pupa/person'}.merge(symbolize_keys(person))
  end

  def post=(post)
    @post = {_type: 'pupa/post'}.merge(symbolize_keys(post))
  end
end

class Pupa::Post
  attr_accessor :area, :position
  dump :area, :position

  def fingerprint
    super.slice(:label, :organization_id, :end_date, :position) # add position
  end
end
