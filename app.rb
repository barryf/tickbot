require 'sinatra'
require './tickbot.rb'

get '/' do
  "I am tickbot."
end

get '/remind' do
  remind
end

get '/shame' do
  shame
end