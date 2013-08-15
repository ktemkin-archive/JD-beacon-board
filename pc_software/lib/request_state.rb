
require_relative 'beacon_state'

#
# A special "request" beacon state which, when transmitted,
# does not cause the beacon to update its own state.
# 
class RequestState < BeaconState

  def initialize
    super(:id => -1)
  end

end
