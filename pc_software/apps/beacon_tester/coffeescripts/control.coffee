#
#
#class Bitfile
#
#  #
#  # Returns the path of the selected bitfile.
#  #
#  @bitfile_path: =>
#    $('#pretty_bitfile').val()
#
#  #
#  # Shortcut to the button being controlled.
#  #
#  @button = $('#program_board')
#  @error_message = $('program_error')
# 
#
#  #
#  # Programming timeout; prevents things from getting into an uncertain state.
#  #
#  @program_timeout = null
#
#  #
#  # Bitfile's tooltip state.
#  # Start off with no tooltip being displayed.
#  #
#  @tooltip = false
#
#  #
#  # Initializes the Bitfile handler.
#  #
#  @initialize: =>
#    #Bitfile input field...
#    $('#bitfile').niceFileField()
#    $('#bitfile').change(Bitfile.trigger_validation)
#    $('#pretty_bitfile').bind('input', Bitfile.trigger_validation)
#
#    #Bitfile program button.
#    @button.click(@trigger_program)
#
#  #
#  # Handles events which should trigger validation of the Bitfile field.
#  #
#  @trigger_validation:  =>
#    data = { path: @bitfile_path }
#    $.post('/backend/validate_bitfile', data, @validation_complete, 'json')
#
#  #
#  # Handles the "validation complete" event.
#  #
#  @validation_complete: (result) =>
#
#    #Set the internal "bitfile valid" flag.
#    @valid_bitfile = result.valid
#
#    #Ensure that we have a connected board.
#    @update()
#
#  #
#  # Adds a given alert to the programming box.
#  #
#  @add_alert: (message, type='error') =>
#    $('#program_alerts').append("<div class=\"alert alert-#{type} fade in\">#{message}<a href=\"#\" class=\"close\" data-dismiss=\"alert\">&times;</a></div>").fadeIn()
#
#  @close_alerts: =>
#    $('#program_alerts .alert').alert('close')
#    
#  #
#  # Shows a tooltip displaying why the program function is disabled.
#  #
#  @show_tooltip: (message) =>
#
#    #If we have a tooltip, and it's not displaying the current message,
#    #destroy the old tooltip.
#    if @tooltip and @tooltip != message
#      @hide_tooltip
#
#    #If we don't already have a tooltip with this message, create one.
#    unless @tooltip
#      @button.tooltip({ trigger: 'hover', placement: 'bottom', title: message })
#      @tooltip = message
#
#  #
#  # Removes the tooltip from the program button.
#  # 
#  @hide_tooltip: =>
#      @button.tooltip('destroy')
#      @tooltip = false
#
#  #
#  # Updates the status of the bitfile programmer according to the status 
#  # of the current board.
#  #
#  @update: =>
#    $('#program_board').removeClass('disabled')
#
#    #If we have an invalid path, disable programming.
#    unless @valid_bitfile
#      $('#program_board').addClass('disabled')
#      @show_tooltip('Check that the specified bitfile exists.')
#      return
#
#    #If we have no connected board, disable programming.
#    unless window.rise.status?.connected_board?
#      $('#program_board').addClass('disabled')
#      @show_tooltip('Check that you have an FPGA board connected.')
#      return
#
#    @hide_tooltip()
#
#  #
#  # Sets up programming of the given bitfile.
#  #
#  @trigger_program: =>
#
#    #Don't ever program if the button is disabled.
#    return if @button.hasClass('disabled')
#
#    #Close all existing alerts...
#    @close_alerts()
#    @button.button('loading')
#
#    #And ask the device to program itself.
#    data = { path: @bitfile_path }
#    $.post('/backend/program', data, @program_complete, 'json')
#
#  #
#  # Handles status retur
#  #
#  @program_complete: (status) =>
#    
#    #Take the 'program' button out of its programming state...
#    @button.button('reset')
#
#    #Show/hide the error panel, depending on the result of the programming.
#    if status.success
#      @add_alert(status.warnings) if status.warnings?
#    else
#      @add_alert(status.message) 
#      
#
#    
#
##
## Update the view's status after we get a status update from
## the Rise server.
##
#view_apply_status = () ->
#  Bitfile.update()
#
#initialize_programming = ->
#
#initialize_view = ->
#
#  #Create a sub-namespace for the Project view.
#  #window.rise.project = {}
#
#  Bitfile.initialize()
#
#  Bitfile.trigger_validation()
#
##Run the initialization function when the gui is ready.
##$(document).ready(initialize_view)
