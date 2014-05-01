
require 'jd_beacon/enumerator'

module JDBeacon
  module Enumerators

    #
    # Beacon board enumerator for systems which have a compliant /dev/ filesystem,
    # such as Linux and FreeBSD.
    #
    class DevEnumerator < Enumerator
     
      #
      # Determine if we can (and should) use this enumerator.
      #
      # If we're on Windows, or udev is supported, this enumerator
      # isn't a good fit. Otherwise, if "/dev" exists, this should
      # be acceptable.
      #
      def self.supported?
        return false if RUBY_PLATFORM.include?('mswin')
        return false if RubDev::Context.new
        return true
      rescue
        return false
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

