# The MIT License (MIT)
# 
# Copyright (c) 2014 Kyle J. Temkin <ktemkin@binghamton.edu>
# Copyright (c) 2014 Binghamton University
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

require 'require_all'

require 'jd_beacon/state'
require 'jd_beacon/errors'
require_rel 'enumerators'


module JDBeacon

  #
  # Class which controls a round of the JD beacon competition.
  #
  class Competition

    attr_reader :board_pairs

    #
    # Creates a new instance of the JD Beacon competition.
    # 
    def initialize
      @message_targets = [] 
      create_paired_connections
    end

    #
    # Registers a block of code responsible for handling 
    # status update messages. 
    #
    def register_message_target(&block)
      @message_targets << block
    end

    #
    # Returns the number of beacons per side.
    #
    def beacons_per_side
      @board_pairs.count
    end


    #
    # Iterates over each beacon on the field.
    #
    def each_beacon(&block)
     beacons.each(&block)
    end

    #
    # Iterates over each beacon on the red side.
    #
    def each_red_beacon(&block)
      red_beacons.each(&block)
    end

    #
    # Iterates over each beacon on the green side.
    #
    def each_green_beacon(&block)
      green_beacons.each(&block)
    end

    #
    # Iterates over each matched pair of beacon towers. 
    #
    def each_pair(&block)
      @board_pairs.each(&block)
    end

    #
    # Iterates over each matched pair of beacnon towers,
    # yielding both the object itself and its index.
    #
    def each_pair_with_index(&block)
      @board_pairs.each_with_index(&block)
    end

    #
    # Returns the set of all beacons.
    #
    def beacons
      red_beacons + green_beacons
    end

    #
    # Returns the set of all red beacons.
    #
    def red_beacons
      beacons_for_color(:red)
    end

    #
    # Returns the set of all green beacons.
    #
    def green_beacons
      beacons_for_color(:green)
    end

    #
    # Resets the competition field to its original state.
    # 
    def reset
      each_beacon       { |beacon| beacon.id = 0; beacon.owner = :none }
      each_red_beacon   { |beacon| beacon.affiliation = :red}
      each_green_beacon { |beacon| beacon.affiliation = :green}
    end


    #
    # Makes a given beacon's selection.
    # 
    def make_visible(pair_number)

      #Set both of the devices in the pair to display their own color.
      pair = @board_pairs[pair_number]
      pair.each do |color, device|
        device.owner = color
        device.id = 1
      end

    end

    #
    # Run the given competition instance on the current thread.
    # This will lock the current thread.
    #
    def run!

      reset
      each_beacon { |beacon| beacon.id = 1 }
      log("New competition round started. All ownership reset.")

      #record initial states
      last_states = @board_pairs.map { |pair| states_for_pair(pair)}
     
      #Main game loop.
      loop do

        #Monitor each pair, as quickly as possible.
        each_pair_with_index do |pair, pair_number|
         
          #Determine the current state of the given pair...
          new_state  = states_for_pair(pair)
          last_state = last_states[pair_number]

          #Update the boards according to any changes that have occurred;
          #and update the most recent state accordingly.
          new_state = update_states_for_pair(pair, new_state, last_state)
          last_states[pair_number] = new_state

        end

      end
     
      #freeze all beacon activity

    end


    private

    #
    # Logs a message to all available message handlers.
    #
    def log(message)
      @message_targets.each { |target| target[message] }
    end


    #
    # Return the current states for both beacons in a matched pair.
    #
    def states_for_pair(pair)
      {:red => pair[:red].state, :green => pair[:green].state }
    end


    def update_states_for_pair(pair, new_state, last_state)

      #Identify whether either side has claimed a beacon...
      red_has_claimed   = (new_state[:red].owner   == :red)   && (last_state[:red].owner   != :red)
      green_has_claimed = (new_state[:green].owner == :green) && (last_state[:green].owner != :green)

      #Select the new owner according to what's happened in the meantime: 
      new_owner = 
        #If both teams have claimed the beacon at the same time, pick randomly between them.
        #This should be very rare.
        if red_has_claimed && green_has_claimed
          [:red, :green].sample

        #Otherwise, if either of the side has claimed the beacon,
        #they'll become the new owner.
        elsif red_has_claimed
          :red
        elsif green_has_claimed
          :green

        #If neither of the sides have claimed the beacon, leave the beacon with its original owner.
        else
          new_state[:red].owner
        end

      #If a change has occurred...
      if red_has_claimed or green_has_claimed

        #... update the beacons themselves...
        pair[:red].owner = pair[:green].owner = new_owner 

        #... modify the new state object...
        new_state[:red].owner = new_state[:green].owner = new_owner

        #... and log the change.
        log "A beacon was claimed by the #{new_owner.to_s} team!"  

      end

      new_state
     
    end




    #
    # Returns a set of all beacons affiliated with a given color.
    # 
    def beacons_for_color(color)
      @board_pairs.map { |pair| pair[color] }
    end


    #
    # Creates a set of paired connections for each of the beacon board connections.
    #
    def create_paired_connections(beacons=initiate_beacon_connections)
        
      connections = initiate_beacon_connections

      #Clear out the list of paired connections.
      @board_pairs = []

      #Split each of the boards into a set of paired elements.
      connections.each_slice(2) do |red, green|
        next unless green
        board_pairs << { :red => red, :green => green} 
      end

    end


    #
    # Builds a set of beacon connections.
    #
    # @param enumerator The JDBeacon::Enumerator which will be used to identify
    #   all connected beacons.
    #
    def initiate_beacon_connections(enumerator=Enumerator)
     
      #Get a list of all connected board devices...
      board_connections = enumerator.connected_beacon_boards

      #... and convert that into a list of actual beacon boards.
      return board_connections.map { |connection| Board.new(connection) }

    end

  end


end


