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

  timerId: null
  setupDrilling: ->
    return if @timerId?
    target = $("#mouse-catcher")
    target.bind 'mousedown', (evt)=>
      @stopModel()
      @timerId = setInterval =>
        ABM.model.drill ABM.model.patches.patchAtPixel(@offsetX(evt, target), @offsetY(evt, target))
      , 100
    .bind 'mouseup mouseleave', =>
      clearInterval @timerId if @timerId?

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

  offsetX: (evt, target)->
    return if evt.offsetX? then evt.offsetX else (evt.pageX - target.offset().left)

  offsetY: (evt, target)->
    return if evt.offsetY? then evt.offsetY else (evt.pageY - target.offset().top)

window.FrackingControls = FrackingControls
$(document).trigger('controls-ready')