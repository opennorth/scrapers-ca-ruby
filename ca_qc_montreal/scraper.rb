require File.expand_path(File.join('..', 'utils.rb'), __dir__)

class Pupa::Person
  EMAIL_RE = /\A[A-Za-z.-]+@(?:sympatico|ville\.montreal\.qc)\.ca\z/
  BOROUGH_RE = /Anjou|L'[Îî]le-Bizard|Lachine|LaSalle|Montréal|Montréal-Nord|Outremont|Pierrefonds|Saint-Laurent|Saint-Léonard|Verdun/
  POSTAL_CODE_RE = /H[0-9][ABCEGHJKLMNPRSTVWXYZ] [0-9][ABCEGHJKLMNPRSTVWXYZ][0-9]/

  validates_inclusion_of :honorific_prefix, in: %w(Monsieur Madame)
  validates_format_of :email, with: EMAIL_RE, allow_blank: true
  validates_format_of :image, with: %r{\Ahttp://ville.montreal.qc.ca/pls/portal/docs/PAGE/COLLECTIONS_GENERALES/MEDIA/Images/Public/[\w-]+\.(?:JPG|jpg)\z}, allow_blank: true
  validate :validate_email_and_address

  def validate_email_and_address
    contact_details.each do |contact_detail|
      case contact_detail[:type]
      when 'email'
        unless contact_detail[:value][EMAIL_RE]
          errors.add(:contact_details, "contain an invalid email address: #{contact_detail[:value]}")
        end
      when 'address'
        contact_detail[:value].sub!(/ +(?=#{POSTAL_CODE_RE}\z)/, "\n")

        unless contact_detail[:value][/\A[\dA-]+, (?:avenue|boul\.|boulevard|chemin|montée|rue) [^\n]+\n(?:#{BOROUGH_RE}) \(Québec\)\n#{POSTAL_CODE_RE}\z/]
          errors.add(:contact_details, "contain an invalid address: #{contact_detail[:value]}")
        end
      end
    end
  end
end

class Document
  validates_inclusion_of :description, in: [
    'Assemblée extraordinaire',
    'Assemblée ordinaire',
    'Assemblée spéciale',
    'Séance extraordinaire',
    'Séance ordinaire',
    'Séance spéciale',
  ]
end

class Montreal < Pupa::Processor
end

require_relative 'organizations'
require_relative 'posts'
require_relative 'people'
require_relative 'documents'

Montreal.add_scraping_task(:organizations)
Montreal.add_scraping_task(:posts)
Montreal.add_scraping_task(:people)
Montreal.add_scraping_task(:documents)

options = {
  database_url: ENV['MONGOLAB_URI'] || 'mongodb://localhost:27017/mycityhall',
}

if ENV['REDISCLOUD_URL']
  options[:output_dir] = ENV['REDISCLOUD_URL']
end

if ENV['MEMCACHIER_SERVERS']
  options[:cache_dir] = nil
else
  options[:expires_in] = 86400 # 1 day
end

runner = Pupa::Runner.new(Montreal, options)

runner.add_action(name: 'download', description: 'Download PDFs')
runner.run(ARGV)
