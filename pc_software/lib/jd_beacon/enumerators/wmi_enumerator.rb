
require 'jd_beacon/enumerator'

module JDBeacon
  module Enumerators

    #
    # Beacon board enumerator for Windows systems which feature WMI.
    #
    class WMIEnumerator < Enumerator
     
      #
      # Determine if we can use this enumerator.
      # We'll check to see that we're not on Windows, and that /dev
      # exists. This should almost always be sufficient.
      #
      def self.supported?
        return true if RUBY_PLATFORM.include?('mswin')
        return true if RUBY_PLATFORM.include?('mingw32')
        return false
      end

      #
      # Returns a list of serial devices for each of the connected beacon boards.
      #
      def connected_beacon_boards

        #Load the ruby WMI library.
        require 'ruby-wmi'

        #Find all serial ports on the host system.
        ports = WMI::Win32_SerialPort.find(:all)

        #Find only the ports which match the vendor/product ID for the JD beacon board.
        ports.select! { |p| p.attributes["pnp_device_id"].start_with? "USB\\VID_16D0&PID_05A5" }

        #And convert each port to a name/value.
        ports.map! { |p| p.attributes["device_id"] }
        
      end

    end
  end
end

