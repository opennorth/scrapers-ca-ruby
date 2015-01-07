require 'bundler/setup'

require 'csv'

require 'active_support/core_ext/integer/inflections'
require 'active_support/time'
require 'active_model'
require 'dalli'
require 'multi_xml'
require 'nokogiri'
require 'pupa'
require 'redis-store'
require 'hiredis'
require 'unicode_utils'
require 'twitter'

class Pupa::Membership
  attr_reader :person, :post
  dump :person, :post
  foreign_object :person, :post

  def person=(person)
    @person = {_type: 'pupa/person'}.merge(symbolize_keys(person))
  end

  def post=(post)
    @post = {_type: 'pupa/post'}.merge(symbolize_keys(post))
  end
end

class Pupa::Person
  include ActiveModel::Validations

  validates_inclusion_of :gender, in: %w(male female)
  validate :validate_voice_and_fax

  def validate_voice_and_fax
    contact_details.each do |contact_detail|
      if %w(voice fax).include?(contact_detail[:type])
        if contact_detail[:value]['poste']
          contact_detail[:value].sub!(/\A(\d{3}).(\d{3}).(\d{4}),?\sposte (\d+)\z/, '\1-\2-\3 x\4')
        else
          contact_detail[:value].sub!(/\A(\d{3}).(\d{3}).(\d{4})\z/, '\1-\2-\3')
        end

        unless contact_detail[:value][/\A514-\d{3}-\d{4}(?: x\d+)?\z/]
          errors.add(:contact_details, "contain an invalid phone number: #{contact_detail[:value]}")
        end
      end
    end
  end
end

class Pupa::Post
  include Pupa::Concerns::Identifiable

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

  # @see http://www.w3.org/TR/vocab-dcat/#Property:distribution_size
  # @see http://dublincore.org/documents/dcmi-terms/#terms-date
  # @see http://schema.org/numberOfPages
  # @see http://dublincore.org/documents/dcmi-terms/#terms-description
  # @see http://schema.org/text
  # @see http://dublincore.org/documents/dcmi-terms/#terms-title
  attr_accessor :byte_size, :date, :description, :number_of_pages, :text, :title, :organization_id
  dump :byte_size, :date, :description, :text, :number_of_pages, :title, :organization_id

  # A single document may contain minutes of multiple meetings.
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
class DownloadStore < Pupa::Processor::DocumentStore::FileStore
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

  # Writes the value to a file with the given name.
  #
  # @param [String] name a key
  # @param [Hash,String] value a value
  def write(name, value)
    File.open(path(name), 'w') do |f|
      f.write(value)
    end
  end

  # Deletes all files in the storage directory.
  def clear
    Dir[File.join(@output_dir, '*')].each do |path|
      File.delete(path)
    end
  end

  # Returns the byte size of the file.
  #
  # @param [String] name a key
  # @return [Integer] the file size in bytes
  def size(name)
    File.size(path(name))
  end
end
