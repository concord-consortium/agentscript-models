class Well
  id: 0
  x: 0
  depth: 0
  tickOpened: 0
  killed: 0
  totalKilled: 0
  head: null
  patches: null
  walls: null
  open: null
  openShale: null

  # state management
  goneHorizontal: false
  toTheRight: null
  cappingInProgress: false
  capped: false

  # some event types
  @CREATED: "wellCreated"
  @CAPPED: 'capped'
  @YEAR_ELAPSED: "wellYearElapsed"

  # some graphical images
  @WELL_IMG: ABM.util.importImage 'img/well-head.png'

  constructor: (@model, @x, @depth)->
    # set these here so all Well instances don't share the same arrays
    @id = @model.wells.length + 1
    @head = {x: 0, y: 0}
    @patches = []
    @walls = []

    @head.x = @x
    @head.y = @depth

    p = @model.patches.patchXY(@head.x, @head.y + 1)
    p.label = "" + @id
    @model.contexts.drawing.labelColor = switch @id
      when 1 then [200,0,0]
      when 2 then [50,255,20]
      when 3 then [0,0,255]
      else [255,255,255]
    p.drawLabel(@model.contexts.drawing)

    @drawUI @constructor.WELL_IMG, @head.x + 4, @head.y + 7

    @model.draw()

    $(document).trigger @constructor.CREATED, @

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
    p.type = "well"
    p.well = @
    @patches.push p

  addWall: (p)->
    p.type = "wellWall"
    p.well = @
    @walls.push p

  drawUI: (img, x, y)->
    ctx = @model.contexts.drawing
    ctx.save()
    ctx.translate x, y
    ctx.scale 0.5, 0.5
    ctx.rotate ABM.util.degToRad(180)
    ctx.drawImage img, 0, 0
    ctx.restore()

window.Well = Well