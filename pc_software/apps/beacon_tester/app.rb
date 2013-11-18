#!/usr/bin/env ruby

#Ensure this app is run using our bundled envrionment.
require 'bundler/setup'
Bundler.require

#require 'compass'
#require 'sinatra'
#require 'barista'
#require 'json'
#
#require 'require_all'

#require 'beacon'

#Ensure that all helpers are loaded.
require_rel 'helpers'

#Allow coffeescripts to be included directly.
register Barista::Integration::Sinatra

#TODO: Disable Barista auto-compile on production?
configure { Barista.verbose = false }

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

get '/ajax/connected_board' do
  Beacon.autodetect_serial_port  
end


