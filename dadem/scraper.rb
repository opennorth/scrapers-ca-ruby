require 'open-uri'

require 'rabx/message'
require 'pupa'

class Representative
  include Pupa::Model

  attr_accessor :deleted, :edit_times, :email, :fax, :id, :last_editor, :method, :name, :parlparse_person_id, :party, :type, :voting_area, :whencreated, :whenlastedited
  dump :deleted, :edit_times, :email, :fax, :id, :last_editor, :method, :name, :parlparse_person_id, :party, :type, :voting_area, :whencreated, :whenlastedited

  def fingerprint
    to_h.slice(:id)
  end

  def to_s
    name
  end
end

class DaDemProcessor < Pupa::Processor
  def scrape_representatives
    if options['only']
      ids = options['only'].split(',')
    else
      ids = Integer(options.fetch('start', 0)).upto(Integer(options.fetch('end', 65_000)))
    end
    ids.each do |id| # 61646 highest observed
      begin
        response = open("http://services.mysociety.org/dadem?#{RABX::Message.dump('R', 'DaDem.get_representative_info', [id])}").read.force_encoding('utf-8')
        dispatch(Representative.new(RABX::Message.load(response).value))
      rescue OpenURI::HTTPError
        warn("HTTP error on #{id}")
      rescue RABX::Message::ProtocolError
        error("Protocol error on #{id}")
      end
    end
  end
end

DaDemProcessor.add_scraping_task(:representatives)

runner = Pupa::Runner.new(DaDemProcessor)
runner.run(ARGV)
