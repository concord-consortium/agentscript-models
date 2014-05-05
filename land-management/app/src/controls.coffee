# Color scheme from: http://colorschemedesigner.com/#2p42z----gVvy

MAGENTA = [255, 50, 185]
DARK_MAGENTA = [255, 0, 130]
ORANGE  = [255, 195, 50]
DARK_ORANGE = [255, 148, 0]
GREEN = [161, 255, 0]
DARK_GREEN = [131, 208, 0]
BLUE = [0, 139, 255]
DARK_BLUE = [0, 114, 208]

$precipitationSlider = $ "#precipitation-slider"
$precipitationSliderDiv = $ "#user-precipitation"
$zone1Slider = $ "#zone-1-slider"
$zone2Slider = $ "#zone-2-slider"
$slopeSlidersDiv = $ "#slope-sliders"
erosionGraph = null
topsoilCountGraph = null
zone1Planting = ""
zone2Planting = ""

enableZoneSliders = (enable) ->
  $zone1Slider.slider if enable then "enable" else "disable"
  $zone2Slider.slider if enable then "enable" else "disable"
  if enable then $slopeSlidersDiv.removeClass "disabled" else $slopeSlidersDiv.addClass "disabled"

updatePrecipitationBarchart = (data) ->
  $(".inner-bar").each (i) ->
    $this = $(this)
    precip = data[i]
    normalized = precip / 500
    height = 55 * normalized
    margin = 55 - height
    $this.stop true
    $this.animate height: height, marginTop: margin, alt: height
    $this.parent().attr({title: precip})

$ ->
  $("button").button()
  $("#playback").buttonset()
  $(".icon-pause").hide()

  $precipitationSlider.slider  min: 0, max: 500, step: 1, value: 166
  $zone1Slider.slider  min: -3, max: 3, step: 0.5, value: 0
  $zone2Slider.slider  min: -3, max: 3, step: 0.5, value: 0

  enableZoneSliders false
  $precipitationSlider.slider("disable")


window.initControls = ->
  $('#date-string').text(model.dateString)
  setupGraphs()
  updatePrecipitationBarchart model.getCurrentClimateData()

reset = ->
  model.stop()
  $(".icon-pause").hide()
  $(".icon-play").show()
  model.reset()
  erosionGraph.reset() if erosionGraph?
  topsoilCountGraph.reset() if topsoilCountGraph?

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
  selection = $(this).val()
  model.setLandType selection
  reset()

  enableZoneSliders(selection is "Sliders")

$("#zone1-planting-options").change ->
  selection = $(this).val()
  model.setZoneManagement 0, selection
  zone1Planting = selection

$("#zone2-planting-options").change ->
  selection = $(this).val()
  model.setZoneManagement 1, selection
  zone2Planting = selection

$precipitationSlider.on 'slide', (event, ui) ->
  model.setUserPrecipitation ui.value
  updatePrecipitationBarchart model.getCurrentClimateData()
  $("#precipitation-value").text model.precipitation

$("#climate-options").change ->
  selection = $(this).val()
  model.setClimate selection
  enable = selection is "user"
  $precipitationSlider.slider if enable then "enable" else "disable"
  if enable then $precipitationSliderDiv.removeClass "disabled" else $precipitationSliderDiv.addClass "disabled"

  updatePrecipitationBarchart model.getCurrentClimateData()
  $("#precipitation-value").text model.precipitation

$zone1Slider.on 'slide', (event, ui) ->
  model.zone1Slope = ui.value
  reset()

$zone2Slider.on 'slide', (event, ui) ->
  model.zone2Slope = ui.value
  reset()

$('input.property').click ->
  $this    = $(this)
  property = $this.attr('id')
  checked  = $this.is(':checked')
  model[property] = checked
  true

autoscaleBoth = do ->
  autoscaling = false
  ->
    unless autoscaling
      autoscaling = true
      erosionGraph?.autoscale()
      topsoilCountGraph?.autoscale()
      autoscaling = false

setupGraphs = ->
  if $('#erosion-graph').length

    erosionGraph = LabGrapher('#erosion-graph',
      title:  "Erosion Rates"
      xlabel: "Time (year)"
      ylabel: "Monthly Erosion"
      xmax:   2020
      xmin:   2013
      ymax:   100
      ymin:   0
      xTickCount: 4
      yTickCount: 5
      xFormatter: "d"
      dataSampleStart: 2013
      sampleInterval: 1/60
      realTime: true
      fontScaleRelativeToParent: true
      onAutoscale: autoscaleBoth
      dataColors: [
        DARK_BLUE,
        DARK_GREEN
      ]
    )

  if $('#topsoil-count-graph').length
    topsoilCountGraph = LabGrapher('#topsoil-count-graph',
      title:  "Amount of Topsoil in Zone"
      xlabel: "Time (year)"
      ylabel: "Amount of Topsoil"
      xmax:   2020
      xmin:   2013
      ymax:   1000
      ymin:   0
      xTickCount: 4
      yTickCount: 5
      xFormatter: "d"
      dataSampleStart: 2013
      sampleInterval: 1/60
      realTime: true
      fontScaleRelativeToParent: true
      onAutoscale: autoscaleBoth
      dataColors: [
        DARK_BLUE,
        DARK_GREEN
      ]
    )

do ->
  # simple exponential smoothing with alpha = 0.3
  makeSmoothed = ->
    s = null
    alpha = 0.3
    (x) -> if s is null then (s = x) else (s = alpha * x + (1 - alpha) * s)

  zone1Smoothed = makeSmoothed()
  zone2Smoothed = makeSmoothed()

  $(document).on LandManagementModel.STEP_INTERVAL_ELAPSED, ->
    $('#date-string').text(model.dateString)
    if erosionGraph
      erosionGraph.addSamples [
        zone1Smoothed(model.zone1ErosionCount),
        zone2Smoothed(model.zone2ErosionCount)
      ]
    model.resetErosionCounts()
    if topsoilCountGraph
      topsoilInZone = model.topsoilInZones()
      topsoilCountGraph.addSamples [topsoilInZone[1], topsoilInZone[2]]


$(document).on LandManagementModel.STEP_INTERVAL_ELAPSED, ->
  $(".inner-bar").removeClass "current-month"
  $($(".inner-bar")[model.month]).addClass "current-month"
  $("#precipitation-value").text model.precipitation
