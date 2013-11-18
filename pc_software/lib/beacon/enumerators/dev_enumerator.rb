
require 'beacon/enumerator'

module Beacon
  module Enumerators

    #
    # Beacon board enumerator for systems which have a /dev/ filesystem,
    # such as Linux or OS X.
    #
    class DevEnumerator < Enumerator
     
      #
      # Determine if we can use this enumerator.
      # We'll check to see that we're not on Windows, and that /dev
      # exists. This should almost always be sufficient.
      #
      def self.supported?
        return false if RUBY_PLATFORM.include?('mswin')
        return false unless File.exists?('/dev')
        return true
      end

      #
      # Returns a list of serial devices for each of the connected beacon boards.
      #
      def connected_beacon_boards
       
        #Find any devices which identify as JD Beacon Boards.
        paths = Dir.glob('/dev/serial/by-id/*JD_Beacon_Board*')

        #Return a list of corresponding serial ports.
        paths.map { |path| File.realpath(path) }

      end

    end
  end
end

