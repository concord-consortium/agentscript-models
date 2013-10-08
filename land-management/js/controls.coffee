$ ->
  $("button").button()
  $("#playback").buttonset()
  $(".icon-pause").hide()
  $(".chosen-select").chosen
    disable_search:true
    width: 110

window.initControls = ->
  $("#terrain-options").change (evt, ui) ->
    model.setLandType ui.selected
    reset()

reset = ->
  model.stop()
  $(".icon-pause").hide()
  $(".icon-play").show()
  model.setup()

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