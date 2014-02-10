class GasWell extends Well
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
  explodingInProgress: false
  exploded: false
  fillingInProgress: false
  filled: false
  frackingInProgress: false
  fracked: false

  @LOOKAHEAD_TYPES: ["open","cleanWaterOpen","cleanPropaneOpen","dirtyWaterOpen","dirtyPropaneOpen"]

  # fill types
  @PROPANE: 'Propane'
  @WATER:   'Water'

  # some event types
  @CAN_EXPLODE: "canExplode"
  @EXPLODED: 'exploded'
  @FILLED: 'filled'
  @FRACKED: 'fracked'

  # some graphical images
  @POND_IMG: ABM.util.importImage 'img/well-pond.png'

  constructor: (@model, @x, @depth, @leaks=false, @pondLeaks=false)->
    # set these here so all Well instances don't share the same arrays
    @open = []
    @openShale = []
    @filling = []
    @exploding = []
    @fracking = []
    @pumping = []
    @pond = []

    console.log "*" if @leaks
    console.log "+" if @pondLeaks

    super

  addOpen: (p)->
    @open.push p
    p.well = @

  addExploding: (p)->
    @openShale.push p if p.type is "shale"
    p.type = "exploding"
    p.well = @
    @model.patchChanged p
    @exploding.push p

  drill: (drillDirection, drillSpeed)->
    return if @explodingInProgress or
      @fillingInProgress or @filled or
      @frackingInProgress or @fracked
    super

  drillHorizontal: ->
    super
    if @goneHorizontal
      # set up "exploding" patches every 10
      if Math.abs(@x - @head.x) % 10 == 0
        for y in [(@depth-4)..(@depth-2)]
          pw = @model.patches.patchXY @x, y
          @addExploding pw
        for y in [(@depth+4)..(@depth+2)]
          pw = @model.patches.patchXY @x, y
          @addExploding pw
        @exploded = false
        $(document).trigger GasWell.CAN_EXPLODE

      # Also expose the color of the 5 patches to top/bottom
      for y in [(@depth - 7)..(@depth + 7)]
        @model.patchChanged @model.patches.patchXY @x, y

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
      $(document).trigger @constructor.EXPLODED
      return
    @explodingInProgress = true
    currentExploding = ABM.util.clone @exploding
    @exploding = []
    setTimeout =>
      @processSet currentExploding, =>
        @explode()
      , (p)=>
        return if p.isWell
        switch p.type
          when "shale"
            if ABM.util.randomInt(100) < @model.shaleFractibility
              @addExploding p
          when "rock"
            if ABM.util.randomInt(100) < @model.rockFractibility
              @addExploding p
      , (p)=>
        return if p.isWell
        p.type = "open"
        @addOpen p
        @model.patchChanged p
    , 50

  fill: ->
    if @filling.length <= 0
      @filled = true if @fillingInProgress
      @fillingInProgress = false
      $(document).trigger @constructor.FILLED
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
        return if p.isWell
        switch p.type
          when "open"
            if p.well? and p.well is @
              p.type = "clean" + @fillType + "Open"
              @model.patchChanged p
              @filling.push p
    , 50

  floodWater: ->
    @fillType = @constructor.WATER
    @flood()

  floodPropane: ->
    @fillType = @constructor.PROPANE
    @flood()

  flood: ->
    return if @capped or @filled or @fracked or not @exploded
    for p in @patches
      if @fillType is @constructor.WATER
        p.color = [45, 141, 190]
      else
        p.color = [122, 192, 99]
      @model.patchChanged p

    @createWastePond() if @fillType is @constructor.WATER

    @fillingInProgress = true
    @model.redraw()

    @filling = ABM.util.clone @walls
    @fill()

  frack: ->
    return unless @filled
    if @fracking.length <= 0
      @fracked = true if @frackingInProgress
      @frackingInProgress = false
      $(document).trigger @constructor.FRACKED
      return
    @frackingInProgress = true
    currentFracking = ABM.util.clone @fracking
    @fracking = []
    fractibilityModifier = switch @fillType
      when @constructor.WATER then 1.05
      when @constructor.PROPANE then 1.1
      else 1
    setTimeout =>
      @processSet currentFracking, =>
        @frack()
      , (p)=>
          return if p.isWell
          switch p.type
            when "shale"
              if ABM.util.randomInt(100) < (@model.shaleFractibility * fractibilityModifier)
                @fracking.push p
                p.type = "dirty" + @fillType + "Open"
                @addOpen p
                @model.patchChanged p
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
        @model.patchChanged p

    @empty()

  empty: ->
    if @pumping.length <= 0
      @filled = false
      @capped = true if @cappingInProgress
      @cappingInProgress = false
      $(document).trigger @constructor.CAPPED
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
        if p.isWell
          p.color = [141, 141, 141]
        else
          p.type = "open"
        @model.patchChanged p

      if pondFilling.length > 0
        for p in pondFilling
          p.type = "dirtyWaterPond"
          @model.patchChanged p
    , 50

  cycleWaterColors: ->
    if @fillType is @constructor.WATER
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
          if @fillType is @constructor.WATER
            p.color = [38,  90,  90]
          else
            p.color = [122, 192, 99]

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
    @drawUI @constructor.POND_IMG, @head.x + 17, @head.y

    for y in [(@head.y-7)...(@head.y)]
      for x in [(@head.x+6)...(@head.x+16)]
        p = @model.patches.patchXY x, y
        if p?
          @pond.push p
          p.type = "air"
          @model.patchChanged p

    null

  leakWastePondWater: ->
    if @pondLeaks and @capped and @pond.length > 0 and ABM.util.randomInt(50) is 0
      @model.pondWaste += @model.pondWasteScale
      @model.pondWater.create 1, (a)=>
        a.well = @
        a.moveTo @model.patches.patchXY(@head.x + ABM.util.randomInt(12) + 6, @head.y - 8)

  eraseUI: ->
    super
    ctx = @model.contexts.drawing
    ctx.save()
    ctx.globalCompositeOperation = "destination-out"
    ctx.translate @head.x, @head.y
    ctx.fillRect 0, -17, 30, 20
    ctx.restore()


  remove: ->
    if @explodingInProgress or @fillingInProgress or @frackingInProgress or @cappingInProgress
      setTimeout =>
        @remove()
      , 100
    else
      for p in @open.concat(@openShale, @filling, @exploding, @fracking, @pumping)
        p.isWell = null
        p.well = null
        @model.patchChanged p
      for p in @pond
        p.isWell = null
        p.well = null
        p.type = "land"
        @model.patchChanged p
      @open = @openShale = @filling = @exploding = @fracking = @pumping = @pond = []
      super

window.GasWell = GasWell