class AirPollutionControls
  setupCompleted: false
  setup: ->
    if @setupCompleted
      $("#controls").show()
    else
      # do other stuff
      @setupPlayback()
      @setupSliders()

      $("#controls").show()
      @setupCompleted = true

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

  setupSliders: ->
    $("#wind-slider").slider
      orientation: 'horizontal'
      min: -100
      max: 100
      step: 10
      value: 0
      slide: (evt, ui)->
        ABM.model.setWindSpeed ui.value

    $("#cars-slider").slider
      orientation: 'horizontal'
      min: 0
      max: 10
      step: 1
      value: 1
      slide: (evt, ui)->
        ABM.model.setCars ui.value

    $("#cars-pollution-slider").slider
      orientation: 'horizontal'
      min: 5
      max: 100
      step: 5
      value: 50
      slide: (evt, ui)->
        ABM.model.carPollutionRate = ui.value

    $("#factories-slider").slider
      orientation: 'horizontal'
      min: 0
      max: 5
      step: 1
      value: 1
      slide: (evt, ui)->
        ABM.model.setFactories ui.value

    $("#factories-pollution-slider").slider
      orientation: 'horizontal'
      min: -100
      max: -5
      step: 5
      value: -25
      slide: (evt, ui)->
        ABM.model.factoryPollutionRate = Math.abs ui.value

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
    @stopModel()
    $("#controls").hide()
    $(".icon-pause").hide()
    $(".icon-play").show()
    setTimeout ->
      ABM.model.reset()
    , 10

window.AirPollutionControls = AirPollutionControls
$(document).trigger 'air-pollution-controls-loaded'