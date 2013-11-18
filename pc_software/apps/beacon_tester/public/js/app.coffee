
#Function which requests a device status update from the RISE sevrer.
update_status = -> $.getJSON('/ajax/connected_boards', null, apply_status)

#
#Function which applies the result of a device status update from the RISE app.
#
apply_status = (status) ->

  #Set the global status.
  window.rise.status = status

  #And update the "connected board" field.
  $('#connected_board').html(status.connected_board || 'No boards found.')

  #If the view wants to be queued in on status updates, pass the status to the view.
  view_apply_status?(status)

#
# Function which initializes the Rise common GUI elements.
#
initialize_rise = ->

  #Create an empty namespace for Rise's globals.
  window.rise = {}

  #Set up the status update 'heartbeat' function.
  setInterval(update_status, 1000)


#Run the initialization function when the gui is ready.
$(document).ready(initialize_rise)

