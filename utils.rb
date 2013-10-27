require 'bundler/setup'

require 'csv'

require 'htmlentities'
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

class Pupa::Post
  attr_accessor :area
  dump :area
end
