#!/usr/bin/env ruby

require_relative 'nomnom'

uri = ARGV[0]
depth = ARGV[1].to_i

unless uri
  puts "Need a URI"
  return
end

unless depth
  depth = 3
  puts "Defaulting to depth #{depth}"
end

x=NomNom.new
x.crawl_and_parse uri, depth
