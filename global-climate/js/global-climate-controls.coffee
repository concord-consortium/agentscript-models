$albedoSlider      = $ '#albedo-slider'
$sunSlider         = $ '#sun-brightness-slider'
$iceSlider         = $ '#ice-slider'
$emissionsSlider   = $ '#human-emissions-slider'
$temperatureSlider = $ '#temperature-slider'
$speedSlider       = $ '#speed-slider'
$yearCounter       = $ '#year'
$co2Output         = $ '#co2-output'
$temperatureOutput = $ '#temperature-output'

temperatureGraph = null
co2Graph = null

initialTemperature = 0
lastTick = 0
isFollowingAgent = false

temperatureFormatter = d3.format "3.1f"
countFormatter = d3.format "3f"

isOceanModel = false
isOceanTemperatureModel = false

modelSetup = null

window.initControls = (args) ->
  $albedoSlider.slider  min: 0, max: 1, step: 0.01, value: climateModel.getAlbedo()
  $sunSlider.slider     min: 0, max: 200, step: 1,  value: climateModel.getSunBrightness()
  $iceSlider.slider     min: 0, max: 1, step: 0.01,  value: climateModel.getIcePercent() if climateModel.getIcePercent
  $emissionsSlider.slider   min: 0, max: 1, step: 0.1,  value: climateModel.getHumanEmissionRate() if climateModel.getHumanEmissionRate
  $temperatureSlider.slider min: 0, max: 20, step: 0.2,  value: climateModel.getTemperature()
  $speedSlider.slider   min: 20, max: 60, step: 2,  value: climateModel.anim.rate

  initialTemperature = climateModel.getTemperature()

  isOceanModel = true if args?.oceanModel
  isOceanTemperatureModel = true if args?.oceanTemperatureModel

  modelSetup = args?.setup

  setupGraphs()

$(document).ready ->

  labels = [
    { key: "solar radiation", draw: (ctx) -> drawShape ctx, "rgb(235, 235, 0)", "arrow" }
    { key: "infrared radiation", draw: (ctx) -> drawShape ctx, "rgb(200, 32, 200)", "arrow" }
    { key: "carbon dioxide", draw: (ctx) -> drawShape ctx, "rgb(0, 255, 0)", "pentagon", 0.8 }
    { key: "water vapor", draw: (ctx) -> drawShape ctx, "rgb(0, 0, 255)", "circle", 0.8 }
    { key: "heat", draw: (ctx) -> drawShape ctx, "rgb(255, 63, 63)", "circle", 0.8 }
  ]

  drawShape = (ctx, fillStyle, shapeName, scale=1) ->
    ctx.save()
    ctx.translate 20, -6
    ctx.scale 18*scale, -18*scale
    ctx.fillStyle = fillStyle
    ctx.beginPath()
    ABM.shapes[shapeName].draw ctx
    ctx.closePath()
    ctx.fill()
    ctx.restore()

  drawKey = (canvas) ->
    # center the lines vertically
    nLines = 4
    perLine = 30
    ctx = canvas.getContext '2d'
    ctx.fillStyle = 'black'
    ctx.font = '18px "Helvetica Neue", Helvetica, sans-serif'
    ctx.lineWidth = 2
    ctx.translate 0, 30
    for label, i in labels
      ctx.fillText label.key, 50, 0
      label.draw ctx
      ctx.translate 0, perLine

  # add a link that, when clicked, pops up a non-modal, draggable canvas element that shows a key
  # for the different agent shapes
  $showKey = $('<a href="#" class="show-agents-key">show key</a>').appendTo $ '#content'
  $showKey.click ->
    if ($key = $('#agents-key')).length is 0
      $key = $("<div id='agents-key' class='agents-key'><a class='icon-remove-sign icon-large'></a><canvas></canvas></div>").appendTo($ document.body).draggable()
      canvas = $key.find('canvas')[0]
      $key.height 170
      $key.width 200
      canvas.height = $key.outerHeight()
      canvas.width = $key.outerWidth()
      drawKey $key.find('canvas')[0]

    $key.css
      left: '5em'
      top: '5em'
    .show()
    .on 'click', 'a', -> $(this).parent().hide()

$('#play-pause-button').click ->
  if climateModel.anim.animStop
    climateModel.start()
    $(".icon-pause").show()
    $(".icon-play").hide()
  else
    climateModel.stop()
    $(".icon-pause").hide()
    $(".icon-play").show()

$('#reset-button').click ->
  climateModel.stop()
  $(".icon-pause").hide()
  $(".icon-play").show()
  lastTick = 0
  temperatureGraph.reset() if temperatureGraph?
  co2Graph.reset() if co2Graph?
  climateModel.setup()
  $temperatureSlider.slider('value', initialTemperature) if $temperatureSlider
  modelSetup() if modelSetup

$('#add-co2-button').click ->
  climateModel.addCO2()

$('#subtract-co2-button').click ->
  climateModel.subtractCO2()

$('#add-clouds-button').click ->
  climateModel.addCloud()

$('#subtract-clouds-button').click ->
  climateModel.subtractCloud()

$('#erupt-button').click ->
  climateModel.erupt()

$albedoSlider.on 'slide', (event, ui) ->
  climateModel.setAlbedo ui.value

$sunSlider.on 'slide', (event, ui) ->
  climateModel.setSunBrightness ui.value

$iceSlider.on 'slide', (event, ui) ->
  climateModel.setIcePercent ui.value

$emissionsSlider.on 'slide', (event, ui) ->
  climateModel.setHumanEmissionRate ui.value

$temperatureSlider.on 'slide', (event, ui) ->
  climateModel.setFixedTemperature ui.value

$speedSlider.on 'slide', (event, ui) ->
  climateModel.anim.setRate ui.value, false

$('#follow-sunray-button').click ->
  $span = $(this).find("span")
  if $span.text() is "Follow Energy Packet"
    climateModel.addSunraySpotlight()
    $span.text "Stop following"
    isFollowingAgent = true
  else
    climateModel.removeSpotlight()
    $span.text "Follow Energy Packet"
    isFollowingAgent = false

$('#follow-co2-button').click ->
  $span = $(this).find("span")
  if $span.text() is "Follow CO2"
    climateModel.addCO2Spotlight()
    $span.text "Stop following"
    isFollowingAgent = true
  else
    climateModel.removeSpotlight()
    $span.text "Follow CO2"
    isFollowingAgent = false

$('#hide-button').click ->
  $span = $(this).find("span")
  if $span.text() is "Hide 90% of elements"
    climateModel.hide90()
    $span.text "Show all elements"
  else
    climateModel.showAll()
    $span.text "Hide 90% of elements"

$('#show-agent-controls input').click ->
  $this   = $(this)
  func    = $this.attr('id')
  checked = $this.is(':checked')
  climateModel[func](checked)

updateTickCounter = ->
  $yearCounter.text(climateModel.getYear())

setupGraphs = ->
  if $('#temperature-graph').length

    title = "Temperature Change"
    if isOceanTemperatureModel then title += " (red), Ocean change (blue)"

    ymax = if isOceanTemperatureModel then 12 else 12
    ymin = if isOceanTemperatureModel then -12 else -6

    temperatureGraph = LabGrapher('#temperature-graph',
      title:  title
      xlabel: "Time (year)"
      ylabel: "Temperature"
      xmax:   2020
      xmin:   2013
      ymax:   ymax
      ymin:   ymin
      xTickCount: 4
      yTickCount: 5
      xFormatter: "d"
      dataSampleStart: 2013
      sampleInterval: 1/300
      realTime: true
      fontScaleRelativeToParent: true
      dataColors: [
        [160,   0,   0],
        [ 44, 160,   0],
        [ 44,   0, 160],
        [  0,   0,   0],
        [255, 127,   0],
        [255,   0, 255]]
    )

  if $('#co2-graph').length

    title = if isOceanModel then "Air CO2 (red), Ocean CO2 (green)" else "CO2 in atmosphere"
    if climateModel.includeVapor then title += ", Vapor (blue)"
    ymax  = if isOceanModel then 30 else 100

    co2Graph = LabGrapher('#co2-graph',
        title:  title
        xlabel: "Time (year)"
        ylabel: if isOceanModel then "Greenhouse gases" else "CO2"
        xmax:   2020
        xmin:   2013
        ymax:   ymax
        ymin:   0
        xTickCount: 4
        yTickCount: 5
        xFormatter: "d"
        dataSampleStart: 2013
        sampleInterval: 1/300
        realTime: true
        fontScaleRelativeToParent: true
        dataColors: [
          [160,   0,   0],
          [ 44, 160,   0],
          [ 44,   0, 160],
          [  0,   0,   0],
          [255, 127,   0],
          [255,   0, 255]]
      )

d3.timer (elapsed) ->
  if climateModel?
    temperature = climateModel.getTemperature()

    if isOceanTemperatureModel
      oceanTemperature = climateModel.oceanTemperature

    if not isOceanModel
      co2Count = climateModel.getCO2Count()
    else
      atmosphereCO2Count = climateModel.getAtmosphereCO2Count()
      oceanCO2Count = climateModel.getOceanCO2Count()
      vaporCount = climateModel.getVaporCount()
    tick = climateModel.anim.ticks
    ticksElapsed = tick - lastTick

    $temperatureOutput.text(temperatureFormatter(temperature))
    $co2Output.text(countFormatter(co2Count))

    if ticksElapsed and not climateModel.animStop
      while ticksElapsed--  # duplicate data if multiple model steps passed
        if not isOceanTemperatureModel
          temperatureGraph.addSamples [temperature-initialTemperature] unless !temperatureGraph?
        else
          temperatureGraph.addSamples [temperature-initialTemperature, 0, oceanTemperature-initialTemperature] unless !temperatureGraph?

        if not isOceanModel
          co2Graph.addSamples [co2Count] unless !co2Graph?
        else
          co2Graph.addSamples [atmosphereCO2Count, oceanCO2Count, vaporCount] unless !co2Graph?

      updateTickCounter()
      lastTick = tick

    if isFollowingAgent and not climateModel.spotlightAgent?
      $(".follow-agent").each ->
        if ~$(this).find("span").text().indexOf("Stop")
          this.click()

  return null

controlsLoaded.resolve()