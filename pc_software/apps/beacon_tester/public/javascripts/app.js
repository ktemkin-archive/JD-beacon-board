(function() {
  var apply_status, initialize_rise, update_status;

  update_status = function() {
    return $.getJSON('/ajax/connected_board', null, apply_status);
  };

  apply_status = function(status) {
    window.rise.status = status;
    $('#connected_board').html(status.location || 'No boards found.');
    return typeof view_apply_status === "function" ? view_apply_status(status) : void 0;
  };

  initialize_rise = function() {
    window.rise = {};
    return setInterval(update_status, 1000);
  };

  $(document).ready(initialize_rise);

}).call(this);
