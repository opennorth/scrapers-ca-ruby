require 'rubygems'
require 'bundler/setup'

require 'json'

require 'active_support/core_ext/hash/slice'
require 'moped'
require 'sinatra'

COLLECTION_MAP = {
  'ocd-membership' => :memberships,
  'ocd-organization' => :organizations,
  'ocd-person' => :people,
  'ocd-post' => :posts,
}

helpers do
  def connection
    uri = URI.parse(ENV['MONGOLAB_URI'] || 'mongodb://localhost:27017/pupa')
    connection = Moped::Session.new(["#{uri.host}:#{uri.port}"], database: uri.path[1..-1])
    connection.login(uri.user, uri.password) if uri.user && uri.password
    connection
  end

  def collection(collection_name, criteria)
    content_type :json
    if params.any?
      raise "Unknown parameters: #{params.keys}"
    end
    if criteria.keys == [:_id] && String === criteria.values[0]
      JSON.dump(connection[collection_name].find(criteria).first)
    else
      JSON.dump(connection[collection_name].find(criteria).to_a)
    end
  end

  def members_of(organization_id)
    {'$in' => connection[:memberships].find(organization_id: organization_id).distinct(:person_id)}
  end

  def network_of(organization_id)
    {'$in' => connection[:memberships].find(person_id: members_of(organization_id)).distinct(:organization_id)}
  end
end

# Get the memberships of the people who are members of the organization.
get '/memberships' do
  in_network_of = params.delete('in_network_of')
  id = params.delete('id')
  if in_network_of
    criteria = {person_id: members_of(in_network_of)}
  elsif id
    criteria = {_id: id}
  else
    criteria = params.slice('organization_id', 'person_id')
    params.delete('organization_id')
    params.delete('person_id')
  end
  collection(:memberships, criteria)
end

# Get the organizations which the members of the organization are members of.
get '/organizations' do
  in_network_of = params.delete('in_network_of')
  id = params.delete('id')
  if in_network_of
    criteria = {_id: network_of(in_network_of)}
  elsif id
    criteria = {_id: id}
  else
    criteria = params.slice('classification', 'parent_id')
    params.delete('classification')
    params.delete('parent_id')
  end
  collection(:organizations, criteria)
end

# Get the people who are members of the organization.
get '/people' do
  in_network_of = params.delete('in_network_of')
  organization_id = params.delete('member_of')
  id = params.delete('id')
  if in_network_of
    criteria = {_id: members_of(network_of(organization_id))}
  elsif organization_id
    criteria = {_id: members_of(organization_id)}
  elsif id
    criteria = {_id: id}
  else
    criteria = {}
  end
  collection(:people, criteria)
end

get '/posts' do
  organization_id = params.delete('organization_id')
  if organization_id
    criteria = {organization_id: organization_id}
  else
    criteria = {}
  end
  collection(:posts, criteria)
end

get '/twitter_users' do
  content_type :json
  data = {}
  connection[:twitter_users].find.each do |user|
    data[user['name']] = user['screen_name']
  end
  JSON.dump(data)
end

get '/robots.txt' do
  "User-agent: *\nDisallow: /"
end

get '/favicon.ico' do
  204
end

get '/' do
  204
end

get '/*' do
  params.delete('captures') # ignore
  id = params.delete('splat')[0]
  collection(COLLECTION_MAP.fetch(id.split('/', 2)[0]), {_id: id})
end

run Sinatra::Application
