$percipitationSlider = $ "#percipitation-slider"

$ ->
  $("button").button()
  $("#playback").buttonset()
  $(".icon-pause").hide()
  $(".chosen-select").chosen
    disable_search:true
    width: 110
  $percipitationSlider.slider  min: 0, max: 500, step: 1, value: 166

window.initControls = ->
  $('#date-string').text(model.dateString)

reset = ->
  model.stop()
  $(".icon-pause").hide()
  $(".icon-play").show()
  model.reset()

$('#play-pause-button').click ->
  if model.anim.animStop
    model.start()
    $(".icon-pause").show()
    $(".icon-play").hide()
  else
    model.stop()
    $(".icon-pause").hide()
    $(".icon-play").show()

$('#reset-button').click reset


$("#terrain-options").change (evt, ui) ->
  model.setLandType ui.selected
  reset()

$percipitationSlider.on 'slide', (event, ui) ->
  model.setPercipitation ui.value

$('input.property').click ->
  $this    = $(this)
  property = $this.attr('id')
  checked  = $this.is(':checked')
  model[property] = checked
  true

$(document).on LandManagementModel.STEP_INTERVAL_ELAPSED, ->
  $('#date-string').text(model.dateString)


controlsLoaded.resolve()