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
  filling: null
  exploding: null
  fracking: null
  pumping: null
  pond: null

  leaks: false
  pondLeaks: false

  # state management
  goneHorizontal: false
  toTheRight: null
  explodingInProgress: false
  exploded: false
  fillingInProgress: false
  filled: false
  frackingInProgress: false
  fracked: false
  cappingInProgress: false
  capped: false

  # fill types
  @PROPANE: 'Propane'
  @WATER:   'Water'

  # some event types
  @CREATED: "wellCreated"
  @CAN_EXPLODE: "canExplode"
  @EXPLODED: 'exploded'
  @FILLED: 'filled'
  @FRACKED: 'fracked'
  @CAPPED: 'capped'
  @YEAR_ELAPSED: "wellYearElapsed"

  # some graphical images
  @WELL_IMG: ABM.util.importImage 'img/well-head.png'
  @POND_IMG: ABM.util.importImage 'img/well-pond.png'

  constructor: (@model, @x, @depth, @leaks=false, @pondLeaks=false)->
    # set these here so all Well instances don't share the same arrays
    @id = @model.wells.length + 1
    @head = {x: 0, y: 0}
    @patches = []
    @walls = []
    @open = []
    @openShale = []
    @filling = []
    @exploding = []
    @fracking = []
    @pumping = []
    @pond = []

    @head.x = @x
    @head.y = @depth

    p = @model.patches.patchXY(@head.x, @head.y + 1)
    p.label = "" + @id
    console.log "*" if @leaks
    console.log "+" if @pondLeaks
    @model.contexts.drawing.labelColor = switch @id
      when 1 then [200,0,0]
      when 2 then [50,255,20]
      when 3 then [0,0,255]
      else [255,255,255]
    p.drawLabel(@model.contexts.drawing)

    @drawUI Well.WELL_IMG, @head.x + 4, @head.y + 7

    @model.draw()

    $(document).trigger Well.CREATED, @

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

  addOpen: (p)->
    @open.push p
    p.well = @

  addExploding: (p)->
    @openShale.push p if p.type is "shale"
    p.type = "exploding"
    p.well = @
    @model.setPatchColor p
    @exploding.push p

  processSet: (set, done, n4processor = null, pProcessor = null)->
    for p in set
      pProcessor(p) if pProcessor?
      if n4processor?
        for pn in p.n4
          if pn?
            n4processor(pn)
    @model.redraw()
    done()

  explode: ->
    return unless @goneHorizontal
    if @exploding.length <= 0
      @exploded = true if @explodingInProgress
      @explodingInProgress = false
      $(document).trigger Well.EXPLODED
      return
    @explodingInProgress = true
    currentExploding = ABM.util.clone @exploding
    @exploding = []
    setTimeout =>
      @processSet currentExploding, =>
        @explode()
      , (p)=>
        switch p.type
          when "shale"
            if ABM.util.randomInt(100) < @model.shaleFractibility
              @addExploding p
          when "rock"
            if ABM.util.randomInt(100) < @model.rockFractibility
              @addExploding p
      , (p)=>
        p.type = "open"
        @addOpen p
        @model.setPatchColor p
    , 50

  fill: ->
    if @filling.length <= 0
      @filled = true if @fillingInProgress
      @fillingInProgress = false
      $(document).trigger Well.FILLED
      setTimeout =>
        @cycleWaterColors()
      , 500
      return
    currentFilling = ABM.util.clone @filling
    @filling = []
    setTimeout =>
      @processSet currentFilling, =>
        @fill()
      , (p)=>
        switch p.type
          when "open"
            if p.well? and p.well is @
              p.type = "clean" + @fillType + "Open"
              @model.setPatchColor p
              @filling.push p
    , 50

  floodWater: ->
    @fillType = Well.WATER
    @flood()

  floodPropane: ->
    @fillType = Well.PROPANE
    @flood()

  flood: ->
    return if @capped or @filled or @fracked or not @exploded
    for p in @patches
      p.type = "clean" + @fillType + "Well"
      @model.setPatchColor p

    @createWastePond() if @fillType is Well.WATER

    @fillingInProgress = true
    @model.redraw()

    @filling = ABM.util.clone @walls
    @fill()

  frack: ->
    return unless @filled
    if @fracking.length <= 0
      @fracked = true if @frackingInProgress
      @frackingInProgress = false
      $(document).trigger Well.FRACKED
      return
    @frackingInProgress = true
    currentFracking = ABM.util.clone @fracking
    @fracking = []
    fractibilityModifier = switch @fillType
      when Well.WATER then 1.05
      when Well.PROPANE then 1.1
      else 1
    setTimeout =>
      @processSet currentFracking, =>
        @frack()
      , (p)=>
          switch p.type
            when "shale"
              if ABM.util.randomInt(100) < (@model.shaleFractibility * fractibilityModifier)
                @fracking.push p
                p.type = "dirty" + @fillType + "Open"
                @addOpen p
                @model.setPatchColor p
    , 50

  pumpOut: ->
    return unless @filled and @fracked
    # start with all of the "open" patches
    opens = ABM.util.clone @open
    opens.sort (a,b)=>
      Math.abs(b.y - @depth) - Math.abs(a.y - @depth)

    # then add all of the well interior patches, sorted by their distance
    # to the well head.
    interiors = ABM.util.clone @patches
    interiors.sort (a,b)=>
      ABM.util.distance(b.x,b.y,@head.x,@head.y) - ABM.util.distance(a.x,a.y,@head.x,@head.y)

    @pumping = opens.concat interiors
    @cappingInProgress = true

    if @pond.length > 0 and (rounds = Math.ceil(@pumping.length / 100)) < 13
      eIdx = (14-rounds)*21
      for p in @pond.slice(0,eIdx)
        p.type = "dirtyWaterPond"
        @model.setPatchColor p

    @empty()

  empty: ->
    if @pumping.length <= 0
      @filled = false
      @capped = true if @cappingInProgress
      @cappingInProgress = false
      $(document).trigger Well.CAPPED
      @tickOpened = @model.anim.ticks
      return
    currentPumping = @pumping.slice(0,100)
    @pumping = @pumping.slice(100)

    pondFilling = []
    if @pond.length > 0 and (roundsLeft = Math.ceil(@pumping.length / 100)) <= 13
      sIdx = (13-roundsLeft)*21
      pondFilling = @pond.slice(sIdx, sIdx+21)

    setTimeout =>
      @processSet currentPumping, =>
        @empty()
      , null, (p)=>
        p.type = if p.type.match(/.*Well$/) then "well" else "open"
        @model.setPatchColor p

      if pondFilling.length > 0
        for p in pondFilling
          p.type = "dirtyWaterPond"
          @model.setPatchColor p
    , 50

  cycleWaterColors: ->
    if @fillType is Well.WATER
      colors = [
        [ 67, 160, 160],
        [ 64, 152, 152],
        [ 61, 144, 144],
        [ 57, 137, 137],
        [ 64, 129, 129],
        [ 51, 121, 121],
        [ 48, 113, 113],
        [ 45, 105, 105],
        [ 41,  98,  98],
        [ 38,  90,  90]
      ]
    else
      colors = [[122, 192, 99]]
    @nextColor(colors)

  nextColor: (colors)->
    if colors.length <= 0
      setTimeout =>
        for p in @patches
          p.type = "dirty" + @fillType + "Well"

        @fracking = ABM.util.clone @open
        @frack()
      , 250
      return
    c = colors.shift()
    setTimeout =>
      for p in @patches
        p.color = c
        @model.toRedraw.push p

      for p in @open
        p.color = c
        @model.toRedraw.push p

      @model.redraw()
      @nextColor(colors)
    , 100

  spawnNewGas: ->
    return unless @capped
    return unless @openShale.length > 0
    # spawn new gas at a rate dependent on the age of the well
    # this ensures we get a nice reduction curve over time
    numToSpawn = 0
    age = @ageFloat()
    return if age is 0
    wellSize = @openShale.length * 1.5
    numToSpawn = wellSize/((age+1)*150) + 0.5
    if (deci = numToSpawn % 1) > 0
      numToSpawn = (if ABM.util.randomFloat(1) < deci then Math.ceil(numToSpawn) else Math.floor(numToSpawn))
    if numToSpawn > 0
      @model.gas.create numToSpawn, (g)=>
        g.moveTo ABM.util.oneOf @openShale
        g.well = @
        g.trapped = false
        g.heading = ABM.util.degToRad(180)
        g.moveable = false
        g.hidden = false

  createWastePond: ->
    @drawUI Well.POND_IMG, @head.x + 17, @head.y

    for y in [(@head.y-7)...(@head.y)]
      for x in [(@head.x+6)...(@head.x+16)]
        p = @model.patches.patchXY x, y
        if p?
          @pond.push p
          p.type = "air"
          @model.setPatchColor p

  leakWastePondWater: ->
    if @pondLeaks and @capped and @pond.length > 0 and ABM.util.randomInt(50) is 0
      @model.pondWaste += @model.pondWasteScale
      @model.pondWater.create 1, (a)=>
        a.well = @
        a.moveTo @model.patches.patchXY(@head.x + ABM.util.randomInt(12) + 6, @head.y - 8)

  drawUI: (img, x, y)->
    ctx = @model.contexts.drawing
    ctx.save()
    ctx.translate x, y
    ctx.scale 0.5, 0.5
    ctx.rotate ABM.util.degToRad(180)
    ctx.drawImage img, 0, 0
    ctx.restore()

window.Well = Well