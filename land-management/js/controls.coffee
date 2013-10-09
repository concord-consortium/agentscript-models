$percipitationSlider = $ "#percipitation-slider"
erosionGraph = null

$ ->
  $("button").button()
  $("#playback").buttonset()
  $(".icon-pause").hide()
  $(".chosen-select").chosen
    disable_search:true
    width: 110
  $percipitationSlider.slider  min: 0, max: 500, step: 1, value: 166

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
  model.setLandType ui.selected
  reset()

$percipitationSlider.on 'slide', (event, ui) ->
  model.setPercipitation ui.value

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