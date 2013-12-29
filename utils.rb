require 'bundler/setup'

require 'csv'

require 'active_model'
require 'nokogiri'
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

  validates_inclusion_of :gender, in: %w(male female)

  # @note Montreal-specific.
  validates_inclusion_of :honorific_prefix, in: %w(Monsieur Madame)
  validates_format_of :email, with: /\A[a-z.-]+@ville.montreal.qc.ca\z/, allow_blank: true
  validates_format_of :image, with: %r{\Ahttp://ville.montreal.qc.ca/pls/portal/docs/PAGE/COLLECTIONS_GENERALES/MEDIA/Images/Public/[\w-]+\.(?:JPG|jpg)\z}
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
    super.slice(:label, :organization_id, :end_date, :position) # adds position
  end
end

class Document
  include Pupa::Model
  include Pupa::Concerns::Timestamps
  include Pupa::Concerns::Sourceable
  include ActiveModel::Validations

  attr_accessor :date, :description, :title, :organization_id
  dump :date, :description, :title, :organization_id

  # @note Montreal-specific.
  validates_inclusion_of :description, in: [
    'Assemblée extraordinaire',
    'Assemblée ordinaire',
    'Assemblée spéciale',
    'Séance extraordinaire',
    'Séance ordinaire',
    'Séance spéciale',
  ]

  def fingerprint
    {date: date, 'sources.url' => source_url}
  end

  def source_url
    sources[0][:url]
  end

  def to_s
    source_url
  end
end

# Stores data downloads on disk.
#
# @see ActiveSupport::Cache::FileStore
class DownloadStore
  # @param [String] output_dir the directory in which to download data
  def initialize(output_dir)
    @output_dir = output_dir
    FileUtils.mkdir_p(@output_dir)
  end

  # Returns whether a file with the given name exists.
  #
  # @param [String] name a key
  # @return [Boolean] whether the store contains an entry for the given key
  def exist?(name)
    File.exist?(path(name))
  end

  # Returns all file names in the storage directory.
  #
  # @return [Array<String>] all keys in the store
  def entries
    Dir.chdir(@output_dir) do
      Dir['*']
    end
  end

  # Returns the contents of the file with the given name.
  #
  # @param [String] name a key
  # @return [Hash] the value of the given key
  def read(name)
    File.open(path(name)) do |f|
      f.read
    end
  end

  # Returns the contents of the files with the given names.
  #
  # @param [String] names keys
  # @return [Array<Hash>] the values of the given keys
  def read_multi(names)
    names.map do |name|
      read(name)
    end
  end

  # Writes the value to a file with the given name.
  #
  # @param [String] name a key
  # @param [Hash,String] value a value
  def write(name, value)
    File.open(path(name), 'w') do |f|
      f.write(value)
    end
  end

  # Writes the value to a file with the given name, unless such a file exists.
  #
  # @param [String] name a key
  # @param [Hash] value a value
  # @return [Boolean] whether the key was set
  def write_unless_exists(name, value)
    !exist?(name).tap do |exists|
      write(name, value) unless exists
    end
  end

  # Writes the values to files with the given names.
  #
  # @param [Hash] pairs key-value pairs
  def write_multi(pairs)
    pairs.each do |name,value|
      write(name, value)
    end
  end

  # Delete a file with the given name.
  #
  # @param [String] name a key
  def delete(name)
    File.delete(path(name))
  end

  # Deletes all files in the storage directory.
  def clear
    Dir[File.join(@output_dir, '*')].each do |path|
      File.delete(path)
    end
  end

  # Collects commands to run all at once.
  def pipelined
    yield
  end

  # Returns the path to the file with the given name.
  #
  # @param [String] name a key
  # @param [String] a path
  def path(name)
    File.join(@output_dir, name)
  end
end
