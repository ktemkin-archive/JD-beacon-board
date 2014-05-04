
class BeaconTestApplication

  status_api:          '/api/status'
  connected_board_api: '/api/connected_board'

  heartbeat_interval: 1000

  #Specifies all possible colors for the beacon.
  possible_colors: ['green', 'none', 'red']


  #
  # Initializes a new BeaconTestApplication object.
  # 
  constructor: ->

    #TODO: Abstract these to somewhere else?
    @manual_control_panel = $('#manual_control')
    @owner_graphic = $('#owner')
    @claim_panels =
      red:    $('#claim_red')
      green:  $('#claim_green')
      none:   $('#claim_none')
    @affiliation_panels =
      red:    $('#affiliation_red')
      green:  $('#affiliation_green')
    @event_log = $('#event_log')
    @ir_claim_panel = $('#claim_code')

    #TODO: DRY
    @simulation_controls =
      simulation_enable:               $("#simulate_capture")
      simulation_interval:             $("#simulation_interval")
      probabilistically_capture:       $('#probabilistically_capture')
      capture_probability:             $('#capture_probability')
      probabilistically_capture_label: $("#probabilistically_capture_label")
     

    #Set up the manual control panel.
    @set_up_claim_panels()
    @set_up_affiliation_panels()

    #set up the simulation panel.
    @set_up_simulation_panel()
    @initialize_simulation()

    #Set the "last known" status to null.
    @state = null


  #
  # Performs a Beacon API call; but does not 
  #
  perform_api_call: (api, argument = null, handler=null) ->

    #If a simple argument is provided, convert it to a URL-style argument,
    #rather than transmitting it as a get-encoded JSON object.
    if typeof argument is "string"
      url_suffix = "/#{argument}"
      argument   = null

    #Otherwise, pass the argument through verbatim.
    else
      url_suffix = ""

    #Perform the simple call.
    $.getJSON("/api/#{api}#{url_suffix}", argument, handler)
 

  
  #
  # Sets up a single "click" event for each of the claim panels, which will
  # claim the provided beacon.
  #
  set_up_claim_panels: =>

    #This is, unfortunately, necessary-- due to CoffeeScript's odd scoping.
    @claim_panels.red.click   => @claim_beacon('red')
    @claim_panels.none.click  => @claim_beacon('none')
    @claim_panels.green.click => @claim_beacon('green')


  #
  # Sets up a single "click" event for each of the affiliation panels,
  # which will adjust the affiliation of the given beacon.
  #
  set_up_affiliation_panels: =>
    @affiliation_panels.green.click => @set_affiliation('green')
    @affiliation_panels.red.click   => @set_affiliation('red')


  #
  # Sets up the actions which handle manipulation of the Gameplay Simulation 
  # controls.
  #
  set_up_simulation_panel: =>
    for name, object of @simulation_controls
      object.change(@update_simulation_parameters)


  #
  # Initializes the simulation control.
  #
  initialize_simulation: =>
    @simulation_interval = null


  #
  # Function which initializes the Rise common GUI elements.
  #
  run: ->
  
    #Set up the status update 'heartbeat' function.
    setInterval(@update_status, @heartbeat_interval)

    #If we can, attempt to turn the beacon on.
    @ensure_beacon_is_on()


  #
  # Handles the update-status "heartbeat", which keeps the view up to date.
  #
  update_status: =>
    @perform_api_call('connected_board', null, @apply_board_status)
    @perform_api_call('status', null, @apply_beacon_status)

  
  #
  #Function which applies the result of a device status update from the RISE app.
  #
  apply_board_status: (status) =>
 
    #If we know the beacon board's location, report it.
    location = if status.location
      "Beacon on #{status.location}"
    else
      'No boards found.'
  
    #And update the "connected board" field.
    $('#connected_board').html(location)
  
  
  #
  # Apply the beacon's status to the local page.
  #
  apply_beacon_status:  (status) =>

    #Never attempt to apply the beacon state during the middle of an update,
    #as this can cause "flashes" of outdated information.
    return if @updating

    #If we weren't able to connect to the device for any reason,
    #display the beacon as disconnected.
    if status.error?
      @_apply_disconnected_status()
      return

    #If the last state was null, we've likely just reconnected
    #the beacon. Make sure the beacon is on!
    if @state is null
      @ensure_beacon_is_on()

    #Log any changes in the beacon's status.
    @_log_state_changes(@state, status)

    #Store the most recent beacon status.
    @state = status

    #Ensure that the "manual control panel" is disabled.
    @manual_control_panel.removeClass('disabled')

    #Display the relevant information about the beacon board.
    @display_beacon_owner(status.owner)
    @display_beacon_affiliation(status.affiliation)

    #Display the current IR information. 
    @display_ir_claim_code(if status.owner == status.affiliation then null else status.claim_code)



  #
  # Adjust the current display to reflect the beacon's owner.
  #
  display_beacon_owner: (owner) ->
    @owner_graphic.attr('class', "beacon activated #{owner}")
    @_set_owner_selection(owner)

  
  #
  # Adjusts the current display to reflect the beacon's affiliation.
  #
  display_beacon_affiliation: (affiliation) ->
    @_set_affiliation_selection(affiliation)


  #
  # Displays inforamtion about the beacon's current claim code.
  #
  display_ir_claim_code: (claim_code) ->
    
    if claim_code
      @ir_claim_panel.html("The beacon is transmitting claim code <strong>#{claim_code}</strong>, and can be claimed by transmitting <strong>#{255 - claim_code}</strong>.")
    else
      @ir_claim_panel.html("The beacon current <strong>cannot be claimed</strong>.")



  #
  # Indicates that the beacon is disconnected.
  #
  _apply_disconnected_status: ->

    #If we were previously connected, then apply a disconnected state.
    #TODO: Move this to log_state_change?
    @_log_event("A beacon was disconnected.") if @state

    #Set the manual controls to a "disabled" appearance,
    #and show that the beacon is disconnected.
    @manual_control_panel.addClass('disabled')
    @owner_graphic.attr('class', "beacon disconnected")

    #Set the beacon's "state" to null.
    @state = null



  #
  # Sets the currently selected panel from amongst a given collection.
  #
  _set_selection: (selected=null, collection=@claim_panels) ->

    #Remove the "selected" class from all claim panels.
    object.removeClass('selected') for i, object of collection

    #... and add it to the relevant panel.
    collection[selected].addClass('selected') if selected


  #
  # Sets the currently selected owner panel.
  #
  _set_owner_selection: (owner=null) ->
    @_set_selection(owner, @claim_panels)


  #
  # Sets the currently selected affiliation panel.
  #
  _set_affiliation_selection: (affiliation=null) ->
    @_set_selection(affiliation, @affiliation_panels)


  #
  # Ensures that the beacon is on.
  # TODO: Replace me with a more comprehensive mode system!
  #
  ensure_beacon_is_on: =>
    @perform_api_call('mode', 'on') unless @state?.mode > 0


  #
  # Claims the beacon for the given team; effectively setting the beacon's owner.
  #
  claim_beacon: (owner) ->

    #Indicate that we're updating the beacon's status, which temporarily blocks
    #the self-update thread.
    @start_update()

    #Ensure the beacon is on.
    @ensure_beacon_is_on()

    #And set the beacon's owner.
    @display_beacon_owner(owner)
    @perform_api_call('claim', owner, @update_complete)


  #
  # Sets the beacon's affiliation; indicating which side of the "game field" it's on.
  # Valid affiliations are "red" or "green".
  #
  set_affiliation: (affiliation) ->
    @perform_api_call('affiliate', affiliation, @update_complete)


  #
  # Handles a modification of the "simulation enable" or "simulation intervals" control.
  #
  update_simulation_parameters: =>

    #Determine if the Gameplay Simulation should be enabled or disabled.
    if @_simulation_is_enabled()
      @_enable_simulation_controls()
      interval = @simulation_controls.simulation_interval.val() * 1000
    else
      @_disable_simulation_controls()
      interval= null

    #... and set the simulation interval accordingly.
    @_set_simulation_interval(interval)


  #
  # Sets up the internal simulation interval.
  #
  # interval: The time interval with which the simulation commands should be 
  #           performed, in milliseconds-- or null do disable simulation.
  #
  _set_simulation_interval: (interval) =>

    console.log "Setting ye interval to #{interval}, captain!"
 
    #If an interval exists, clear it.
    clearInterval(@simulation_interval)

    #If an interval was provided, create a new interval.
    @simulation_interval = setInterval(@handle_simulation, interval) if interval?


  #
  # Enables (or disables) the simulation controls.
  #
  # enable: If true, simulation controls will be enabled-- otherwise, the simulation controls will be disabled.
  #
  _enable_simulation_controls: (enable=true) =>

    #Enable or disable the core inputs, as applicable.
    @simulation_controls.probabilistically_capture.prop('disabled', not enable)
    @simulation_controls.capture_probability.prop('disabled', not enable)

    #Add or remove the "disabled" colorization from the simulation controls.
    label = @simulation_controls.probabilistically_capture_label
    if enable
      label.removeClass('disabled')
    else
      label.addClass('disabled')


  #
  # Convenience shortcut for _enable_simulation_controls(false). 
  # Disables all simulation controls.
  #
  _disable_simulation_controls: =>
    @_enable_simulation_controls(false)


  #
  # Handles the execution of the "gameplay simulation".
  #
  handle_simulation: =>
    @claim_beacon(@opponent_color()) if @_simulation_capture_should_be_applied()


  #
  # Determines if the given simulation capture shold be applied--
  # this is a function of the probability settings.
  #
  _simulation_capture_should_be_applied: =>
   
    #If probabilistic simulation isn't on, then all captures shold be applied.
    return true unless @simulation_controls.simulation_enable.is(':checked')

    #Get the probability of application for a single simulation, as a fraction of '1',
    #where '1' means "always apply".
    probability = @simulation_controls.capture_probability.val() / 100

    #Return true iff a random number in the range (0,1] was less than the desired probability;
    #this should be true with the same probability as given. (JS's random function is uniform.)
    return Math.random() <= probability


  #
  # Logs any state changes that occur between two states to the event log.
  #
  _log_state_changes: (old_state, new_state) =>

    #If we've just connected a beacon, log its state.
    if old_state is null and new_state isnt null
      @_log_state_on_connection(new_state)
      return

    #If the beacon hasn't changed owners, check for any failed claim attempts.
    if old_state.owner is new_state.owner

      #If we've recieved an incorrect claim code, log the event.
      if new_state.last_claim == -2
        @_log_event("An invalid claim attempt was made; the response code was not properly framed.")
      else if new_state.last_claim

        #Compute the correct value for the claim code...
        response_code = 255 - new_state.claim_code

        #... and notify the user of the incident.
        @_log_event("An invalid claim attempt was made. The response code was <strong>#{new_state.last_claim} " +
          "<code>(0b#{new_state.last_claim.toString(2)})</code></strong>, but should have been <strong>#{response_code}" +
          " <code>(0b#{response_code.toString(2)})</strong></code>.")


    #If the beacon has changed owners, report it!
    else
     
      #If this beacon is being manually forced to "unclaimed", repor that.
      if new_state.owner is "none"
        @_log_event("A beacon was taken from the <strong>#{old_state.owner}</strong> team, and is now <strong>unclaimed</strong>.")

      #Otherwise, manually report the change.
      else
        old_owner = if old_state.owner == "none" then "unclaimed" else old_state.owner
        @_log_event("The <strong>#{new_state.owner}</strong> team has claimed a <strong>#{old_state.owner}</strong> beacon!")


  #
  # Logs the state of the beacon on a connection.
  #
  _log_state_on_connection: (new_state) =>
    return unless new_state.affiliation? and new_state.owner?

    #Create a message that describes the beacon's current claim status.
    if new_state.owner is "none"
      owned_status = "unclaimed"
    else
      owned_status = "claimed by the #{new_state.owner} team"

    #And log the connection state.
    @_log_event("A beacon was connected on the <strong>#{new_state.affiliation} side of the board</strong>; and is currently <strong>#{owned_status}<strong>.")


  #
  # Adds a given message to the event log.
  #
  _log_event: (message, time = null) =>

    #Create a timestamp for the given message.
    time ||= new Date()

    #Create a new list-item with the given message.
    new_event = $(document.createElement('li'))
    new_event.append("<strong>#{@_create_log_time(time)}</strong>\t- #{message}")

    #And add our new event to it.
    @event_log.prepend(new_event)


  #
  # Creates a time in event-log format.
  #
  _create_log_time: (time = Date) ->

    #Get a human-readable hourly date.
    hours = (time.getHours() % 12) || 12
    am_pm = if time.getHours() > 11 then "PM" else "AM"

    #Format the given timestamp.
    #http://codereview.stackexchange.com/questions/15097/coffeescript-date-formatting
    timestamp = [hours, time.getMinutes(), time.getSeconds()].join(':')
    timestamp = timestamp.replace( /\b(\d)\b/g, "0$1" )
    timestamp = timestamp.replace /\s/g, ""

    #Return the 12-hour time.
    "#{timestamp} #{am_pm}"





  #
  # Returns the color of the active state's "opponent".
  #
  opponent_color: =>
    switch @state?.affiliation
      when 'red'   then return 'green'
      when 'green' then return 'red'
      else return 'none'


  #
  # Returns true iff the user has enabled simulation.
  #
  _simulation_is_enabled: =>
    @simulation_controls.simulation_enable.is(':checked')


  #
  # Puts the application into an "update in progress" mode, 
  # during which we don't allow the "heartbeat" to update the view.
  #
  start_update: =>
    @updating = true

  #
  # Takes the application out of "update pending" mode.
  #
  update_complete: =>
    @updating = false
  
  
  
#Run the initialization function when the gui is ready.
$(document).ready ->
  window.app = new BeaconTestApplication($('#owner'))
  window.app.run()

