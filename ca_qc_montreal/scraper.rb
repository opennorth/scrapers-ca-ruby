require File.expand_path(File.join('..', 'utils.rb'), __dir__)

class Montreal < GovernmentProcessor
end

require_relative 'organizations'
require_relative 'posts'
require_relative 'people'

GovernmentProcessor.add_scraping_task(:organizations)
GovernmentProcessor.add_scraping_task(:posts)
GovernmentProcessor.add_scraping_task(:people)

Pupa::Runner.new(Montreal, database: 'mycityhall', expires_in: 604800).run(ARGV) # 1 week
