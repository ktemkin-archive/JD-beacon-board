#!/usr/bin/env ruby

#Ensure this app is run using our bundled envrionment.
require 'bundler/setup'
Bundler.require

require 'barista'
require 'json'
require 'sinatra'

#Ensure that all helpers are loaded.
require_rel 'helpers'

#Allow coffeescripts to be included directly.
register Barista::Integration::Sinatra

#Allow all local systems to connect to Sinatra.
set :bind, '0.0.0.0'
disable :logging

#Silence the standard error.
$stderr = File.open(File::NULL, 'w')


#Configure the automatic inclusion of CoffeScripts.
Barista.configure do |c|

  #Specify where the application's interactive coffeescript should be located.
  c.root = 'coffeescripts'
  c.output_root = 'public/js'

  c.verbose =  false
  c.auto_compile = true
end

#
# Returns the currently connected port.
#
def connected_port
  JDBeacon::Board.autodetect_serial_port
end


#
# Adjust the beacon board's state, and return the board's status.
#
def adjust_board_state(&block)
  begin
    JDBeacon::Board.open(&block) if block
    JDBeacon::Board.open do |board| 
      JSON::generate(board.state.snapshot.merge(:claim_code => board.claim_code, :last_claim => board.last_claim_attempt))
    end
  rescue StandardError => e
    JSON::generate({:error => e.class, :message => e.to_s, :backtrace => e.backtrace})
  end
end

#
# Returns the board's status, as a JSON object.
#
def board_status
  adjust_board_state
end



#Ensure that the relevant CSS is preprocessed by scss.
get '/css/app.css' do
  scss :'stylesheets/app'
end

#If no URI was provided, the user most likely wants to control the beacon.
get '/' do
  redirect '/control'
end

#Return the main control view, if necessary.
#This view should be nearly completely decoupled from the server;
#(e.g. you should be able to save this and have everything work--
# you'd just need to adjust the API location.)
get '/control' do
  haml :control
end

#
# Backend status methods.
# 

#Return information about the connected board.
get '/api/connected_board' do
  JSON::generate(connected_board_summary)
end

#Return the board's current status.
get '/api/status' do
  board_status
end

get '/api/claim_status' do
  JDBeacon::Board.open do |board| 
    JSON::generate(:last_attempt => board.last_claim_attempt, :code => board.claim_code, :inverted => board.inverted_claim_code)
  end
end

#
# Backend control methods.
#

get '/api/mode/:mode' do
  #TODO: Replace me when ID is change to "mode".
  mode = params[:mode] == 'on' ? 1 : 0
  adjust_board_state { |board| board.id = mode }
end


#Set the beacon's current owner.
get '/api/claim/:color' do
    adjust_board_state { |board| board.owner = params[:color].to_sym }
end

#Set the beacon's current affiliation.
get '/api/affiliate/:color' do
    adjust_board_state { |board| board.affiliation = params[:color].to_sym }
end


puts 
puts "=========================="
puts "Beacon Tester started!"
puts "=========================="
puts
puts "To access the beacon test, point your web browser to:  http://localhost:#{settings.port}"
puts "Press CTRL+C to stop running the beacon tester."
puts 
puts "Enjoy!"

