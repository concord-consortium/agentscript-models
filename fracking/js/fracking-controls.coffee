class FrackingControls
  setupCompleted: false
  setup: ->
    # do stuff
    if ABM.model?
      if @setupCompleted
        $("#controls").show()
      else
        @setupPlayback()
        @setupDrilling()
        @setupOperations()
        @setupTriggers()
        @setupGraph()
        @setupCompleted = true
    else
      console.log("delaying...")
      setTimeout =>
        @setup()
      , 500

  setupPlayback: ->
      $(".icon-pause").show()
      $(".icon-play").hide()
      $("#controls").show()
      $("#play-pause-button").button()
      .click =>
        @startStopModel()
      $("#reset-button").button()
      .click =>
        @resetModel()
      $("#playback").buttonset()

  setupTriggers: ->
    $(document).on Well.CAN_EXPLODE, =>
      @updateControls()
    $(document).on Well.EXPLODED, =>
      @updateControls()
    $(document).on Well.FILLED, =>
      @updateControls()
    $(document).on Well.FRACKED, =>
      @updateControls()
    $(document).on Well.CAPPED, =>
      @updateControls()
      @startModel()
    @updateControls()

  updateControls: ->
    for c in ["#explosion","#fill-water","#fill-propane","#remove-fluid"]
      $(c).button("disable")

    for w in ABM.model.wells
      continue if w.capped or w.explodingInProgress or w.fillingInProgress or w.frackingInProgress or w.cappingInProgress
      if w.fracked
        $("#remove-fluid").button("enable")
      else if w.filled
        # do nothing - we're automatically forwarded to the fracking stage
      else if w.exploded and w.exploding.length <= 0
        $("#fill-water").button("enable")
        $("#fill-propane").button("enable")
      else if w.goneHorizontal
        $("#explosion").button("enable")

  timerId: null
  setupDrilling: ->
    $("#drill-left").button().click =>
      @stopDrilling("left")
      if $("#drill-left")[0]?.checked
        ABM.model.drillDirection = "left"
      else
        ABM.model.drillDirection = null

    $("#drill-down").button().click =>
      @stopDrilling("down")
      if $("#drill-down")[0]?.checked
        ABM.model.drillDirection = "down"
      else
        ABM.model.drillDirection = null

    $("#drill-right").button().click =>
      @stopDrilling("right")
      if $("#drill-right")[0]?.checked
        ABM.model.drillDirection = "right"
      else
        ABM.model.drillDirection = null

    $("#drilling-buttons").buttonset()

    target = $("#mouse-catcher")
    target.bind 'mousedown', (evt)=>
      return if @timerId?
      @timerId = setInterval =>
        p = ABM.model.patches.patchAtPixel(@offsetX(evt, target), @offsetY(evt, target))
        ABM.model.drill p
        well = ABM.model.findNearbyWell(p)
        if well?
          depthBelowViewport = $("#model").height() - ($("#model-viewport").scrollTop() + $("#model-viewport").height()) - (well.depth*2)
          if depthBelowViewport > -200
            $("#model-viewport").animate {scrollTop: "+=" + (depthBelowViewport + 400)}, 300
      , 100
    .bind 'mouseup mouseleave', =>
      clearInterval @timerId if @timerId?
      @timerId = null

  stopDrilling: (source)->
    if source isnt "left"
      $("#drill-left").click() if $("#drill-left")[0]?.checked
    if source isnt "down"
      $("#drill-down").click() if $("#drill-down")[0]?.checked
    if source isnt "right"
      $("#drill-right").click() if $("#drill-right")[0]?.checked

  setupOperations: ->
    $("#explosion").button().click =>
      $("#explosion").button("disable")
      ABM.model.explode()
    $("#fill-water").button().click =>
      $("#fill-water").button("disable")
      $("#fill-propane").button("disable")
      ABM.model.floodWater()
    $("#fill-propane").button().click =>
      $("#fill-water").button("disable")
      $("#fill-propane").button("disable")
      ABM.model.floodPropane()
    $("#remove-fluid").button().click =>
      $("#remove-fluid").button("disable")
      ABM.model.pumpOut()

  outputGraph: null
  outputGraphs: null
  setupGraph: ->
    outputOptions =
      title:  "Methane Production"
      xlabel: "Time (years)"
      ylabel: "Methane"
      xmax:   40
      xmin:   0
      ymax:   600
      ymin:   0
      xTickCount: 4
      yTickCount: 5
      xFormatter: "3.3r"
      realTime: false
      fontScaleRelativeToParent: true

    @outputGraph = Lab.grapher.Graph '#output-graph', outputOptions

    # start the graph with four lines, each at 0,0
    @outputGraph.addSamples [0, 0, 0, 0]

    $(document).on FrackingModel.YEAR_ELAPSED, =>
      killed = [0,0,0,0]
      killed[3] = ABM.model.killed

      for well, i in ABM.model.wells
        killed[i] = well.killed
        well.killed = 0

      ABM.model.killed = 0
      @outputGraph.addSamples killed if killed[3] > 0

    if $('#contaminant-graph').length > 0
      contaminantOptions =
        title:  "Contaminants in the aquifer"
        xlabel: "Time (years)"
        ylabel: "Contaminants"
        xmax:   40
        xmin:   0
        ymax:   250
        ymin:   0
        xTickCount: 4
        yTickCount: 5
        xFormatter: "3.3r"
        realTime: false
        fontScaleRelativeToParent: true

      @contaiminantGraph = Lab.grapher.Graph '#contaminant-graph', contaminantOptions

      # start the graph with just methane in water
      @contaiminantGraph.addSamples [FrackingModel.baseMethaneInWater, 0]

      $(document).on FrackingModel.YEAR_ELAPSED, =>
        baseMethane   = ABM.model.baseMethaneInWater
        leakedMethane = ABM.model.leakedMethane
        pondWaste     = ABM.model.pondWaste

        ABM.model.leakedMethane *= 0.6
        ABM.model.pondWaste     *= 0.6

        @contaiminantGraph.addSamples [baseMethane+leakedMethane, pondWaste]



  startStopModel: ->
    @stopModel() unless @startModel()

  stopModel: ->
    if ABM.model.anim.stopped
      return false
    else
      ABM.model.stop()
      $(".icon-pause").hide()
      $(".icon-play").show()
      return true

  startModel: ->
    if ABM.model.anim.stopped
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

    @outputGraph.reset()
    @outputGraph.addSamples [0, 0, 0, 0]
    if @contaiminantGraph
      @contaiminantGraph.reset()
      @contaiminantGraph.addSamples [FrackingModel.baseMethaneInWater,0]

    setTimeout =>
      ABM.model.reset()
      @startModel()
    , 10

  offsetX: (evt, target)->
    return if evt.offsetX? then evt.offsetX else (evt.pageX - target.offset().left)

  offsetY: (evt, target)->
    return if evt.offsetY? then evt.offsetY else (evt.pageY - target.offset().top)

window.FrackingControls = FrackingControls
$(document).trigger 'fracking-controls-loaded'
