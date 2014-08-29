// shows or hides an instructions overlay for a model
function toggleInstructionsOverlay() {
  if ($('#instructions-overlay').css('display') != 'block') {
    $('#instructions-overlay').fadeIn('slow');
    $('#instructions-toggle').text('hide help');
  } else {
    $('#instructions-overlay').fadeOut('slow');
    $('#instructions-toggle').text('show help');
  }
}