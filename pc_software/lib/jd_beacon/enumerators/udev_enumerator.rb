
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

require 'jd_beacon/enumerator'
require 'rubdev'

module JDBeacon
  module Enumerators

    #
    # Beacon board enumerator for systems which have a compliant /dev/ filesystem,
    # such as Linux and FreeBSD.
    #
    class UDevEnumerator < Enumerator

      VENDOR_ID  = "16d0"
      PRODUCT_ID = "05a5"

      #
      # Determine if we can use this enumerator.
      # We'll check to see that we're not on Windows, and that /dev
      # exists. This should almost always be sufficient.
      #
      def self.supported?
        return false if RUBY_PLATFORM.include?('mswin')
        return false unless RubDev::Context.new
        return true
      rescue
        return false
      end

      #
      # Returns a list of serial devices for each of the connected beacon boards.
      #
      def connected_beacon_boards
        connected_beacon_board_udev_devices.map { |device| device.devnode }
      end


      private

      #
      # Creates an array of all udev syspaths matching a set of conditions.
      # Yields a udev enumerator to the provided block, which can be used to apply udev
      # matchers, reducing the scope.
      #
      # @return Array An array of all matching syspaths.
      #
      def find_matching_udev_devices(&block)

        #Create a udev enumerator devices.
        context    = RubDev::Context.new
        enumerator = RubDev::Enumerate.new(context)

        #Yield the given enumerator to the provided block,
        #allowing it to narrow our search.
        block[enumerator]

        #... scan for the relevant devices...
        enumerator.scan_devices
        paths = enumerator.to_list

        devices = []

        #... and build an array of relevant syspaths.
        until paths.name.nil?
          devices << RubDev::Device.from_syspath(context, paths.name)
          paths.next
        end
          
        devices

      end


      #
      # Returns a collection of udev devices corresponding to all 
      # attached beacon board Abstract Control Model USB-to-serial devices.
      #
      def connected_beacon_board_udev_devices
        find_matching_udev_devices do |enumerator|
          enumerator.match_subsystem("tty")
          enumerator.match_property("ID_VENDOR_ID", VENDOR_ID)
          enumerator.match_property("ID_MODEL_ID", PRODUCT_ID)
        end
      end

      
    end
  end
end

