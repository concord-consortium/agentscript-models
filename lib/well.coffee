class Well
  @TAKEN_IDS: {}
  id: 0
  x: 0
  depth: 0
  tickOpened: 0
  killed: 0
  totalKilled: 0
  head: null
  patches: null
  walls: null

  drawContext: null

  # state management
  goneHorizontal: false
  toTheRight: null
  cappingInProgress: false
  capped: false

  # some event types
  @CREATED: "wellCreated"
  @CAPPED: 'capped'
  @YEAR_ELAPSED: "wellYearElapsed"

  @LOOKAHEAD_TYPES: []
  @WELL_HEAD_TYPES: []

  # some graphical images
  # NOTE: relative urls are relative to the model html location!
  @WELL_IMG: ABM.util.importImage ''

  # Returns min, available ID of a well.
  @getId: ->
    id = 1
    while Well.TAKEN_IDS[id]
      id++
    Well.TAKEN_IDS[id] = true
    id

  constructor: (@model, @x, @depth)->
    # set these here so all Well instances don't share the same arrays
    @id = Well.getId()
    @head = {x: 0, y: 0}
    @patches = []
    @walls = []

    @head.x = @x
    @head.y = @depth

    @drawContext = @_createDrawContext()

    @drawWell()
    @drawLabel()
    @model.draw()

    $(document).trigger @constructor.CREATED, @

  # overridden in GasWell
  drawWell: ->
    img = @constructor.WELL_IMG
    @drawUI img, @head.x, @head.y, 0.5, 0

  # extended in GasWell
  drawLabel: ->
    p = @model.patches.patchXY(@head.x, @head.y + 4)
    p.label = "" + @id
    @addPatch p
    @drawContext.labelColor = @getLabelColor @id
    p.drawLabel(@drawContext)

  # overridden in GasWell
  getLabelColor: (id) ->
    switch id
      when 1 then [0, 0, 255]
      when 2 then [255, 0, 102]
      when 3 then [0, 0, 0]
      when 4 then [204, 51, 255]
      when 5 then [255, 102, 0]
      else [255, 255, 255]

  length: ->
    Math.abs(@x - @head.x) + Math.abs(@depth - @head.y)

  age: ->
    age = Math.ceil(@tickAge() / @model.ticksPerYear)
    return if age is 0 then 1 else age

  ageFloat: ->
    @tickAge() / @model.ticksPerYear

  tickAge: ->
    @model.anim.ticks - @tickOpened

  # add a center patch to the well
  addPatch: (p)->
    p.well = @
    p.isWell = true
    p.color = [141, 141, 141]
    @patches.push p

  addWall: (p)->
    p.well = @
    p.isWell = true
    p.color = [87, 87, 87]
    @walls.push p

  drill: (drillDirection, drillSpeed)->
    return if @cappingInProgress or @capped

    if drillDirection is "down" and not @goneHorizontal
      # drill one deeper
      for i in [0...drillSpeed]
        @drillVertical()
    else if drillDirection isnt "down"
      if not @toTheRight?
        @toTheRight = (drillDirection is "right")

      if (drillDirection is "right" and @toTheRight) or (drillDirection is "left" and not @toTheRight)
        # drill horizontally
        for i in [0...drillSpeed]
          @drillHorizontal()

  drillVertical: ->
    y = @depth - 1
    return if y < (@model.patches.minY + 5)
    return if @goneHorizontal

    lookahead = @model.patches.patchXY(@x, y-5)
    return if lookahead? and (lookahead.isWell or ABM.util.contains(@constructor.LOOKAHEAD_TYPES, lookahead.type))

    #draw the well
    #for x in [(@x - 1)..(@x + 1)]
    pw = @model.patches.patchXY @x, y
    @addPatch pw

    # and the well walls
    for x in [(@x - 1), (@x + 1)]
      pw = @model.patches.patchXY x, y
      @addWall pw

    # Also expose the color of the 5 patches to either side
    for x in [(@x - 7)..(@x + 7)]
      @model.patchChanged @model.patches.patchXY x, y

    @depth = y

  drillHorizontal: ->
    if not @goneHorizontal
      pivotX = if @toTheRight then @x + 2 else @x - 2
      pivot = @model.patches.patchXY pivotX, @depth

      for x in [(@x - 7)..(@x + 7)]
        for y in [(@depth - 1)..(@depth - 8)]
          p = @model.patches.patchXY x, y
          if (@toTheRight and x <= pivot.x) or (not @toTheRight and x >= pivot.x)
            d = ABM.util.distance(pivot.x, pivot.y, p.x, p.y)
            if d > 2.25 and d < 3.25
              @addWall p
            else if d <= 2.25
              @addPatch p
          @model.patchChanged p
      @depth = @depth - 2
      @x = @x + (if @toTheRight then 2 else -2)

      @goneHorizontal = true
    else
      x = @x + (if @toTheRight then 1 else -1)
      return if x > (@model.patches.maxX - 1) or x < (@model.patches.minX + 1)

      lx = @x + (if @toTheRight then 5 else -5)
      lookahead = @model.patches.patchXY(lx, @depth)
      return if lookahead? and (lookahead.isWell or ABM.util.contains(@constructor.LOOKAHEAD_TYPES, lookahead.type))

      #draw the well
      #for y in [(@depth - 1)..(@depth + 1)]
      pw = @model.patches.patchXY x, @depth
      @addPatch pw

      # and the well walls
      for y in [(@depth - 1), (@depth + 1)]
        pw = @model.patches.patchXY x, y
        @addWall pw

      @x = x

  remove: ->
    for p in @patches.concat(@walls)
      p.isWell = null
      p.well = null
      @model.patchChanged p
    @patches = []
    @walls = []
    ABM.util.removeItem @model.wells, @
    @eraseUI()
    @model.redraw()
    @model.wellRemovedCallback?(@id)
    Well.TAKEN_IDS[@id] = false

  # a check to see if the well is still properly situated.
  # Basically, it just makes sure that the well head patch is on a valid type,
  # and that the patch immediately below the well head isn't one of those types
  isValid: ->
    head = @model.patches.patchXY @head.x, @head.y
    patchBelow = head.n4[0]
    return ABM.util.contains(@constructor.WELL_HEAD_TYPES, head.type) and not ABM.util.contains(@constructor.WELL_HEAD_TYPES, patchBelow.type)

  eraseUI: ->
    ctx = @drawContext
    ctx.save()
    ctx.globalCompositeOperation = "destination-out"
    ctx.translate @head.x, @head.y
    ctx.fillRect -7, -1, 14, 30
    ctx.restore()

  # draw image `img` at (x, y). Image will be drawn at 50% scale and  will be centered on the point
  # (xFraction, yFraction) within the image, where xFraction and yFraction are normalized to the
  # width and height of the image, and are relative to the bottom left of the image.
  drawUI: (img, x, y, xFraction = 0, yFraction = 0) ->
    ctx = @drawContext

    ctx.save()
    ctx.translate x, y
    # Agentscript's origin appears to be the _lower_ left corner, rather than upper left.
    ctx.scale 0.5, -0.5
    ctx.drawImage img, -xFraction * img.width, (yFraction - 1) * img.height
    ctx.restore()

  # returns the bounding box of the image, if drawn by passing the same parameters to @drawUI
  getDrawUIBBox: (img, x, y, xFraction = 0, yFraction = 0) ->
    x: x + 0.5 * -xFraction * img.width,
    y: y - 0.5 * yFraction * img.height,
    width: 0.5 * img.width,
    height: 0.5 * img.height

  _createDrawContext: ->
    return @model.contexts.wells if @model.contexts.wells?
    ctx = @model.addContext "wells", 5
    # mirror the drawing context's text and label settings
    ctx.font         = @model.contexts.drawing.font
    ctx.textAlign    = @model.contexts.drawing.textAlign
    ctx.textBaseline = @model.contexts.drawing.textBaseline
    ctx.labelXY      = @model.contexts.drawing.labelXY
    ctx

window.Well = Well
