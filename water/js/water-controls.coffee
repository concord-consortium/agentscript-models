window.WaterControls =
  modelReady: false
  drawStyle: "draw"  # draw or fill
  patchType: "rock1"
  removeType: "layer"
  countOptions:
    x: 0
    y: 0
    dx: 50
    dy: 50
    debug: true
  graphOptions:
    xMin: 0
    xMax: 40
    yMin: 0
    yMax: 600
    initialValues: [0]
  setup: ->
    if ABM.model?
      $(".icon-pause").hide()
      $(".icon-play").show()
      if @modelReady
        $("#controls").show()
      else
        $("#controls").hide()
      # $("#draw-button").button()
      # .click =>
      #   $("#fill-button").click() if $("#fill-button")[0].checked
      #   if `this.checked`
      #     @drawStyle = "draw"
      #     @draw()
      #   else
      #     @stopDraw()
      $("#play-pause-button").button()
      .click =>
        @stopDraw(false)
        @startStopModel()
      $("#reset-button").button()
      .click =>
        @stopDraw()
        @resetModel()
      $("#playback").buttonset()
      $("#erase-button").button()
      .click =>
        @stopDraw()
        @erase()
      $("#fill-button").button()
      .click =>
        @stopDraw()
        if `this.checked`
          @drawStyle = "fill"
          @draw()
      $("#draw-button-type").button
        text: false
        icons:
          primary: "ui-icon-triangle-1-s"
      .click ->
        menu = $("#draw-button-type-options").show().position
          my: "left top"
          at: "left bottom"
          of: this
        $(document).one 'click', ->
          menu.hide()
        return false
      $("#draw-button-set").buttonset()
      $("#draw-button-type-options").hide().menu
        select: (evt, ui)=>
          layerOption = ui.item.find(".layer-option")
          $("label[for='fill-button'] .ui-button-text").html(layerOption.clone())
          @setDrawType layerOption.prop('className').split(/\s+/)
          # automatically put us into fill mode when we select a layer type
          $("#fill-button").click() unless $("#fill-button")[0].checked
      $("#remove-button").button()
      .click =>
        @stopDraw()
        if `this.checked`
          switch @removeType
            when "layer" then @erase()
            when "water" then @removeWater()
            when "well" then @removeWell()
            else console.log("Invalid remove type: " + @removeType)
      $("#remove-button-type").button
        text: false
        icons:
          primary: "ui-icon-triangle-1-s"
      .click ->
        menu = $("#remove-button-type-options").show().position
          my: "left top"
          at: "left bottom"
          of: this
        $(document).one 'click', ->
          menu.hide()
        return false
      $("#remove-button-set").buttonset()
      $("#remove-button-type-options").hide().menu
        select: (evt, ui)=>
          layerOption = ui.item.find(".remove-option")
          $("label[for='remove-button'] .ui-button-text").html(layerOption.clone())
          @setRemoveType layerOption.prop('className').split(/\s+/)
          # automatically put us into fill mode when we select a layer type
          @stopDraw()
          $("#remove-button").click()
      $('#follow-water-button').button(
        label: "Follow Water Droplet"
      ).click ->
        $span = $('#follow-water-button').find('span')
        if $span.text() is "Follow Water Droplet"
          ABM.model.addRainSpotlight()
          $span.text "Stop following"
        else
          ABM.model.removeSpotlight()
          $span.text "Follow Water Droplet"
      exportDataField = $("#exported-data")
      $("#export-button").button().click ->
        state = ImportExport.export(ABM.model)
        stateStr = JSON.stringify(state, null, 2)
        exportDataField.val(stateStr)
      $("#import-button").button().click ->
        if exportDataField.val()? and exportDataField.val().length > 0
          state = JSON.parse(exportDataField.val())
          ImportExport.import(ABM.model, state)
      $("#rain-slider").slider
        orientation: 'horizontal'
        min: 0
        max: 1
        step: 0.05
        value: 0.35
        slide: (evt, ui)->
          ABM.model.rainProbability = ui.value
        ABM.model.rainProbability = 0.35
      templateOptions = $('#template-options')
      templateOptions.change (evt)=>
        # FIXME There's got to be a better way to handle this
        switch templateOptions.val()
          when "state/WaterModel-Gaining-Losing-Stream-StreamA.json" then @graphOptions.initialValues = [28]
          when "state/WaterModel-Gaining-Losing-Stream-StreamB.json" then @graphOptions.initialValues = [5333]
        ABM.model.setTemplate templateOptions.val()
        @resetModel(false)
      irrigationWellButton = $("#irrigation-well-button")
      irrigationWellButton.button().click =>
        @stopDraw()
        if irrigationWellButton[0]?.checked
          @drill('irrigation')
      removalWellButton = $("#removal-well-button")
      removalWellButton.button().click =>
        @stopDraw()
        if removalWellButton[0]?.checked
          @drill('removal')
      removeWellButton = $("#remove-well")
      removeWellButton.button().click =>
        @stopDraw()
        if removeWellButton[0]?.checked
          @removeWell()
      addWaterButton = $("#water-button")
      addWaterButton.button().click =>
        @stopDraw()
        if addWaterButton[0]?.checked
          @addWater()
      removeWaterButton = $("#remove-water-button")
      removeWaterButton.button().click =>
        @stopDraw()
        if removeWaterButton[0]?.checked
          @removeWater()

      if $('#output-graph').length > 0
        @setupGraph()

    else
      console.log("delaying...")
      setTimeout =>
        @setup()
      , 500

  outputGraph: null
  center: null
  setupGraph: ->
    outputOptions =
      title:  "Water Level"
      xlabel: "Time (years)"
      ylabel: "Water Level"
      xmax:   @graphOptions.xMax
      xmin:   @graphOptions.xMin
      ymax:   @graphOptions.yMax
      ymin:   @graphOptions.yMin
      xTickCount: 4
      yTickCount: 5
      xFormatter: "3.3r"
      realTime: false
      fontScaleRelativeToParent: true
      sampleInterval: 1/12

    @outputGraph = Lab.grapher.Graph '#output-graph', outputOptions

    # start the graph with one line at 0,0
    @outputGraph.addSamples @graphOptions.initialValues

    @center = ABM.model.patches.patchXY @countOptions.x, @countOptions.y

    $(document).on WaterModel.MONTH_ELAPSED, =>
      count = ABM.model.rainCount @center, @countOptions.dx, @countOptions.dy, true, @countOptions.debug

      @outputGraph.addSamples [count]


  setDrawType: (colors = [])->
    if $.inArray("rock1", colors) > -1
      @patchType = "rock1"
    else if $.inArray("rock2", colors) > -1
      @patchType = "rock2"
    else if $.inArray("rock3", colors) > -1
      @patchType = "rock3"
    else if $.inArray("rock4", colors) > -1
      @patchType = "rock4"
    else if $.inArray("soil", colors) > -1
      @patchType = "soil"
    else
      console.log "Invalid layer option!", colors

  setRemoveType: (types = [])->
    if $.inArray("layer", types) > -1
      @removeType = "layer"
    else if $.inArray("water", types) > -1
      @removeType = "water"
    else if $.inArray("well", types) > -1
      @removeType = "well"
    else
      console.log "Invalid remove option!", types

  startType: null
  fillBelow: (x,y,points)->
    # also include all the points below this one, up to the first patch that is not the same type as the current patch
    @startType ||= ABM.model.patches.patchXY(x, y)?.type
    done = false
    for dy in [(y)..(ABM.model.patches.minY)]
      continue if done
      p = ABM.model.patches.patchXY x, dy
      if p.type is @startType
        points.push {x: x, y: dy}
      else
        done = true

  draw: ->
    target = $("#mouse-catcher")
    mouseDown = false
    cStart = null
    drawEvt = (evt)=>
      if evt? and evt.preventDefault?
        evt.preventDefault()
      else
        window.event.returnValue = false
      return false unless mouseDown
      cEnd = ABM.model.patches.patchAtPixel @offsetX(evt, target), @offsetY(evt, target)
      points = []
      if cStart? and (cStart.x != cEnd.x or cStart.y != cEnd.y)
        # Paint all the patches in a line between this and the last patch red
        if cEnd.x != cStart.x
          m = (cEnd.y - cStart.y)/(cEnd.x - cStart.x)
        else
          m = 100000000 # something large enough that it will always round down
        for x in [(cStart.x)..(cEnd.x)]
          continue if x > ABM.model.patches.maxX or x < ABM.model.patches.minX
          pt = {x: x}
          pt.y = Math.round(m * (x - cEnd.x) + cEnd.y)  # point-slope form, solve for y
          continue if pt.y > ABM.model.patches.maxY or pt.y < ABM.model.patches.minY
          if @drawStyle is "fill"
            @fillBelow pt.x, pt.y, points
          else
            points.push pt
        if @drawStyle is "draw" and m != 0
          for y in [(cStart.y)..(cEnd.y)]
            continue if y > ABM.model.patches.maxY or y < ABM.model.patches.minY
            pt = {y: y}
            pt.x = Math.round((y - cEnd.y)/m + cEnd.x)  # point-slope form, solve for x
            continue if pt.x > ABM.model.patches.maxX or pt.x < ABM.model.patches.minX
            points.push pt
      else
        if @drawStyle is "fill"
          @fillBelow cEnd.x, cEnd.y, points
        else
          points.push cEnd
      wellsToRevalidate = []
      for c in points
        p = ABM.model.patches.patchXY c.x, c.y
        if p?
          p.type = @patchType
          if p.isWell
            wellsToRevalidate.push p.well
          ABM.model.patchChanged p # handles resetting the patch color
        else
          console.log("Failed to find patch for: (" + c.x + ", " + c.y + ")")
      @revalidateWells wellsToRevalidate
      ABM.model.refreshPatches = true
      ABM.model.draw()
      ABM.model.refreshPatches = false
      cStart = cEnd
      return false
    target.show()
    target.css('cursor', 'url("img/cursor_add.cur")')
    target.bind 'mousedown', (evt)->
      mouseDown = true
      drawEvt(evt)
    target.bind 'mouseup', =>
      mouseDown = false
      cStart = null
      @startType = null
    target.bind 'mouseleave', (evt)=>
      drawEvt(evt)
      mouseDown = false
      cStart = null
      @startType = null
    target.bind 'mousemove', drawEvt

  erase: ->
    target = $("#mouse-catcher")
    target.show()
    target.css('cursor', 'url("img/cursor_remove.cur")')
    target.bind 'mousedown', (evt)=>
      # get the patch under the cursor,
      # find all the contiguous patches of the same type,
      # set them to the type of the first non-similar patch above them
      originalPatch = ABM.model.patches.patchAtPixel @offsetX(evt, target), @offsetY(evt, target)
      return unless originalPatch?
      originalPatchType = originalPatch.type
      return if originalPatchType is "sky"
      patches = [originalPatch]
      wellsToRevalidate = []
      fillTypes = {}
      findFillType = (p)->
        x = p.x
        return fillTypes[x] if fillTypes[x]
        for y in [(p.y)..(ABM.model.patches.maxY)]
          nextP = ABM.model.patches.patchXY(x,y)
          if nextP? and p.type isnt nextP.type
            fillTypes[x] = nextP.type
            return fillTypes[x]
        fillTypes[x] = "sky"
        return fillTypes[x]
      while patches.length > 0
        patch = patches.shift()
        continue if patch.type isnt originalPatchType
        fType = findFillType(patch)
        patch.type = fType
        if patch.isWell
          # add it to the list to revalidate
          wellsToRevalidate.push patch.well if wellsToRevalidate.indexOf(patch.well) == -1
        ABM.model.patchChanged patch # handles resetting the patch color
        for n in patch.n4
          if n? and n.type is originalPatchType
            patches.push n
      @revalidateWells wellsToRevalidate
      ABM.model.refreshPatches = true
      ABM.model.draw()
      ABM.model.refreshPatches = false

  stopDraw: (alsoStopModel=true)->
    $("#fill-button").click() if $("#fill-button")[0]?.checked
    $("#remove-button").click() if $("#remove-button")[0]?.checked
    $("#erase-button").click() if $("#erase-button")[0]?.checked
    $("#irrigation-well-button").click() if $("#irrigation-well-button")[0]?.checked
    $("#removal-well-button").click() if $("#removal-well-button")[0]?.checked
    $("#water-button").click() if $("#water-button")[0]?.checked
    @startStopModel() if alsoStopModel and not ABM.model.anim.animStop
    $("#mouse-catcher").hide()
    $("#mouse-catcher").css('cursor', '')
    $("#mouse-catcher").unbind('mouseup')
    $("#mouse-catcher").unbind('mousedown')
    $("#mouse-catcher").unbind('mousemove')
    $("#mouse-catcher").unbind('mouseleave')
    clearInterval @timerId if @timerId?
    @timerId = null

  revalidateWells: (wellsToRevalidate)->
    for well in wellsToRevalidate
      well.remove() unless well.isValid()

  timerId: null
  drill: (type='irrigation')->
    target = $("#mouse-catcher")
    target.show()
    target.css('cursor', 'url("img/cursor_addwell' + type + '.cur")')
    target.bind 'mousedown', (evt)=>
      return if @timerId?
      ABM.model.newWellType = switch type
        when "irrigation" then IrrigationWell
        else WaterRemovalWell
      @timerId = setInterval =>
        p = ABM.model.patches.patchAtPixel(@offsetX(evt, target), @offsetY(evt, target))
        ABM.model.drill p
      , 100
    .bind 'mouseup mouseleave', =>
      clearInterval @timerId if @timerId?
      @timerId = null

  removeWell: ->
    target = $("#mouse-catcher")
    target.show()
    target.css('cursor', 'url("img/cursor_removewell.cur")')
    target.bind 'mousedown', (evt)=>
      # get the patch under the cursor,
      # check if there's a nearby well. If so, remove it.
      originalPatch = ABM.model.patches.patchAtPixel @offsetX(evt, target), @offsetY(evt, target)
      return unless originalPatch?
      well = ABM.model.findNearbyWell originalPatch
      well.remove() if well?

  addWater: ->
    target = $("#mouse-catcher")
    lastWaterEvt = null
    mouseDown = false
    target.show()
    target.css('cursor', 'url("img/cursor_addwater.cur")')
    target.bind 'mousedown', (evt)=>
      return if @timerId?
      lastWaterEvt = evt
      mouseDown = true
      @_placeWater(evt, target)
      @timerId = setInterval =>
        @_placeWater(lastWaterEvt, target)
      , 10
    .bind 'mousemove', (evt)=>
      lastWaterEvt = evt if mouseDown
      if evt? and evt.preventDefault?
        evt.preventDefault()
      else
        window.event.returnValue = false
      return false
    .bind 'mouseup mouseleave', =>
      mouseDown = false
      clearInterval @timerId if @timerId?
      @timerId = null

  removeWater: ->
    target = $("#mouse-catcher")
    lastWaterEvt = null
    mouseDown = false
    target.show()
    target.css('cursor', 'url("img/cursor_removewater.cur")')
    target.bind 'mousedown', (evt)=>
      return if @timerId?
      lastWaterEvt = evt
      mouseDown = true
      @_removeWater(evt, target)
      @timerId = setInterval =>
        @_removeWater(lastWaterEvt, target)
      , 10
    .bind 'mousemove', (evt)=>
      lastWaterEvt = evt if mouseDown
      if evt? and evt.preventDefault?
        evt.preventDefault()
      else
        window.event.returnValue = false
      return false
    .bind 'mouseup mouseleave', =>
      mouseDown = false
      clearInterval @timerId if @timerId?
      @timerId = null

  _placeWater: (evt, target)->
    p = ABM.model.patches.patchAtPixel(@offsetX(evt, target), @offsetY(evt, target))
    rect = ABM.model.patches.patchRect p, 5, 5, true
    for pa in ABM.util.shuffle(rect)
      if pa? and pa.agentsHere().length == 0
        ABM.model.rain.create 1, (drop)->
          drop.moveTo pa
          ABM.model.draw()
        break

  _removeWater: (evt, target)->
    p = ABM.model.patches.patchAtPixel(@offsetX(evt, target), @offsetY(evt, target))
    rect = ABM.model.patches.patchRect p, 5, 5, true
    for pa in ABM.util.shuffle(rect)
      if pa? and (agents = pa.agentsHere()).length != 0
        for a in agents
          if a.breed is ABM.model.rain
            a.die()
        ABM.model.draw()
        break

  startStopModel: ->
    if ABM.model.anim.animStop
      ABM.model.start()
      $(".icon-pause").show()
      $(".icon-play").hide()
    else
      ABM.model.stop()
      $(".icon-pause").hide()
      $(".icon-play").show()

  resetModel: (passToModel=true)->
    ABM.model.reset() if passToModel
    $(".icon-pause").hide()
    $(".icon-play").show()

    @outputGraph.reset()
    @outputGraph.addSamples @graphOptions.initialValues

  offsetX: (evt, target)->
    return if evt.offsetX? then evt.offsetX else (evt.pageX - target.offset().left)

  offsetY: (evt, target)->
    return if evt.offsetY? then evt.offsetY else (evt.pageY - target.offset().top)

$(document).one 'model-ready', ->
  WaterControls.modelReady = true
  $("#controls").show()
$(document).trigger('controls-ready')