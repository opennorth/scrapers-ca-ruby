require File.expand_path(File.join('..', 'utils.rb'), __dir__)

class Canada < Pupa::Processor
end

require_relative 'twitter'
require_relative 'candidates'

Canada.add_scraping_task(:manual)
Canada.add_scraping_task(:conservative)
Canada.add_scraping_task(:liberal)
Canada.add_scraping_task(:ndp)

options = {
  database_url: ENV['MONGOLAB_URI'] || 'mongodb://localhost:27017/pupa',
  expires_in: 604800, # 1 week
}

if ENV['REDISCLOUD_URL']
  options[:output_dir] = ENV['REDISCLOUD_URL']
end

if ENV['MEMCACHIER_SERVERS']
  options[:cache_dir] = "memcached://#{ENV['MEMCACHIER_SERVERS']}"
  options[:memcached_username] = ENV['MEMCACHIER_USERNAME']
  options[:memcached_password] = ENV['MEMCACHIER_PASSWORD']
end

runner = Pupa::Runner.new(Canada, options)

runner.add_action(name: 'update', description: 'Update Twitter screen names')
runner.run(ARGV)
