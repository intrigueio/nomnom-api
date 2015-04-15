# test.rb
require_relative 'test_helper'

class ApiTest < MiniTest::Test

  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_base
    get '/', :key => "WHATEVER"
    assert last_response.ok?
    assert_equal "ahoy!", last_response.body
  end

  def test_fake_route
    get '/whatever.json'
    assert !last_response.ok?
  end


end
