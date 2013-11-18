

module Beacon

  #
  # Base class for objects which enumerate all local beacons.
  #
  # This may not be the most appropriate way to lay this out, as it creates
  # an unneccessary "abstract" base class-- but this seems cleaner than a
  # metaprogrammed module. This should be given more thought, when time permits.
  #
  class Enumerator

    @enumerators = []

    #
    # Inheritance "hook", which keeps track of all beacon enumerators.
    #
    def self.inherited(child)
      @enumerators << child
    end

    #
    # Retreives the first enumerator which is appropriate for the
    # current platform.
    #
    def self.for_current_platform
      enumerator = @enumerators.find(&:supported?) || self
      enumerator.new
    end

    #
    # Returns a list of serial ports to which beacon boards are connected.
    #
    # This implementation is a degenerate case, which is used when 
    # we couldn't find any appropriate enumerators.
    #
    def connected_beacon_boards
      []
    end

    #
    # Convenience method which enumerates all current beacon boards
    # using the default enumerator for the current platform.
    #
    def self.connected_beacon_boards
      for_current_platform.connected_beacon_boards
    end


  end

end
