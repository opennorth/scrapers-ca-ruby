require 'rubygems'
require 'bundler/setup'

require 'json'

require 'moped'
require 'sinatra'

helpers do
  def connection
    uri = URI.parse(ENV['MONGOLAB_URI'] || 'mongodb://localhost:27017/pupa')
    connection = Moped::Session.new(["#{uri.host}:#{uri.port}"], database: uri.path[1..-1])
    connection.login(uri.user, uri.password) if uri.user && uri.password
    connection
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

get '/persons' do # like PopIt
  collection(:people)
end

get '/posts' do
  collection(:posts)
end

get '/twitter_users' do
  content_type :json
  data = {}
  connection[:twitter_users].find.each do |user|
    data[user['name']] = user['screen_name']
  end
  JSON.dump(data)
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
