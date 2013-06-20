class FrackingControls
  setup: ->
    # do stuff
    if ABM.model?
      @setupPlayback()
      @setupDrilling()
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

  setupDrilling: ->
    timerId = null
    $("#mouse-catcher").mousedown (evt)=>
      @stopModel()
      timerId = setInterval ->
        ABM.model.drill ABM.model.patches.patchAtPixel(evt.offsetX, evt.offsetY)
      , 100
    .bind 'mouseup mouseleave', ->
      clearInterval timerId if timerId?

  startStopModel: ->
    @stopModel() unless @startModel()

  stopModel: ->
    if ABM.model.anim.animStop
      return false
    else
      ABM.model.stop()
      $(".icon-pause").hide()
      $(".icon-play").show()
      return true

  startModel: ->
    if ABM.model.anim.animStop
      ABM.model.start()
      $(".icon-pause").show()
      $(".icon-play").hide()
      return true
    else
      return false

  resetModel: ->
    ABM.model.reset()
    $(".icon-pause").hide()
    $(".icon-play").show()

window.FrackingControls = FrackingControls
$(document).trigger('controls-ready')