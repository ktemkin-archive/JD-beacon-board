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

    #This is for debug only!
    #attr_reader :board_pairs
 

    #
    # Creates a new instance of the JD Beacon competition.
    # 
    def initialize
      @message_targets = [ lambda { |s| puts s }] #Debug only! replace with []
      create_paired_connections
      reset
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

      #Initialize each beacon...
      each_beacon       { |beacon| beacon.mode = :off; beacon.owner = :none }
      each_red_beacon   { |beacon| beacon.affiliation = :red}
      each_green_beacon { |beacon| beacon.affiliation = :green}

      #Clear our "first to claim" register...
      @first_to_claim   = nil

      #... and record the initial state of each beacon.
      @last_states = @board_pairs.map { |pair| states_for_pair(pair)}

    end

    #
    # Performa a given 
    #
    def each_beacon_in_pair(pair_number, &action)
      Thread.exclusive do
        @board_pairs[pair_number].each(&action)
      end
    end


    #
    # Makes the allegiance of each beacon in a pair visible by displaying
    # its color, dimly.
    # 
    def display_affiliation(pair_number, turn_off_others)
      
      turn_off_all

      each_beacon_in_pair(pair_number) do |color, device|
        device.owner = color
        device.mode = :on
      end

    end

    #
    # Turns off both beacons in a given pair.
    #
    def turn_off_pair(pair_number)
      each_beacon_in_pair(pair_number) do |color, device|
        device.mode = :off
      end
    end

    #
    # Turns off all beacons' lights.
    #
    def turn_off_all
      Thread.exclusive do
        beacons.each {|device| device.mode = :off}
      end
    end


    #
    # Run the given competition instance on the current thread.
    # This will lock the current thread.
    #
    # @param duration Duration in seconds.
    #
    def run!(duration = nil)

      reset
      each_beacon { |beacon| beacon.mode = :on }
      log("New competition round started. All ownership reset.")


      #And determine the finish time, if a duration is provided.
      @finish_time = duration ? (Time.now + duration) : nil

      #Main game loop, which should run until the duration is passed.
      until time_up?

        #Ensure that this thread is run exlcusively; and not interrupted.
        Thread.exclusive do

          #Monitor each pair, as quickly as possible.
          each_pair_with_index do |pair, pair_number|
           
            #Determine the current state of the given pair...
            new_state  = states_for_pair(pair)
            last_state = @last_states[pair_number]

            #Update the boards according to any changes that have occurred;
            #and update the most recent state accordingly.
            @last_states[pair_number] = update_states_for_pair(pair, new_state, last_state)

          end  
        end
      end

      #Freeze all beacon activity, once the round is over!
      each_beacon { |beacon| beacon.mode = :freeze }

      log("Competition round ended!")
      log("Final scores: #{scores}.")

    end

    #
    # Returns the number of seconds remaining, which may be negative,
    # or nil if the round has no limit.
    #
    def seconds_left
      return nil unless @finish_time
      @finish_time - Time.now
    end

    #
    # Returns true iff the round's time is up.
    #
    def time_up?
      return false unless @finish_time
      seconds_left < 0
    end

    #
    # Returns the owners for each of the beacon pairs, 
    # as of the last time an update was performed.
    #
    # @param update boolean If true, the beacons' current states will
    #   be updated; otherwise the most recent value will be used. This
    #   should not be true while a competition is running!
    #
    def beacon_owners(update=false)

      #If requested, update each of the beacon pairs' states.
      states = 
        if update
          @board_pairs.map { |pair| states_for_pair(pair) }
        else
          @last_states
        end

      #Convert each set of states into a owner.
      states.map { |state| state[:red].owner }

    end

    
    #
    # Return the current scores for both of the competing teams.
    #
    def scores
      #Thread.exclusive do

        #Start off assuming a zero score for both teams.
        scores = { :red => 0, :green => 0 }

        #Award each team 30 points for any beacons they own.
        beacon_owners.each do |owner|
          next unless scores[owner]
          scores[owner] += 30
        end

        #Awared the first team to claim a beacon 8 points.
        scores[@first_to_claim] += 8 if @first_to_claim

        #And return the computed scores.
        scores
      #end
      
    end

    #
    # Swaps a given pair of beacons.
    #
    def swap(color_a, number_a, color_b, number_b)
      @board_pairs[number_a][color_a], @board_pairs[number_b][color_b] = 
          @board_pairs[number_b][color_b], @board_pairs[number_a][color_a]
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

    #
    # 
    #
    def first_to_claim
      @first_to_claim
    end


    #
    # Updates the states for a pair of beacons, given a pair of "simultaneous" readings.
    #
    # Warning: This method updates beacon states, and thus should only be called in "exclusive"
    # critical sections, to ensure thread safety.
    #
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

        #... update the "first to claim" statistic, if appropriate...
        @first_to_claim ||= new_owner

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
      #Ensure that this aciton is performed atomically.
      Thread.exclusive do
          
        connections = initiate_beacon_connections

        #Clear out the list of paired connections.
        @board_pairs = []

        #Split each of the boards into a set of paired elements.
        connections.each_slice(2) do |red, green|
          next unless green
          @board_pairs << { :red => red, :green => green} 
        end

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


