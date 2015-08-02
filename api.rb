require 'rubygems'
require 'sinatra'
require 'json'
require 'timeout'
require_relative 'nomnom'

before do
  puts "Params: #{params}"
end

##
## http://redistogo.com/documentation/heroku
##
#configure do
#  require 'redis'
#  uri = URI.parse(ENV["REDISTOGO_URL"])
#  REDIS = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
#end

get '/' do
  "NomNom!"
end

post '/single' do
  check_authorized params["key"]
  return 500 unless params["uri"] =~ /^http/
  uri = params["uri"]

  json_result = "nil"
  begin
    n = NomNom.new
    result = n.download_and_extract_metadata uri
    json_result = JSON.pretty_generate(result)
  rescue JSON::ParserError => e
    puts "ERROR PARSING JSON"
  end

return json_result
end

post '/crawl' do
  check_authorized params["key"]

  return 500 unless params["uri"] =~ /^http/
  return 500 unless params["depth"] =~ /\d/
  uri = params["uri"]
  depth = params["depth"] || 2

  json_result = "nil"
  begin
    n = NomNom.new
    result = n.crawl_and_parse uri, depth, 90
    json_result = JSON.pretty_generate(result)
  rescue JSON::ParserError => e
    puts "ERROR PARSING JSON"
  end

return json_result
end

def check_authorized(key)
  error 401 unless key =~ /^intrigue/
end
