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

require 'serialport'
require 'forwardable'
require 'require_all'

require 'jd_beacon/state'
require 'jd_beacon/errors'
require_rel 'enumerators'

module JDBeacon

  #
  # Class which controls a single JD Beacon board.
  #
  class Board
    extend Forwardable

    # The timeout for a single read from a the beacon board, in milliseconds.
    READ_TIMEOUT = 2000

    # A special, constant request that indicates that there is no new data.
    NULL_REQUEST = State.new(:id => 31)

    attr_reader :filename

    #
    # Meta-method which defines a "state setter",
    # which sets an indvidual aspect of the state.
    #
    def self.state_setter(*names)

      #For each of the target names provided...
      names.each do |name|

        #... determine what the name of the resulting setter value should be...
        method_name = "#{name}="

        # ... and create the desired setter method.
        define_method(method_name) do |value|

          #Read the device's current state.
          new_state = self.state

          #Adjust the state so it contains the appropriate value...
          new_state.send(method_name, value)

          #... and update the device with the new state.
          self.state = new_state

        end
      end
    end

    #Create a state setter for each of the beacon board's properties.
    STATE_PROPERTIES = [:id, :affiliation, :owner]
    state_setter(*STATE_PROPERTIES)

    #And forward any state call to the state object itself>
    def_delegators :state, *STATE_PROPERTIES


    #
    # Initializes a new beacon board connection, creating the raw serial connection
    # to the beacon board.
    #
    def initialize(serial_port = self.class.autodetect_serial_port)

      #If we were provided with a string, convert it into a serial port object.
      if serial_port.is_a? String
        @filename = serial_port
        serial_port = SerialPort.new(serial_port, 9600)
      end

      raise NotConnectedError unless serial_port

      #Set up the serial port.
      @serial_port = serial_port
      @serial_port.read_timeout = READ_TIMEOUT

    end

    #
    # Closes the connection to the JD beacon board.
    #
    def close
      @serial_port.close
    end

    #
    # Returns the beacon board's current state.
    #
    def state
      send_state(NULL_REQUEST)
      receive_state
    end

    #
    # Sets the state of the beacon board.
    #
    def state=(new_state)
      send_state(new_state)
      receive_state
    end

    #
    # Creates a connection to the given beacon board,
    # If a block is given, the connection will be yielded,
    # and then closed afterwrads.
    #
    def self.open(filename=autodetect_serial_port)

      #Create a new connection, and 
      connection = new(filename)
      return connection unless block_given? 

      #If we were passed a block, yield the connection
      #to it, and then close the connection.
      begin
        return yield connection
      ensure
        connection.close
      end
       
    end

    
    private

    #
    # Sets the target beacon's state,
    # but does not wait for a response.
    #
    def send_state(state)
      state.write(@serial_port)
    end

    #
    # Receives the beacon board's state.
    # This requires that a request be sent beforehand;
    # the process is performed automatically by state=.
    #
    def receive_state
      State.read(@serial_port)
    end

    #
    # Automatically detects the virtual serial port 
    # on which the Beacon board is connected.
    #
    def self.autodetect_serial_port
      Enumerator.connected_beacon_boards.first
    end

  end

end
