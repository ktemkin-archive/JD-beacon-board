
require 'bindata'

module JDBeacon

  #
  # Data structure which represents the current state of a beacon board, 
  # in the binary format that will be exchanged with the board itself.
  #
  class State < BinData::Record

    # A look-up table that maps each of the possible beacon colors to 
    # their raw binary.
    TEAMS = {
      :green => 0,
      :red   => 1,
      :none  => 2
    }

    #Prevent this record from re-defining its accessor methods at runtime.
    def self.define_field_accessors(*args); end

    #
    # Meta-method which allows the definition of fields which represent
    # a beacon color.
    #
    def self.color_field(name, bits)

      #First, add the appropriate field.
      send("bit#{bits}", name)

      #Create a getter method, which automatically replaces the raw representation
      #of a color with a more descriptive symbol...
      define_method(name) do
        TEAMS.key(self[name])
      end

      #... and create setter methods which automatically replace each color with the
      #correesponding raw binary representation.
      define_method("#{name}=") do |value| 
        self[name] = TEAMS[value]
      end

    end

    # Indicates which team currently owns the beacon, if any.
    #
    # 0 = Green robot owns the beacon.
    # 1 = Red robot owns the beacon.
    # 2 = Neither robot owns the beacon.
    color_field :owner, 2


    # The affiliation of the beacon. 
    # This indicates which side of the board the beacon is on:
    #
    # 0 = Green robot side,
    # 1 = Red robot side
    color_field :affiliation, 1


    # The unique ID number for this beacon.
    #
    # A beacon value of zero means that this beacon has not yet been assigned an 
    # ID by its host, and a beacon value of 31 (all 1's) is prohibited, to ensure
    # that this value is always distinguishable from the sync byte. Any other 
    # value is a defined beacon ID.
    bit5 :id


  end

end
