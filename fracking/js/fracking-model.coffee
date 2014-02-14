class FrackingModel extends ABM.Model

  # "class" property
  @gradients = do ->
    gradients =
      air: [
        { stop: 0    , color: "#CBE9E6" },
        { stop: 0.178, color: "#A7DDE8" },
        { stop: 0.351, color: "#85D4EB" },
        { stop: 0.521, color: "#6BCEEE" },
        { stop: 0.689, color: "#58CAF0" },
        { stop: 0.855, color: "#4DC9F5" },
        { stop: 1    , color: "#49C8F5" }]

      land: [
        { stop: 0    , color: "#0193B1" },
        { stop: 0.011, color: "#0293AF" },
        { stop: 0.264, color: "#199C78" },
        { stop: 0.452, color: "#28A256" },
        { stop: 0.555, color: "#2DA549" },
        { stop: 1    , color: "#2DA549" }]

      water: [
        { stop: 0    , color: "#426587" },
        { stop: 0.168, color: "#41678F" },
        { stop: 0.436, color: "#3A6CA6" },
        { stop: 0.766, color: "#3D73B9" },
        { stop: 1    , color: "#4474BA" }]

      rock1: [
        { stop: 0    , color: "#7E461D" },
        { stop: 0.018, color: "#7E461D" },
        { stop: 0.873, color: "#563D2B" },
        { stop: 0.942, color: "#543D2D" },
        { stop: 0.966, color: "#4D3D33" },
        { stop: 0.984, color: "#413E3E" },
        { stop: 0.998, color: "#303F4C" },        
        { stop: 1    , color: "#2D3F50" }]

      shale: [
        { stop: 0    , color: "#DFCBAE" },
        { stop: 0.258, color: "#D6BE9D" },
        { stop: 0.769, color: "#BE9D6E" },
        { stop: 1    , color: "#B48E59" }]

      rock5: [
        { stop: 0    , color: "#251D19" },
        { stop: 0.027, color: "#271E1A" },
        { stop: 0.037, color: "#2E2420" },
        { stop: 0.044, color: "#39312D" },
        { stop: 0.045, color: "#3D342F" },
        { stop: 0.543, color: "#3F3530" },
        { stop: 0.732, color: "#463931" },  
        { stop: 0.868, color: "#523F33" },
        { stop: 0.979, color: "#634835" },  
        { stop: 1    , color: "#674A36" }]        

    for key, gradient of gradients
      for el, index in gradient
        unless index is 0
          el.priorStop = gradient[index-1].stop
          el.interpolator = d3.interpolateHsl gradient[index-1].color, el.color
    
    gradients

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
      if a.p.isWell
        a.trapped = false
        a.well = a.p.well
        a.hidden = not a.well.capped
        a.moveable = a.well.capped
      else if a.p.type is "open"
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
    if a.p.isWell
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
    else
      switch a.p.type
        when "air"
          @toKill.push a
          return
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
  
  getGradientColor: (gradient, y, yMin, yMax) ->
    # gradient vector points such that 0 => top of gradient area, 1 => bottom of gradient area
    fraction = (y - yMin) / (yMax - yMin)
    for el in gradient
      break if el.stop > fraction
    color = d3.rgb el.interpolator (fraction - el.priorStop) / (el.stop - el.priorStop)

    [color.r, color.g, color.b]

  patchChanged: (p, redraw=true)->
    return unless p?
    unless p.isWell
      g = @constructor.gradients
      p.color = switch p.type
        when "air"   then @getGradientColor g.air ,  p.y, @airDepth - 10       , @world.maxY
        when "land"  then @getGradientColor g.land,  p.y, @landDepth           , @airDepth
        when "water" then @getGradientColor g.water, p.y, @waterLowerDepth(p.x), @landDepth
        when "shale" then @getGradientColor g.shale, p.y, @shaleLowerDepth(p.x), @shaleUpperDepth(p.x)
        when "rock"
          switch p.rockType
            when "rock1" then @getGradientColor g.rock1, p.y, @rock1LowerDepth(p.x), @waterLowerDepth(p.x)
            when "rock2" then [157, 132,  72]
            when "rock3" then [90, 57,  40]
            when "rock4" then [157, 110,  64]
            when "rock5" then @getGradientColor g.rock5, p.y, @world.minY, @shaleLowerDepth(p.x)
        when "exploding" then [215, 50, 41]
        when "open"      then [0, 0, 0]
        when "cleanWaterWell", "cleanWaterOpen" then [45, 141, 190]
        when "dirtyWaterWell", "dirtyWaterOpen", "dirtyWaterPond" then [0, 147, 177]
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
    
    # memoization helper, so we don't constantly recalculate *LowerDepth(x) for every different y
    memo = (f) =>
      cache = {}
      (x) => cache[x] ? cache[x] = f(x)

    degToRad = @u.degToRad
    sin = (x) -> Math.sin(degToRad(x))

    # this is a common term found in several of the boundary functions
    f = (c, x, width) => sin(c*x - (width / 4))
    
    # Save these functions per-instance, so we can use them later when calculating patches' color
    # gradient
    @waterLowerDepth = memo (x) =>
      @waterDepth + @height * f(0.6, x, @width) / 160
    
    @rock1LowerDepth = memo (x) =>
      x * rock1Angle + @rock1Depth - @height * f(0.3, x, @width) / 160

    @rock2LowerDepth = memo (x) =>
      x * rock2Angle + @rock2Depth + @height * f(0.4, x, @width) / 160

    @rock3LowerDepth = memo (x) => 
      @rock3Depth + @height * f(0.2, x, @width) / 160

    @shaleUpperDepth = memo (x) =>
      @oilDepth + @height * sin(shaleUpperModifier * x) / 30

    @shaleLowerDepth = memo (x) =>
      @baseDepth - @height * 0.9 * sin(shaleLowerModifier * x + 45) / 50 + p.x / 10

    # TODO. This long if statement is silly, change it to iterate over x then y.
    for p in @patches
      p.type = "n/a"
      p.color = [255,255,255]

      if p.y > @airDepth
        p.type = "air"
      else if p.y > @landDepth
        p.type = "land"
      else if p.y > @waterLowerDepth(p.x)
        p.type = "water"
      else if p.y > @rock1LowerDepth(p.x)
        p.type = "rock"
        p.rockType = "rock1"
      else if p.y > @rock2LowerDepth(p.x)
        p.type = "rock"
        p.rockType = "rock2"
      else if p.y > @rock3LowerDepth(p.x)
        p.type = "rock"
        p.rockType = "rock3"
      else if p.y > @shaleUpperDepth(p.x)
        p.type = "rock"
        p.rockType = "rock4"
      else if p.y > @shaleLowerDepth(p.x)
        @shale.push p
        p.type = "shale"
      else
        p.type = "rock"
        p.rockType = "rock5"

      if p.y > @landDepth or @showEarthPatches
        @patchChanged p, false
      else
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
    if p.isWell
      return p.well
    else
      # look within an N patch radius of us for a well or wellWall patch
      near = @patches.patchRect p, 5, 5, true
      for pn in near
        if pn.isWell
          return pn.well

window.FrackingModel = FrackingModel

GasWell.WELL_HEAD_TYPES.push "air" unless ABM.util.contains(GasWell.WELL_HEAD_TYPES, "air")

$(document).trigger 'fracking-model-loaded'
