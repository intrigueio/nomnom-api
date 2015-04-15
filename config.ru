require './api'

run Rack::URLMap.new('/' => Sinatra::Application)
