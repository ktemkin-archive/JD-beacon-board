
require 'sinatra/base'

module BeaconTester
  module Helpers
    module ConnectedBoardSummary
      
      def connected_board_summary
        { location: JDBeacon::Board.autodetect_serial_port }
      end

      #Register the helpers, for use in any classic-mode Sinatra apps.
      Sinatra.helpers ConnectedBoardSummary

    end
  end
end
