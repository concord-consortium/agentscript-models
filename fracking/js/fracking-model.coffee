class FrackingModel extends ABM.Model
  @DEBUG: false
  @showEarthPatches: false
  u: ABM.util
  airDepth: 0
  landDepth: 0
  waterDepth: 0
  oilDepth: 0
  baseDepth: 0
  rock1Depth: 0
  rock2Depth: 0
  width: 0
  height: 0
  shaleFractibility: 40
  rockFractibility: 10
  wellLimit: 3
  drillSpeed: 13
  gasSpeed: 12
  ticksPerYear: 100
  wells: null
  toRedraw: null
  toMoveToWaterGas: null
  baseMethaneInWater: 25

  leaks: false
  # 1/N wells will leak
  leakProbability: 10
  pondLeakProbability: 10
  # a methane turtle has a 1/N chance it will leak into the water layer
  # every tick that it is within the water layer. Currently gas agents are
  # within that layer for about 6 ticks.
  leakRate: 500
  # each leaked methane molecule or pond water contributes x scale
  leakedMethaneScale: 30
  pondWasteScale: 30

  toKill: null
  killed: 0
  leakedMethane: 0
  pondWaste: 0

  hiddenPatchColor: [220,220,220]

  @YEAR_ELAPSED: "modelYearElapsed"

  setup: ->
    @anim.setRate 30, false
    @setFastPatches()
    @patches.usePixels true
    @refreshPatches = false
    @setTextParams {name: "drawing"}, "10px sans-serif"
    @setLabelParams {name: "drawing"}, [255,255,255], [0,-20]

    @setupAgents()
    @setupGlobals()
    @setupPatches()
    @spawnInitialShaleGas()
    @draw()

    $(document).trigger 'model-ready'

  reset: ->
    super
    @setup()
    @anim.draw()

  setupAgents: ->
    @agentBreeds "gas waterGas shaleGas pondWater"

    for agents in [@gas, @waterGas, @shaleGas]
      agents.setDefaultShape "circle"
      agents.setDefaultSize 1
      agents.setDefaultColor [255, 0, 0]

    @pondWater.setDefaultShape "circle"
    @pondWater.setDefaultSize 2
    @pondWater.setDefaultColor [38,  90,  90]

  spawnInitialShaleGas: ->
    for p in @shale
      p.sprout(1, @shaleGas) if @u.randomFloat(1) < 0.03

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

    for a in @shaleGas
      @moveShaleGas(a)

    for a in @waterGas
      @moveWaterPollution(a)

    for a in @pondWater
      @movePondWater(a)

    if @toMoveToWaterGas.length > 0
      for a in @toMoveToWaterGas
        well = a.well
        res = a.changeBreed @waterGas
        res[0].well = well
      @toMoveToWaterGas = []

    if @toKill.length > 0
      for a in @toKill
        a.die()
        if a.well
          @killed++
          a.well.killed++
          a.well.totalKilled++
      @toKill = []

    for well in @wells
      well.spawnNewGas()
      well.leakWastePondWater()
      if well.tickAge() % @ticksPerYear is 0
        $(document).trigger GasWell.YEAR_ELAPSED, well

    if @anim.ticks % @ticksPerYear is 0
      $(document).trigger FrackingModel.YEAR_ELAPSED

    return true

  redraw: ->
    redrawSet = @u.clone @toRedraw
    @toRedraw = []
    setTimeout =>
      @patches.drawScaledPixels @contexts.patches, redrawSet
    , 1

  moveAgentTowardPipeCenter: (a)->
    return unless a.moveable

    return if a.trapped
    switch a.p.type
      when "air"
        @toKill.push a
        return
      when "well", "wellWall"
        # kill if we're close to the top
        if @landDepth < a.y < @airDepth
          @toKill.push a
          return
        # otherwise move up well
        dist = @u.randomInt(@gasSpeed)+3
        if -0.5 < (a.x - a.well.head.x) < 0.5
          if a.well.leaks and @u.randomInt(@leakRate) == 0 and (pWater = @patches.patchXY(a.x + (if @u.randomInt(2) is 0 then 3 else -3), a.y))?.type is "water"
            # Leak into the water
            a.moveTo pWater
            @toMoveToWaterGas.push a
            @leakedMethane += @leakedMethaneScale
          else
            # move vertically toward the well head
            a.heading = @u.degToRad(90)
            a.forward dist
        else
          # move horizontally
          dx = a.x - a.well.head.x
          a.heading = if dx > 0 then @u.degToRad(180) else 0
          if Math.abs(dx) > dist then a.forward(dist) else a.forward(Math.abs(dx))
      when "shale", "rock", "open"
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

  moveShaleGas: (a) ->
    if a.p.type is "open"
      @toKill.push a
    else if a.p.type isnt "shale"
      a.moveTo @shale[@u.randomInt @shale.length]
    else
      a.heading = @u.randomFloat(Math.PI*2)
      a.forward 0.2
    a.hidden = "#{a.p.color}" is "#{@hiddenPatchColor}"

  moveWaterPollution: (a, offset=0)->
    return if a.hidden
    if @u.colorsEqual a.p.color, [255,255,255]
      a.hidden = true
      return
    # Slowly diffuse through the water layer away from the well
    n = @u.randomInt 8
    if a.x > a.well.head.x + offset
      while n is 0 or n is 3 or n is 5
        n = @u.randomInt 8
    else
      while n is 2 or n is 4 or n is 7
        n = @u.randomInt 8
    pWater = a.p.n[n]
    if pWater? and pWater.type is "water"
      a.face pWater
      a.forward 0.05

  movePondWater: (a)->
    return if a.hidden
    if @u.colorsEqual a.p.color, [255,255,255]
      a.hidden = true
      return
    switch a.p.type
      when "land"
        n = @u.randomInt 3
        if a.p.n[n]?
          a.face a.p.n[n]
          a.forward 0.05
      when "water"
        @moveWaterPollution a, 22
      else
        console.log "bad patch type: " + a.p.type

  patchChanged: (p, redraw=true)->
    return unless p?
    p.color = switch p.type
      when "air"   then [128, 173, 255]
      when "land"  then [ 29, 159, 120]
      when "water" then [ 52,  93, 169]
      when "shale" then [237, 237,  49]
      when "rock"
        if p.rockType is "rock1" then [157, 110,  72]
        else if p.rockType is "rock2" then [157, 132,  72]
        else if p.rockType is "rock3" then [90, 57,  40]
        else if p.rockType is "rock4" then [157, 110,  64]
        else [81, 61,  54]
      when "well"  then [141, 141, 141]
      when "wellWall" then [87, 87, 87]
      when "exploding" then [215, 50, 41]
      when "open"      then [0, 0, 0]
      when "cleanWaterWell", "cleanWaterOpen" then [45, 141, 190]
      when "dirtyWaterWell", "dirtyWaterOpen", "dirtyWaterPond" then [38,  90,  90]
      when "cleanPropaneWell", "cleanPropaneOpen", "dirtyPropaneWell", "dirtyPropaneOpen" then [122, 192, 99]
    @toRedraw.push p if redraw

  setupGlobals: ->
    @width  = @patches.maxX - @patches.minX
    @height = @patches.maxY - @patches.minY
    @airDepth   = @patches.minY + Math.round(@height * 0.93)
    @landDepth  = @airDepth - Math.round(@height * 0.02)
    @waterDepth = @landDepth - Math.round(@height * 0.03)
    @rock1Depth = Math.round(@patches.minY + @waterDepth * 0.6)
    @rock2Depth = Math.round(@patches.minY + @waterDepth * @u.randomFloat2(0.6,0.7))
    @rock3Depth = Math.round(@patches.minY + @waterDepth * 0.4)
    @oilDepth   = Math.round(@patches.minY + @waterDepth * 0.2)
    @baseDepth  = Math.round(@patches.minY + @waterDepth * 0.1)

    @wells = []
    @toRedraw = []
    @toKill = []
    @toMoveToWaterGas = []

    @killed = 0
    @leakedMethane = 0
    @pondWaste = 0

    @drillSpeed = 10 if FrackingModel.DEBUG
    @leakProbability = 1 if FrackingModel.DEBUG
    @pondLeakProbability = 1 if FrackingModel.DEBUG

  setupPatches: ->
    @shale = []

    shaleUpperModifier = @u.randomFloat(0.2)
    shaleLowerModifier = @u.randomFloat(0.4)
    rock1Angle = @u.randomFloat(0.1)+0.2
    rock2Angle = @u.randomFloat(0.1)+0.05
    for p in @patches
      p.type = "n/a"
      p.color = [255,255,255]
      # continue if p.isOnEdge()
      waterLowerDepth = (@waterDepth + @height * Math.sin(@u.degToRad(0.6*p.x - (@width / 4))) / 160)
      rock1LowerDepth = (p.x*rock1Angle)+(@rock1Depth + @height * -Math.sin(@u.degToRad(0.3*p.x - (@width / 4))) / 160)
      rock2LowerDepth = (p.x*rock2Angle)+(@rock2Depth + @height * Math.sin(@u.degToRad(0.4*p.x - (@width / 4))) / 160)
      rock3LowerDepth = (@rock3Depth + @height * Math.sin(@u.degToRad(0.2*p.x - (@width / 4))) / 160)
      shaleUpperDepth = (@oilDepth + @height * Math.sin(@u.degToRad(shaleUpperModifier * p.x)) / 30)
      shaleLowerDepth = (@baseDepth + @height * 0.9 * -Math.sin(@u.degToRad(shaleLowerModifier * p.x + 45)) / 50 + (p.x / 10))
      if p.y > @airDepth
        p.type = "air"
        @patchChanged(p, false)
      else if p.y > @landDepth and p.y <= @airDepth
        p.type = "land"
        @patchChanged(p, false)
      else if @landDepth >= p.y > waterLowerDepth
        p.type = "water"
        @patchChanged(p, false) if @showEarthPatches
      else if waterLowerDepth >= p.y > rock1LowerDepth
        p.type = "rock"
        p.rockType = "rock1"
        @patchChanged(p, false) if @showEarthPatches
      else if rock1LowerDepth >= p.y > rock2LowerDepth
        p.type = "rock"
        p.rockType = "rock2"
        @patchChanged(p, false) if @showEarthPatches
      else if rock2LowerDepth >= p.y > rock3LowerDepth
        p.type = "rock"
        p.rockType = "rock3"
        @patchChanged(p, false) if @showEarthPatches
      else if rock3LowerDepth >= p.y > shaleUpperDepth
        p.type = "rock"
        p.rockType = "rock4"
        @patchChanged(p, false) if @showEarthPatches
      else if shaleUpperDepth >= p.y > shaleLowerDepth
        @shale.push p
        p.type = "shale"
        @patchChanged(p, false) if @showEarthPatches
      else if p.y <= shaleLowerDepth
        p.type = "rock"
        p.rockType = "rock5"
        @patchChanged(p, false) if @showEarthPatches

      if p.y <= @landDepth and not @showEarthPatches
        p.color = @hiddenPatchColor

      @toRedraw.push p
      @redraw() if @toRedraw.length > 1000

  drillDirection: null
  drill: (p)->
    return unless @drillDirection?
    # drill at the specified patch
    well = @findNearbyWell(p)
    if well?
      well.drill @drillDirection, @drillSpeed
    else if @drillDirection is "down" and p.type is "land" and p.x > (@patches.minX + 3) and p.x < (@patches.maxX - 38)
      return if @wells.length >= @wellLimit
      for w in @wells
        return if (0 < Math.abs(p.x - w.head.x) < 30)
      leaks = (@leaks and @u.randomInt(@leakProbability) == 0)
      pondLeaks = (@leaks and @u.randomInt(@pondLeakProbability) == 0)
      well = new GasWell @, p.x, @airDepth+1, leaks, pondLeaks
      @wells.push well
      # start a new vertical well as long as we're not too close to the wall
      for y in [@airDepth..(p.y)]
        well.drillVertical()
    @redraw()

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

$(document).trigger 'fracking-model-loaded'
