require 'bundler/setup'

require 'csv'

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

class Pupa::Membership
  attr_reader :person, :post
  foreign_object :person, :post
  dump :person, :post

  def person=(person)
    @person = {_type: 'pupa/person'}.merge(person)
  end

  def post=(post)
    @post = {_type: 'pupa/post'}.merge(post)
  end
end

class Pupa::Post
  attr_accessor :area
  dump :area
end
