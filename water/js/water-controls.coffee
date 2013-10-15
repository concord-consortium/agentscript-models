window.WaterControls =
  drawStyle: "draw"  # draw or fill
  drawColor: [255,0,0]
  patchType: "rock1"
  setup: ->
    if ABM.model?
      $(".icon-pause").hide()
      $(".icon-play").show()
      $("#controls").show()
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
        else
          @stopDraw()
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
          window.drawColor = ui.item
          layerOption = ui.item.find(".layer-option")
          $("label[for='fill-button'] .ui-button-text").html(layerOption.clone())
          @setDrawColor layerOption.prop('className').split(/\s+/)
          # automatically put us into fill mode when we select a layer type
          @stopDraw() and $("#fill-button").click() unless $("#fill-button")[0].checked
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
      importButton = $("#import-button")
      exportButton = $("#export-button")
      exportDataField = $("#exported-data")
      if importButton? and exportButton? and exportDataField?
        exportButton.button().click ->
          state = ImportExport.export(ABM.model)
          stateStr = JSON.stringify(state, null, 2)
          exportDataField.val(stateStr)
        importButton.button().click ->
          if exportDataField.val()? and exportDataField.val().length > 0
            state = JSON.parse(exportDataField.val())
            ImportExport.import(ABM.model, state)
      rainSlider = $("#rain-slider")
      if rainSlider?
        rainSlider.slider
          orientation: 'horizontal'
          min: 0
          max: 1
          step: 0.05
          value: 0.35
          slide: (evt, ui)->
            ABM.model.rainProbability = ui.value
        ABM.model.rainProbability = 0.35
      templateOptions = $('#template-options')
      if templateOptions?
        templateOptions.change (evt)->
          ABM.model.setTemplate templateOptions.val()
    else
      console.log("delaying...")
      setTimeout =>
        @setup()
      , 500

  setDrawColor: (colors = [])->
    if $.inArray("rock1", colors) > -1
      @drawColor = [255,0,0]
      @patchType = "rock1"
    else if $.inArray("rock2", colors) > -1
      @drawColor = [117,117,176]
      @patchType = "rock2"
    else if $.inArray("rock3", colors) > -1
      @drawColor = [0,255,0]
      @patchType = "rock3"
    else if $.inArray("rock4", colors) > -1
      @drawColor = [0,0,0]
      @patchType = "rock4"
    else if $.inArray("soil", colors) > -1
      @drawColor = [255,255,0]
      @patchType = "soil"
    else
      console.log "Invalid layer option!", colors

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
      return unless mouseDown
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
      for c in points
        p = ABM.model.patches.patchXY c.x, c.y
        if p?
          p.color = @drawColor
          p.type = @patchType
        else
          console.log("Failed to find patch for: (" + c.x + ", " + c.y + ")")
      ABM.model.refreshPatches = true
      ABM.model.draw()
      ABM.model.refreshPatches = false
      cStart = cEnd
    target.show()
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
    target.bind 'mousedown', (evt)=>
      # get the patch under the cursor,
      # find all the contiguous patches of the same type,
      # set them to the type of the first non-similar patch above them
      originalPatch = ABM.model.patches.patchAtPixel @offsetX(evt, target), @offsetY(evt, target)
      return unless originalPatch?
      originalPatchType = originalPatch.type
      return if originalPatchType is "sky"
      patches = [originalPatch]
      fillTypes = {}
      findFillType = (p)->
        x = p.x
        return fillTypes[x] if fillTypes[x]
        for y in [(p.y)..(ABM.model.patches.maxY)]
          nextP = ABM.model.patches.patchXY(x,y)
          if nextP? and p.type isnt nextP.type
            fillTypes[x] = {type: nextP.type, color: nextP.color}
            return fillTypes[x]
        fillTypes[x] = {type: "sky", color: [205, 237, 252]}
        return fillTypes[x]
      while patches.length > 0
        patch = patches.shift()
        continue if patch.type isnt originalPatchType
        fType = findFillType(patch)
        patch.type = fType.type
        patch.color = fType.color
        for n in patch.n4
          if n? and n.type is originalPatchType
            patches.push n
      ABM.model.refreshPatches = true
      ABM.model.draw()
      ABM.model.refreshPatches = false

  stopDraw: (alsoStopModel=true)->
    $("#fill-button").click() if $("#fill-button")[0]?.checked
    $("#erase-button").click() if $("#erase-button")[0]?.checked
    @startStopModel() if alsoStopModel and not ABM.model.anim.stopped
    $("#mouse-catcher").hide()
    $("#mouse-catcher").unbind('mouseup')
    $("#mouse-catcher").unbind('mousedown')
    $("#mouse-catcher").unbind('mousemove')
    $("#mouse-catcher").unbind('mouseleave')

  startStopModel: ->
    if ABM.model.anim.stopped
      ABM.model.start()
      $(".icon-pause").show()
      $(".icon-play").hide()
    else
      ABM.model.stop()
      $(".icon-pause").hide()
      $(".icon-play").show()

  resetModel: ->
    ABM.model.reset()
    $(".icon-pause").hide()
    $(".icon-play").show()

  offsetX: (evt, target)->
    return if evt.offsetX? then evt.offsetX else (evt.pageX - target.offset().left)

  offsetY: (evt, target)->
    return if evt.offsetY? then evt.offsetY else (evt.pageY - target.offset().top)

$(document).trigger('controls-ready')