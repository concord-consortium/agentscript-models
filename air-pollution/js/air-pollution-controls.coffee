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
    ABM.model.graphSampleInterval = 10
    defaultOptions =
      title:  "Primary (red), Secondary (green) Pollutants"
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

    @pollutionGraph = Lab.grapher.Graph '#pollution-graph', defaultOptions

    # start the graph at 0,0
    @pollutionGraph.addSamples [[0],[0]]

    # hack (for now) to make y-axis non-draggable
    $(".draggable-axis[x=24]").css("cursor","default").attr("pointer-events", "none")
    $(".y text").css("cursor", "default")

    $(document).on AirPollutionModel.GRAPH_INTERVAL_ELAPSED, =>
      p = ABM.model.primaryAQI()
      s = ABM.model.secondaryAQI()
      @pollutionGraph.addSamples [[p], [s]]
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
      value: 0
      slide: (evt, ui)->
        ABM.model.setWindSpeed ui.value
    ABM.model.setWindSpeed 0

    $("#cars-slider").slider
      orientation: 'horizontal'
      min: 0
      max: 10
      step: 1
      value: 1
      slide: (evt, ui)->
        ABM.model.setCars ui.value
    ABM.model.setCars 1

    $("#cars-pollution-slider").slider
      orientation: 'horizontal'
      min: -100
      max: 5
      step: 5
      value: -50
      slide: (evt, ui)->
        ABM.model.carPollutionRate = Math.abs ui.value
    ABM.model.carPollutionRate = 50

    $("#cars-electric-slider").slider
      orientation: 'horizontal'
      min: 0
      max: 100
      step: 10
      value: 25
      slide: (evt, ui)->
        ABM.model.carElectricRate = ui.value
    ABM.model.carElectricRate = 25

    $("#factories-slider").slider
      orientation: 'horizontal'
      min: 0
      max: 5
      step: 1
      value: 1
      slide: (evt, ui)->
        ABM.model.setFactories ui.value
    ABM.model.setFactories 1

    $("#factories-pollution-slider").slider
      orientation: 'horizontal'
      min: -100
      max: -5
      step: 5
      value: -25
      slide: (evt, ui)->
        ABM.model.factoryPollutionRate = Math.abs ui.value
    ABM.model.factoryPollutionRate = 25

    $("#temperature-slider").slider
      orientation: 'horizontal'
      min: 0
      max: 100
      step: 10
      value: 50
      slide: (evt, ui)->
        ABM.model.temperature = ui.value
    ABM.model.temperature = 50

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