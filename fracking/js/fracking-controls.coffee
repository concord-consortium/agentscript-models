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
    $(document).on GasWell.CAN_EXPLODE, =>
      @updateControls()
    $(document).on GasWell.EXPLODED, =>
      @updateControls()
    $(document).on GasWell.FILLED, =>
      @updateControls()
    $(document).on GasWell.FRACKED, =>
      @updateControls()
    $(document).on GasWell.CAPPED, =>
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
          scaleY = @getCanvasScaleY()
          depthBelowViewport = ($("#model").height() - ($("#model-viewport").scrollTop() + $("#model-viewport").height())) * scaleY - (well.depth * 2)
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
    # add a link that, when clicked, pops up a non-modal, draggable canvas element
    # that shows labeled lines for the different sample types used by the specified graph.
    appendKeyToGraph = (graphId, top, labelInfo) ->
      $graph = $ "##{graphId}"
      $graph.append '<a href="#" class="show-key">show key</a>'
      $graph.find('.show-key').click ->
        unless $("##{graphId}-key").length > 0
          $key = $("<div id=\"#{graphId}-key\" class=\"key\"><a class=\"icon-remove-sign icon-large\"></a><canvas></canvas></div>").appendTo($(document.body)).draggable()
          canvas = $key.find('canvas')[0]
          $key.height 18 * (labelInfo.length + 1)
          canvas.height = $key.outerHeight()
          canvas.width = $key.outerWidth()
          drawKey $key.find('canvas')[0], labelInfo

        $key = $ "##{graphId}-key"
        $key.css
          left: '450px',
          top: "#{top}px"
        .show()
        .on 'click', 'a', ->
          $(this).parent().hide()

    # Called by appendKeyToGraph to draw the actual lines
    drawKey = (canvas, labelInfo) ->
      # center the lines verticaly
      y = 0.5 * (canvas.height - 20 * (labelInfo.length - 1))
      ctx = canvas.getContext '2d'
      ctx.fillStyle = 'black'
      ctx.font = '12px "Helvetica Neue", Helvetica, sans-serif'
      ctx.lineWidth = 2
      for label in labelInfo
        ctx.strokeStyle = "rgb(#{label.color.join(',')})"
        ctx.beginPath()
        ctx.moveTo 10, y
        ctx.lineTo 60, y
        ctx.stroke()
        ctx.fillText label.label, 70, y + 3
        y += 20

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
      dataColors: [
        GasWell.labelColors[0],
        GasWell.labelColors[1],
        GasWell.labelColors[2],
        [  0,   0,   0],
        [255, 127,   0],
        [255,   0, 255]]

    if $('#output-graph').length > 0
      @outputGraph = LabGrapher '#output-graph', outputOptions

      labelInfo = ({ color: GasWell.labelColors[i], label: "Well #{i+1} Output"} for i in [0...3]).concat([{ color: [0, 0, 0], label: "Combined Output" }])
      appendKeyToGraph 'output-graph', 50, labelInfo

      # start the graph with four lines, each at 0,0
      @outputGraph.addSamples [0, 0, 0, 0]

      $(document).on FrackingModel.YEAR_ELAPSED, =>
        killed = [0,0,0,0]
        killed[3] = ABM.model.killed

        for well, i in ABM.model.wells
          killed[i] = well.killed
          well.killed = 0

        ABM.model.killed = 0
        @outputGraph?.addSamples killed if killed[3] > 0

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
        dataColors: [
          [160,   0,   0],
          [ 44, 160,   0],
          [ 44,   0, 160],
          [  0,   0,   0],
          [255, 127,   0],
          [255,   0, 255]]

      @contaminantGraph = LabGrapher '#contaminant-graph', contaminantOptions
      appendKeyToGraph 'contaminant-graph', 260, [
        { color: [160,   0,   0], label: "Leaked Methane", }
        { color: [ 44, 160,   0], label: "Pond Waste" }
      ]

      # start the graph with just methane in water
      @contaminantGraph.addSamples [FrackingModel.baseMethaneInWater, 0]

      $(document).on FrackingModel.YEAR_ELAPSED, =>
        baseMethane   = ABM.model.baseMethaneInWater
        leakedMethane = ABM.model.leakedMethane
        pondWaste     = ABM.model.pondWaste

        ABM.model.leakedMethane *= 0.6
        ABM.model.pondWaste     *= 0.6

        @contaminantGraph.addSamples [baseMethane+leakedMethane, pondWaste]

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

    @outputGraph?.reset()
    @outputGraph?.addSamples [0, 0, 0, 0]
    if @contaminantGraph
      @contaminantGraph.reset()
      @contaminantGraph.addSamples [FrackingModel.baseMethaneInWater,0]

    setTimeout =>
      ABM.model.reset()
      @startModel()
    , 10

  getCanvasScaleX: ->
    $canvas = $("#layers canvas")
    $canvas.attr("width") / $canvas.width()

  getCanvasScaleY: ->
    $canvas = $("#layers canvas")
    $canvas.attr("height") / $canvas.height()

  offsetX: (evt, target)->
    scale = @getCanvasScaleX()
    val = if evt.offsetX? then evt.offsetX else (evt.pageX - target.offset().left)
    val * scale

  offsetY: (evt, target)->
    scale = @getCanvasScaleY()
    val = if evt.offsetY? then evt.offsetY else (evt.pageY - target.offset().top)
    val * scale

window.FrackingControls = FrackingControls
$(document).trigger 'fracking-controls-loaded'
