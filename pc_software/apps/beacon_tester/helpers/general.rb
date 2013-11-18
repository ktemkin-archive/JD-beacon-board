require 'sinatra/base'

module BeaconTester
  module Helpers

    #
    # Helper functions which allow easy access to common functionality.
    # 
    module General

      #
      # Adds a JavaScript file to the current page.
      #
      def js(file)
        %Q{<script type="text/javascript" src="/js/#{file}.js"></script>}
      end


    end

    #Register the helpers, for use in any classic-mode Sinatra apps.
    Sinatra.helpers General

  end
end


