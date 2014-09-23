require 'bundler/setup'

require 'csv'

require 'active_support/core_ext/integer/inflections'
require 'active_support/time'
require 'active_model'
require 'dalli'
require 'fog'
require 'multi_xml'
require 'nokogiri'
require 'pupa'
require 'redis-store'
require 'hiredis'
require 'zip/zip'
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
          contact_detail[:value].sub!(/\A(\d{3}).(\d{3}).(\d{4}),? poste (\d+)\z/, '\1-\2-\3 x\4')
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

# Stores data downloads on AWS.
#
# @see ActiveSupport::Cache::FileStore
class AWSStore < Pupa::Processor::DocumentStore::FileStore
  # @param [String] bucket the AWS bucket in which to store data
  # @param [String] output_dir the directory in which to download data
  # @param [String] aws_access_key_id an AWS access key ID
  # @param [String] aws_secret_access_key an AWS secret access key
  # @see http://fog.io/storage/#using-amazon-s3-and-fog
  def initialize(bucket, output_dir, aws_access_key_id, aws_secret_access_key)
    @connection = Fog::Storage.new(provider: 'AWS', aws_access_key_id: aws_access_key_id, aws_secret_access_key: aws_secret_access_key, path_style: true)
    @bucket = @connection.directories.get(output_dir)
  end

  # Returns whether a file with the given name exists.
  #
  # @param [String] name a key
  # @return [Boolean] whether the store contains an entry for the given key
  # @see http://fog.io/storage/#checking-if-a-file-already-exists
  def exist?(name)
    !!@bucket.files.head(name)
  end

  # Returns all file names in the storage directory.
  #
  # @return [Array<String>] all keys in the store
  def entries
    @bucket.files.map(&:key)
  end

  # Returns the contents of the file with the given name.
  #
  # @param [String] name a key
  # @return [Hash] the value of the given key
  # @see http://fog.io/storage/#backing-up-your-files
  def read(name)
    @bucket.files.get(name).body
  end

  # Writes the value to a file with the given name.
  #
  # @param [String] name a key
  # @param [Hash,String] value a value
  # @see http://fog.io/storage/#using-amazon-s3-and-fog
  def write(name, value)
    @bucket.files.new(key: name, body: value, public: true).save
  end

  # Delete a file with the given name.
  #
  # @param [String] name a key
  # @see http://fog.io/storage/#cleaning-up
  def delete(name)
    @bucket.files.get(name).destroy
  end

  # Deletes all files in the storage directory.
  def clear
    @connection.delete_multiple_objects(@bucket.key, entries)
  end
end
