require 'rubygems'
require './app.rb'

map('/') do
  run Sinatra::Application
end

