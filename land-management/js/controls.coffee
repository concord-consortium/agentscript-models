$percipitationSlider = $ "#percipitation-slider"
$zone1Slider = $ "#zone-1-slider"
$zone2Slider = $ "#zone-2-slider"
$slopeSlidersDiv = $ "#slope-sliders"
erosionGraph = null



enableZoneSliders = (enable) ->
  $zone1Slider.slider if enable then "enable" else "disable"
  $zone2Slider.slider if enable then "enable" else "disable"
  if enable then $slopeSlidersDiv.removeClass "disabled" else $slopeSlidersDiv.addClass "disabled"

$ ->
  $("button").button()
  $("#playback").buttonset()
  $(".icon-pause").hide()
  $(".chosen-select").chosen
    disable_search:true
    width: 158
  $percipitationSlider.slider  min: 0, max: 500, step: 1, value: 166
  $zone1Slider.slider  min: -5, max: 5, step: 1, value: 0
  $zone2Slider.slider  min: -5, max: 5, step: 1, value: 0

  enableZoneSliders false



window.initControls = ->
  $('#date-string').text(model.dateString)
  setupGraphs()

reset = ->
  model.stop()
  $(".icon-pause").hide()
  $(".icon-play").show()
  model.reset()
  erosionGraph.reset() if erosionGraph?

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
  reset()

$("#zone2-planting-options").change (evt, ui) ->
  selection = ui.selected
  model.setZoneManagement 1, selection
  reset()

$percipitationSlider.on 'slide', (event, ui) ->
  model.setPercipitation ui.value

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

    erosionGraph = Lab.grapher.Graph('#erosion-graph',
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
    )

$(document).on LandManagementModel.STEP_INTERVAL_ELAPSED, ->
  $('#date-string').text(model.dateString)
  erosionGraph.addSamples [0,0,0,0,model.zone1ErosionCount, model.zone2ErosionCount]
  model.resetErosionCounts()

controlsLoaded.resolve()