window.WaterControls =
  drawStyle: "draw"  # draw or fill
  drawColor: [255,0,0]
  patchType: "rock1"
  setup: ->
    if ABM.model?
      $("#controls").show()
      $("#draw-button").button()
      .click =>
        $("#fill-button").click() if $("#fill-button")[0].checked
        if `this.checked`
          @drawStyle = "draw"
          @draw()
        else
          @stopDraw()
      $("#fill-button").button()
      .click =>
        $("#draw-button").click() if $("#draw-button")[0].checked
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
          @setDrawColor ui.item.text()
    else
      console.log("delaying...")
      setTimeout =>
        @setup()
      , 500

  setDrawColor: (colorStr)->
    if colorStr is "Red"
      @drawColor = [255,0,0]
      @patchType = "rock1"
    else if colorStr is "Violet"
      @drawColor = [117,117,176]
      @patchType = "rock2"
    else if colorStr is "Green"
      @drawColor = [0,255,0]
      @patchType = "rock3"
    else if colorStr is "Black"
      @drawColor = [0,0,0]
      @patchType = "rock4"
    else if colorStr is "Yellow"
      @drawColor = [255,255,0]
      @patchType = "soil"

  draw: ->
    mouseDown = false
    cStart = null
    drawEvt = (evt)=>
      return unless mouseDown
      cEnd = @patchCoords evt.offsetX, evt.offsetY
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
          points.push pt
          if @drawStyle is "fill"
            # also include all the points below this one
            for y in [(pt.y)..(ABM.model.patches.minY)]
              points.push {x: pt.x, y: y}
        if @drawStyle is "draw" and m != 0
          for y in [(cStart.y)..(cEnd.y)]
            continue if y > ABM.model.patches.maxY or y < ABM.model.patches.minY
            pt = {y: y}
            pt.x = Math.round((y - cEnd.y)/m + cEnd.x)  # point-slope form, solve for x
            continue if pt.x > ABM.model.patches.maxX or pt.x < ABM.model.patches.minX
            points.push pt
      else
        if @drawStyle is "fill"
          # also include all the points below this one
          for y in [(cEnd.y)..(ABM.model.patches.minY)]
            points.push {x: cEnd.x, y: y}
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
    $("#mouse-catcher").show()
    $("#mouse-catcher").bind 'mousedown', (evt)->
      mouseDown = true
      drawEvt(evt)
    $("#mouse-catcher").bind 'mouseup', ->
      mouseDown = false
      cStart = null
    $("#mouse-catcher").bind 'mouseleave', (evt)->
      drawEvt(evt)
      mouseDown = false
      cStart = null
    $("#mouse-catcher").bind 'mousemove', drawEvt

  stopDraw: ->
    $("#mouse-catcher").hide()
    $("#mouse-catcher").unbind('mousedown')
    $("#mouse-catcher").unbind('mousemove')
    $("#mouse-catcher").unbind('mouseup')


  patchCoords: (x,y)->
    patches = ABM.model.patches
    minX = patches.minX
    maxY = patches.maxY
    size = patches.size

    pX = Math.floor(x/size) + minX
    pY = maxY - Math.floor(y/size)
    return {x: pX, y: pY}

$(document).trigger('controls-ready')