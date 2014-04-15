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
  $(".chosen-select").chosen
    disable_search:true
    width: 158
  $precipitationSlider.slider  min: 0, max: 500, step: 1, value: 166
  $zone1Slider.slider  min: -5, max: 5, step: 1, value: 0
  $zone2Slider.slider  min: -5, max: 5, step: 1, value: 0

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
  selection = ui.selected
  model.setLandType selection
  reset()

  enableZoneSliders(selection is "Sliders")

$("#zone1-planting-options").change (evt, ui) ->
  selection = ui.selected
  model.setZoneManagement 0, selection

  reset() unless ~selection.indexOf("wheat") && ~zone1Planting.indexOf("wheat")
  zone1Planting = selection

$("#zone2-planting-options").change (evt, ui) ->
  selection = ui.selected
  model.setZoneManagement 1, selection

  reset() unless ~selection.indexOf("wheat") && ~zone2Planting.indexOf("wheat")
  zone2Planting = selection

$precipitationSlider.on 'slide', (event, ui) ->
  model.setUserPrecipitation ui.value
  updatePrecipitationBarchart model.getCurrentClimateData()
  $("#precipitation-value").text model.precipitation

$("#climate-options").change (evt, ui) ->
  selection = ui.selected
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
      dataColors: [
        [160,   0,   0],
        [ 44, 160,   0],
        [ 44,   0, 160],
        [  0,   0,   0],
        [255, 127,   0],
        [255,   0, 255]]
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
      dataColors: [
        [160,   0,   0],
        [ 44, 160,   0],
        [ 44,   0, 160],
        [  0,   0,   0],
        [255, 127,   0],
        [255,   0, 255]]
    )

$(document).on LandManagementModel.STEP_INTERVAL_ELAPSED, ->
  $('#date-string').text(model.dateString)
  if erosionGraph then erosionGraph.addSamples [0,0,0,0,model.zone1ErosionCount, model.zone2ErosionCount]
  model.resetErosionCounts()
  if topsoilCountGraph
    topsoilInZone = model.topsoilInZones()
    topsoilCountGraph.addSamples [0, 0, 0, 0, topsoilInZone[1], topsoilInZone[2]]


$(document).on LandManagementModel.STEP_INTERVAL_ELAPSED, ->
  $(".inner-bar").removeClass "current-month"
  $($(".inner-bar")[model.month]).addClass "current-month"
  $("#precipitation-value").text model.precipitation
