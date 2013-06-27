class FrackingModel extends ABM.Model
  DEBUG: false
  u: ABM.util
  airDepth: 0
  landDepth: 0
  waterDepth: 0
  oilDepth: 0
  baseDepth: 0
  width: 0
  height: 0
  shaleFractibility: 42
  rockFractibility: 10
  drillSpeed: 3
  wells: null
  toRedraw: null

  setup: ->
    @anim.setRate 30, false
    @setFastPatches()
    @patches.usePixels true
    @refreshPatches = false
    @agentBreeds "gas"

    @setupGlobals()
    @setupPatches()
    @setupGas()

  reset: ->
    super
    @setup()
    @anim.draw()

  toKill: []
  killed: 0
  step: ->
    # move gas turtles to the surface, if possible
    for a in @gas
      continue unless a.p?
      switch a.p.type
        when "well", "wellWall"
          a.trapped = false
          a.well = a.p.well
          a.hidden = not a.well.capped
          a.moveable = a.well.capped
        when "open"
          a.well = a.p.well
          a.hidden = not a.well.capped
          a.moveable = a.well.capped
      @moveAgentTowardPipeCenter(a)

    if @toKill.length > 0
      for a in @toKill
        a.die()
        @killed++
      @toKill = []

    if @anim.ticks % 100 is 0
      console.log("Killed " + @killed)
      @killed = 0

    return true

  redraw: ->
    redrawSet = @u.clone @toRedraw
    @toRedraw = []
    setTimeout =>
      @patches.drawScaledPixels @contexts.patches, redrawSet
    , 1

  moveAgentTowardPipeCenter: (a)->
    return unless a.moveable

    # randomly spawn new gas
    if @u.randomFloat(1000) < (990/(a.well.length() + 50))
      a.hatch 1, @gas, (g)=>
        a.trapped = false
        placed = false
        while not placed or a.p.type isnt "open"
          x = 2 + @u.randomInt(@width - 4)
          y = 2 + @u.randomInt(@height - 4)
          a.moveTo @patches.patchXY(x, y)
          placed = true
        a.well = a.p.well

    return if a.trapped
    switch a.p.type
      when "air"
        @toKill.push a
        return
      when "well"
        if -0.5 < (a.x - a.well.head.x) < 0.5
          # move vertically toward the well head
          a.heading = @u.degToRad(90)
        else
          # move horizontally
          a.heading = if a.x > a.well.head.x then @u.degToRad(180) else 0
        a.forward 1
      when "shale", "rock", "wellWall", "open"
        if a.y > a.well.depth and -0.5 < (a.x - a.well.head.x) < 0.5
          # somehow we're right under the well head, but not on a well patch...
          # move vertically toward the well head anyway
          a.heading = @u.degToRad(90)
        else if a.y > a.well.depth and Math.abs(a.x - a.well.head.x) <= 2
          # move horizontally to the center of the vertical shaft
          a.heading = if a.x > a.well.head.x then @u.degToRad(180) else 0
        else
          # if the well bends right, and we're left of the vertical shaft,
          # aim for the center of the bend. Vice versa, as well.
          if not a.well.toTheRight and a.x > a.well.head.x
            a.face @patches.patchXY a.well.head.x, a.well.depth+1
          else if a.well.toTheRight and a.x < a.well.head.x
            a.face @patches.patchXY a.well.head.x, a.well.depth+1
          # if we're past the end of the horizontal pipe, aim for the end of the pipe
          else if a.well.toTheRight and a.x > a.well.x
            a.face @patches.patchXY a.well.x-2, a.well.depth
          else if not a.well.toTheRight and a.x < a.well.x
            a.face @patches.patchXY a.well.x+2, a.well.depth
          else
            # move vertically toward the horizontal pipe center
            a.heading = if a.y < a.well.depth then @u.degToRad(90) else @u.degToRad(270)
        a.forward 1
      else
        console.log("Hit layer: " + a.p.type)


  setPatchColor: (p, redraw=true)->
    return unless p?
    p.color = switch p.type
      when "air"   then [ 93, 126, 186]
      when "land"  then [ 29, 159, 120]
      when "water" then [ 52,  93, 169]
      when "shale" then [237, 237,  49]
      when "rock"  then [157, 110,  72]
      when "well"  then [141, 141, 141]
      when "wellWall" then [87, 87, 87]
      when "exploding" then [215, 50, 41]
      when "open"      then [0, 0, 0]
      when "cleanWaterWell", "cleanWaterOpen" then [45, 141, 190]
      when "dirtyWaterWell", "dirtyWaterOpen" then [38,  90,  90]
      when "cleanPropaneWell", "cleanPropaneOpen", "dirtyPropaneWell", "dirtyPropaneOpen" then [122, 192, 99]
    @toRedraw.push p if redraw

  setupGlobals: ->
    @width  = @patches.maxX - @patches.minX
    @height = @patches.maxY - @patches.minY
    @airDepth   = @height - 90 # Math.round(@patches.minY + @patches.maxY * 0.8)
    @landDepth  = @airDepth - 20 # Math.round(@patches.minY + @patches.maxY * 0.75)
    @waterDepth = @landDepth - 50 # Math.round(@patches.minY + @patches.maxY * 0.6)
    @oilDepth   = Math.round(@patches.minY + @waterDepth * 0.2)
    @baseDepth  = Math.round(@patches.minY + @waterDepth * 0.1)

    @wells = []
    @toRedraw = []

  setupPatches: ->
    shaleUpperModifier = @u.randomFloat(1.5)
    shaleLowerModifier = @u.randomFloat(1.5)
    for p in @patches
      p.type = "n/a"
      p.color = [255,255,255]
      @toRedraw.push p
      @redraw() if @toRedraw.length > 1000
      # continue if p.isOnEdge()
      waterLowerDepth = (@waterDepth + @height * Math.sin(@u.degToRad(0.6*p.x - (@width / 4))) / 160)
      shaleUpperDepth = (@oilDepth + @height * Math.sin(@u.degToRad(shaleUpperModifier * p.x)) / 30)
      shaleLowerDepth = (@baseDepth + @height * 0.9 * Math.sin(@u.degToRad(shaleLowerModifier * p.x + 45)) / 50 + (p.x / 10))
      if p.y > @airDepth
        p.type = "air"
        @setPatchColor(p, false)
      else if p.y > @landDepth and p.y <= @airDepth
        p.type = "land"
        @setPatchColor(p, false)
      else if @landDepth >= p.y > waterLowerDepth
        p.type = "water"
        @setPatchColor(p, false) if @DEBUG
      else if waterLowerDepth >= p.y > shaleUpperDepth
        p.type = "rock"
        @setPatchColor(p, false) if @DEBUG
      else if shaleUpperDepth >= p.y > shaleLowerDepth
        p.type = "shale"
        @setPatchColor(p, false) if @DEBUG
      else if p.y <= shaleLowerDepth
        p.type = "rock"
        @setPatchColor(p, false) if @DEBUG

  setupGas: ->
    @gas.create 4000, (a)=>
      placed = false
      while not placed or a.p.type isnt "shale"
        x = 2 + @u.randomInt(@width - 4)
        y = 2 + @u.randomInt(@height - 4)
        a.moveTo @patches.patchXY(x, y)
        placed = true
      a.color = [255, 0, 0]
      a.heading = @u.degToRad(180)
      a.size = 4
      a.moveable = false
      a.trapped = (@u.randomInt(100) <= 14)
      a.shape = "triangle"
      a.hidden = not @DEBUG

  drillDirection: null
  drill: (p)->
    return unless @drillDirection?
    # drill at the specified patch
    well = @findNearbyWell(p)
    if well?
      return if well.explodingInProgress or
        well.fillingInProgress or well.filled or
        well.frackingInProgress or well.fracked or
        well.cappingInProgress or well.capped

      # if we're up in the land area, go verticall
      # if p.y > @landDepth and p.y <= @airDepth
      if @drillDirection is "down" and not well.goneHorizontal
        # drill one deeper
        for i in [0...@drillSpeed]
          @drillVertical(well)
      else if @drillDirection isnt "down"
        if not well.toTheRight?
          well.toTheRight = (@drillDirection is "right")

        if (@drillDirection is "right" and well.toTheRight) or (@drillDirection is "left" and not well.toTheRight)
          # drill horizontally
          for i in [0...@drillSpeed]
            @drillHorizontal(well)
    else if @drillDirection is "down" and p.type is "land" and p.x > (@patches.minX + 3) and p.x < (@patches.maxX - 3)
      well = new Well @, p.x, @airDepth+1
      @wells.push well
      # start a new vertical well as long as we're not too close to the wall
      for y in [@airDepth..(p.y)]
        @drillVertical(well)
    @redraw()

  drillVertical: (well)->
    y = well.depth - 1
    return if y < (@patches.minY - 5)
    return if well.goneHorizontal

    lookahead = @patches.patchXY(well.x, y-5)
    return if lookahead? and @u.contains(["wellWall","open","cleanWaterOpen","cleanPropaneOpen","dirtyWaterOpen","dirtyPropaneOpen"], lookahead.type)

    #draw the well
    for x in [(well.x - 1)..(well.x + 1)]
      pw = @patches.patchXY x, y
      well.addPatch pw

    # and the well walls
    for x in [(well.x - 2), (well.x + 2)]
      pw = @patches.patchXY x, y
      well.addWall pw

    # Also expose the color of the 5 patches to either side
    for x in [(well.x - 7)..(well.x + 7)]
      @setPatchColor @patches.patchXY x, y

    well.depth = y

  drillHorizontal: (well)->
    if not well.goneHorizontal
      pivotX = if well.toTheRight then well.x + 2 else well.x - 2
      pivot = @patches.patchXY pivotX, well.depth

      for x in [(well.x - 7)..(well.x + 7)]
        for y in [(well.depth - 1)..(well.depth - 8)]
          p = @patches.patchXY x, y
          if (well.toTheRight and x <= pivot.x) or (not well.toTheRight and x >= pivot.x)
            d = @u.distance(pivot.x, pivot.y, p.x, p.y)
            if d > 3.9 and d < 4.5
              well.addWall p
            else if d <= 3.9
              well.addPatch p
          @setPatchColor p
      well.depth = well.depth - 2
      well.x = well.x + (if well.toTheRight then 2 else -2)

      well.goneHorizontal = true
    else
      x = well.x + (if well.toTheRight then 1 else -1)
      return if x > (@patches.maxX - 1) or x < (@patches.minX + 1)

      lx = well.x + (if well.toTheRight then 5 else -5)
      lookahead = @patches.patchXY(lx, well.depth)
      return if lookahead? and @u.contains(["wellWall","open","cleanWaterOpen","cleanPropaneOpen","dirtyWaterOpen","dirtyPropaneOpen"], lookahead.type)

      #draw the well
      for y in [(well.depth - 1)..(well.depth + 1)]
        pw = @patches.patchXY x, y
        well.addPatch pw

      # and the well walls
      for y in [(well.depth - 2), (well.depth + 2)]
        pw = @patches.patchXY x, y
        well.addWall pw

      # set up "exploding" patches every 20
      if Math.abs(x - well.head.x) % 20 == 0
        for y in [(well.depth-7)..(well.depth-3)]
          pw = @patches.patchXY x, y
          well.addExploding pw
        for y in [(well.depth+7)..(well.depth+3)]
          pw = @patches.patchXY x, y
          well.addExploding pw
        well.exploded = false
        $(document).trigger Well.CAN_EXPLODE

      # Also expose the color of the 5 patches to top/bottom
      for y in [(well.depth - 7)..(well.depth + 7)]
        @setPatchColor @patches.patchXY x, y

      well.x = x

  explode: ->
    for well in @wells
      well.explode()

  floodWater: ->
    for well in @wells
      well.floodWater()

  floodPropane: ->
    for well in @wells
      well.floodPropane()

  pumpOut: ->
    for well in @wells
      well.pumpOut()

  findNearbyWell: (p)->
    if p.type is "well" or p.type is "wellWall"
      return p.well
    else
      # look within an N patch radius of us for a well or wellWall patch
      near = @patches.patchRect p, 5, 5, true
      for pn in near
        if pn.type is "well" or pn.type is "wellWall"
          return pn.well

window.FrackingModel = FrackingModel

class Well
  x: 0,
  depth: 0,
  head: null
  patches: null
  walls: null
  open: null
  filling: null
  exploding: null
  fracking: null
  pumping: null

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
  @CAN_EXPLODE: "canExplode"
  @EXPLODED: 'exploded'
  @FILLED: 'filled'
  @FRACKED: 'fracked'
  @CAPPED: 'capped'

  constructor: (@model, @x, @depth)->
    # set these here so all Well instances don't share the same arrays
    @head = {x: 0, y: 0}
    @patches = []
    @walls = []
    @open = []
    @filling = []
    @exploding = []
    @fracking = []
    @pumping = []

    @head.x = @x
    @head.y = @depth

  length: ->
    Math.abs(@x - @head.x) + Math.abs(@depth - @head.y)

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
    @empty()

  empty: ->
    if @pumping.length <= 0
      @filled = false
      @capped = true if @cappingInProgress
      @cappingInProgress = false
      $(document).trigger Well.CAPPED
      return
    currentPumping = @pumping.slice(0,100)
    @pumping = @pumping.slice(100)
    setTimeout =>
      @processSet currentPumping, =>
        @empty()
      , null, (p)=>
        p.type = if p.type.match(/.*Well$/) then "well" else "open"
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

window.Well = Well
