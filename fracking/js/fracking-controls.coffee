class FrackingControls
  setup: ->
    # do stuff
    if ABM.model?
      @setupPlayback()
    else
      console.log("delaying...")
      setTimeout =>
        @setup()
      , 500

  setupPlayback: ->
      $(".icon-pause").hide()
      $(".icon-play").show()
      $("#controls").show()
      $("#play-pause-button").button()
      .click =>
        @startStopModel()
      $("#reset-button").button()
      .click =>
        @resetModel()
      $("#playback").buttonset()

  startStopModel: ->
    if ABM.model.anim.animStop
      ABM.model.start()
      $(".icon-pause").show()
      $(".icon-play").hide()
    else
      ABM.model.stop()
      $(".icon-pause").hide()
      $(".icon-play").show()

  resetModel: ->
    ABM.model.reset()
    $(".icon-pause").hide()
    $(".icon-play").show()

window.FrackingControls = FrackingControls
$(document).trigger('controls-ready')