
require 'rubygems'
require 'sinatra'
require './nomnom'
require 'json'
require 'pry'

before do
end

get '/' do
  "NomNom!"
end

post '/single' do
  check_authorized params["key"]

  return 500 unless params["uri"] =~ /^http/
  uri = params["uri"]

  n = NomNom.new
  result = n.download_and_extract_metadata uri
JSON.pretty_generate(result)
end

post '/crawl' do
  check_authorized params["key"]

  return 500 unless params["uri"] =~ /^http/
  return 500 unless params["depth"] =~ /\d/
  uri = params["uri"]
  depth = params["depth"] || 3

  n = NomNom.new
  result = n.crawl_and_parse uri, depth
JSON.pretty_generate(result )
end


def check_authorized(key)
  error 401 unless key =~ /^jcran/
end
