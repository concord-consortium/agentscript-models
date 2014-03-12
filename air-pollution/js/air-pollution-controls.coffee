class AirPollutionControls
  setupCompleted: false
  setup: ->
    if @setupCompleted
      $("#controls").show()
    else
      # do other stuff
      @setupGraph()
      @setupPlayback()
      @setupSliders()

      $("#controls").show()
      @setupCompleted = true

  pollutionGraph: null
  setupGraph: ->
    if $("#output-graphs").length == 0 then return

    ABM.model.graphSampleInterval = 10
    defaultOptions =
      title:  "Primary (red), Secondary (black) Pollutants"
      xlabel: "Time (ticks)"
      ylabel: "AQI"
      xmax:   2100
      xmin:   0
      ymax:   300
      ymin:   0
      xTickCount: 7
      yTickCount: 10
      xFormatter: "3.3r"
      sample: 10
      realTime: true
      fontScaleRelativeToParent: true
      dataColors: [
        [160,   0,   0],
        [ 44, 160,   0],
        [ 44,   0, 160],
        [  0,   0,   0],
        [255, 127,   0],
        [255,   0, 255]]

    @pollutionGraph = LabGrapher '#pollution-graph', defaultOptions

    # start the graph at 0,0
    @pollutionGraph.addSamples [[0],[0],[0],[0]]

    # hack (for now) to make y-axis non-draggable
    $(".draggable-axis[x=24]").css("cursor","default").attr("pointer-events", "none")
    $(".y text").css("cursor", "default")

    $(document).on AirPollutionModel.GRAPH_INTERVAL_ELAPSED, =>
      p = ABM.model.primaryAQI()
      s = ABM.model.secondaryAQI()
      @pollutionGraph.addSamples [[p], [0], [0], [s]]
      $("#raw-primary").text(ABM.model.primary.length)
      $("#raw-secondary").text(ABM.model.secondary.length)
      $("#aqi-primary").text(p)
      $("#aqi-secondary").text(s)

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
      value: ABM.model.windSpeed
      slide: (evt, ui)->
        ABM.model.setWindSpeed ui.value
        if ui.value > 0
          opacity = 0.5 - (ui.value/60)
          $("#lower-air-temperature").stop().animate({opacity: opacity})
        else
          $("#lower-air-temperature").stop().animate({opacity: 1})

    $("#cars-slider").slider
      orientation: 'horizontal'
      min: 0
      max: 10
      step: 1
      value: ABM.model.getNumCars()
      slide: (evt, ui)->
        ABM.model.setNumCars ui.value

    $("#sunlight-slider").slider
      orientation: 'horizontal'
      min: 0
      max: 10
      step: 1
      value: ABM.model.sunlightAmount
      slide: (evt, ui)->
        ABM.model.setSunlight ui.value
      change: (evt, ui)->
        ABM.model.setSunlight ui.value

    $("#rain-slider").slider
      orientation: 'horizontal'
      min: 0
      max: 6
      step: 1
      value: ABM.model.rainRate
      slide: (evt, ui)->
        ABM.model.setRainRate ui.value
      change: (evt, ui)->
        ABM.model.setRainRate ui.value

    $("#cars-pollution-slider").slider
      orientation: 'horizontal'
      min: 0
      max: 100
      step: 5
      value: ABM.model.carPollutionRate
      slide: (evt, ui)->
        ABM.model.carPollutionRate = ui.value

    $("#cars-pollution-control-slider").slider
      orientation: 'horizontal'
      min: 0
      max: 100
      step: 5
      value: 100 - ABM.model.carPollutionRate
      slide: (evt, ui)->
        ABM.model.carPollutionRate = 100 - ui.value

    $("#cars-electric-slider").slider
      orientation: 'horizontal'
      min: 0
      max: 100
      step: 10
      value: ABM.model.electricCarPercentage
      slide: (evt, ui)->
        ABM.model.electricCarPercentage = ui.value

    $("#factories-slider").slider
      orientation: 'horizontal'
      min: 0
      max: 5
      step: 1
      value: ABM.model.getNumFactories()
      slide: (evt, ui)->
        ABM.model.setNumFactories ui.value

    $("#factories-pollution-slider").slider
      orientation: 'horizontal'
      min: 0
      max: 100
      step: 5
      value: ABM.model.factoryPollutionRate
      slide: (evt, ui)->
        ABM.model.factoryPollutionRate = ui.value

    $("#factories-pollution-control-slider").slider
      orientation: 'horizontal'
      min: 0
      max: 100
      step: 5
      value: 100 - ABM.model.factoryPollutionRate
      slide: (evt, ui)->
        ABM.model.factoryPollutionRate = 100 - ui.value

    $("#temperature-slider").slider
      orientation: 'horizontal'
      min: 0
      max: 100
      step: 10
      value: ABM.model.temperature
      slide: (evt, ui)->
        ABM.model.temperature = ui.value

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
    $(".icon-pause").hide()
    $(".icon-play").show()

    @pollutionGraph.reset()
    @pollutionGraph.addSamples [[0],[0],[0],[0]]

    setTimeout ->
      ABM.model.reset()
    , 10

window.AirPollutionControls = AirPollutionControls
$(document).trigger 'air-pollution-controls-loaded'