#!/usr/bin/env ruby

#Ensure this app is run using our bundled envrionment.
require 'bundler/setup'
Bundler.require

require 'json'

#Ensure that all helpers are loaded.
require_rel 'helpers'

#Allow coffeescripts to be included directly.
register Barista::Integration::Sinatra

#TODO: Disable Barista auto-compile on production?
configure { Barista.verbose = false }

def connected_port
  JDBeacon::Board.autodetect_serial_port
end

#Ensure that the relevant CSS is preprocessed by scss.
get '/css/app.css' do
  scss :'stylesheets/app'
end

get '/' do
  redirect '/control'
end

get '/control' do
  haml :control
end

get '/ajax/status' do
  state = JDBeacon::Board.open { |board| board.state }
  JSON::generate(state.snapshot)
end


