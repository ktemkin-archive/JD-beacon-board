(function() {
  var Bitfile, initialize_programming, initialize_view, view_apply_status;

  Bitfile = (function() {

    function Bitfile() {}

    Bitfile.bitfile_path = function() {
      return $('#pretty_bitfile').val();
    };

    Bitfile.button = $('#program_board');

    Bitfile.error_message = $('program_error');

    Bitfile.program_timeout = null;

    Bitfile.tooltip = false;

    Bitfile.initialize = function() {
      $('#bitfile').niceFileField();
      $('#bitfile').change(Bitfile.trigger_validation);
      $('#pretty_bitfile').bind('input', Bitfile.trigger_validation);
      return Bitfile.button.click(Bitfile.trigger_program);
    };

    Bitfile.trigger_validation = function() {
      var data;
      data = {
        path: Bitfile.bitfile_path
      };
      return $.post('/backend/validate_bitfile', data, Bitfile.validation_complete, 'json');
    };

    Bitfile.validation_complete = function(result) {
      Bitfile.valid_bitfile = result.valid;
      return Bitfile.update();
    };

    Bitfile.add_alert = function(message, type) {
      if (type == null) {
        type = 'error';
      }
      return $('#program_alerts').append("<div class=\"alert alert-" + type + " fade in\">" + message + "<a href=\"#\" class=\"close\" data-dismiss=\"alert\">&times;</a></div>").fadeIn();
    };

    Bitfile.close_alerts = function() {
      return $('#program_alerts .alert').alert('close');
    };

    Bitfile.show_tooltip = function(message) {
      if (Bitfile.tooltip && Bitfile.tooltip !== message) {
        Bitfile.hide_tooltip;
      }
      if (!Bitfile.tooltip) {
        Bitfile.button.tooltip({
          trigger: 'hover',
          placement: 'bottom',
          title: message
        });
        return Bitfile.tooltip = message;
      }
    };

    Bitfile.hide_tooltip = function() {
      Bitfile.button.tooltip('destroy');
      return Bitfile.tooltip = false;
    };

    Bitfile.update = function() {
      var _ref;
      $('#program_board').removeClass('disabled');
      if (!Bitfile.valid_bitfile) {
        $('#program_board').addClass('disabled');
        Bitfile.show_tooltip('Check that the specified bitfile exists.');
        return;
      }
      if (((_ref = window.rise.status) != null ? _ref.connected_board : void 0) == null) {
        $('#program_board').addClass('disabled');
        Bitfile.show_tooltip('Check that you have an FPGA board connected.');
        return;
      }
      return Bitfile.hide_tooltip();
    };

    Bitfile.trigger_program = function() {
      var data;
      if (Bitfile.button.hasClass('disabled')) {
        return;
      }
      Bitfile.close_alerts();
      Bitfile.button.button('loading');
      data = {
        path: Bitfile.bitfile_path
      };
      return $.post('/backend/program', data, Bitfile.program_complete, 'json');
    };

    Bitfile.program_complete = function(status) {
      Bitfile.button.button('reset');
      if (status.success) {
        if (status.warnings != null) {
          return Bitfile.add_alert(status.warnings);
        }
      } else {
        return Bitfile.add_alert(status.message);
      }
    };

    return Bitfile;

  }).call(this);

  view_apply_status = function() {
    return Bitfile.update();
  };

  initialize_programming = function() {};

  initialize_view = function() {
    window.rise.project = {};
    Bitfile.initialize();
    return Bitfile.trigger_validation();
  };

  $(document).ready(initialize_view);

}).call(this);
