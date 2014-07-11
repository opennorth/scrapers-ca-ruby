require 'rubygems'
require 'bundler/setup'

require 'json'

require 'moped'
require 'sinatra'

helpers do
  def connection
    uri = URI.parse(ENV['MONGOLAB_URI'] || 'mongodb://localhost:27017/pupa')
    Moped::Session.new(["#{uri.host}:#{uri.port}"], database: uri.path[1..-1])
  end

  def collection(collection_name)
    content_type :json
    JSON.dump(connection[collection_name].find.to_a)
  end
end

get '/memberships' do
  collection(:memberships)
end

get '/organizations' do
  collection(:organizations)
end

get '/people' do
  collection(:people)
end

get '/' do
  204
end

get '/robots.txt' do
  "User-agent: *\nDisallow: /"
end

get '/favicon.ico' do
  204
end

run Sinatra::Application
