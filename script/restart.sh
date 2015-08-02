#!/bin/bash

bundle exec jruby -J-Xmx2048m `which puma` -C config/puma-tcp.rb
