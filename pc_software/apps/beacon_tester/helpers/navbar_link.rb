
require 'sinatra/base'

module BeaconTester
  module Helpers
    module Navbar
      
      def navigation_link(name)

        #Compute the link path for the given NavBar link.
        link = '/' + name.downcase.gsub(' ', '_')

        #Determine if this is the currently active page by checking to see if this matches the request.
        is_currently_active_page = request.path_info.casecmp(link).zero?

        #If this _is_, add the active class to its link.
        link_class = is_currently_active_page ? 'active' : ''

        #Return the newly-closed navbar link.
        %Q{<li class="#{link_class}"><a href="#{link}">#{name}</a></li>}
      end

      #Register the helpers, for use in any classic-mode Sinatra apps.
      Sinatra.helpers Navbar

    end
  end
end
