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


require 'jd_beacon/competition'
require 'forwardable'

module JDBeacon

  #
  # Pseudo thread-safe proxy for a Beacon Competition,
  # which runs the given competition in the background.
  #
  class BackgroundCompetition
    extend Forwardable

      #
      # Creates a new instance of the JD Beacon competition.
      # 
      def initialize(competition = nil)

        #Create the core competition instance we're proxying.
        @competition = competition || JDBeacon::Competition.new

        #Create a thread object used to 
        @thread = nil

      end

      #
      # Run a competition, in the background.
      #
      def run(duration=nil)
        @thread.kill if running?
        @thread = Thread.new { @competition.run!(duration) }
      end


      #
      # Returns true iff a competition is currently running.
      #
      def running?
        @thread and @thread.alive?
      end

      
      #
      # Makes the allegiance of each beacon in a pair visible by displaying
      # its color, dimly.
      #
      # Thread-safe.
      # 
      def display_allegiance(pair_number, turn_off_first=true)
        return if running?
        turn_off_all if turn_off_first
        @competition.display_allegiance(pair_number)
      end

      #
      # Turns off both beacons in a given pair.
      #
      # Thread-safe.
      # 
      def turn_off_pair(pair_number)
        return if running?
        @competition.turn_off_pair(pair_number)
      end

      #
      # Turns off all beacons.
      #
      # Thread-safe.
      # 
      def turn_off_all
        return if running?
        @competition.turn_off_all
      end



      #
      # Allow access to the safe calls during the competition.
      #
      def_delegators :@competition, :seconds_left, :beacon_owners, :scores, :first_to_claim


      #Allow use of "owners" to get the beacon's owners.
      alias_method :owners, :beacon_owners



  end

end

