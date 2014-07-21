class AirPollutionModel extends ABM.Model
  @GRAPH_INTERVAL_ELAPSED: 'graph-interval-lapsed'

  @pollutantColors =
    primary: [102, 73, 53]
    secondary: [244, 121, 33]

  LEFT: ABM.util.degToRad 180
  RIGHT: 0
  UP: ABM.util.degToRad 90
  DOWN: ABM.util.degToRad 270
  PI2: Math.PI * 2
  FACTORY_POLLUTION_SPAWN_OFFSETS: [
    {x: 133, y:   3},
    {x: 122, y:  -5},
    {x: 106, y: -15},
    {x:  93, y: -19}
  ]
  FACTORY_SPAWN_POS: [
    {x: 160, y: 160, size: 1},
    {x: 100, y: 100, size: 0.5},
    {x: 240, y: 120, size: 0.8},
    {x: 320, y: 120, size: 0.5},
    {x:  90, y: 110, size: 0.3}
  ]
  CAR_SPAWN: null

  includeSunlight: true
  includeInversionLayer: false

  mountainsX: 410
  oceanX: 120
  landY: 85
  inversionY: 190
  rainMax: 350

  graphSampleInterval: 10

  windSpeed: 0
  maxNumCars: 10
  maxNumFactories: 5
  factoryDensity: 5
  carPollutionRate: 60
  electricCarPercentage: 25
  factoryPollutionRate: 100
  raining: false
  temperature: 50

  inversionStrength: 0

  sunlightAmount: 6
  rainRate: 3
  nextRainEnd: 0

  constructor: ->
    super
    @setNumFactories 0
    @setRootVars()

  setup: ->
    @anim.setRate 50, false
    @setFastPatches()
    @patches.usePixels true
    @setTextParams {name: "drawing"}, "10px sans-serif"
    @setLabelParams {name: "drawing"}, [255,255,255], [0,-20]

    @patches.importColors "img/air-pollution-bg-mask.png", => @setupCars()
    @patches.importDrawing "img/air-pollution-bg.png"

    @setCacheAgentsHere()

    ['sedan-left-side', 'sedan-right-side',
     'sedan-front-quarter', 'sedan-rear-quarter',
     'sedan-front', 'sedan-rear'].forEach (shapeName) ->

      img = document.getElementById shapeName.replace /-.*-side/, '-side'
      flip = (shapeName.indexOf('-right-side') > 0) or (shapeName.indexOf('-front-quarter') > 0)

      ABM.shapes.add shapeName, false, (ctx) ->
        ctx.scale (if flip then -1 else 1), -1
        ctx.translate 0, -img.height
        if flip then ctx.translate -img.width, 0
        ctx.drawImage img, 0, 0

    factoryImg = document.getElementById('factory-sprite')

    ABM.shapes.add "factory", false, (ctx)=>
      ctx.scale(-1, 1)
      ctx.rotate @LEFT
      ctx.drawImage(factoryImg, 0, 0)
    ABM.shapes.add "pollutant", false, (ctx)=>
      ctx.arc -0.5, -0.5, 0.5, 0, @PI2, false
      ctx.arc 0.5, -0.5, 0.5, 0, @PI2, false
      ctx.arc 0, 0.5, 0.5, 0, @PI2, false
      ctx.fill()

    @agentBreeds "wind cars factories primary secondary rain sunlight"

    @setupFactories()
    @setupWind()
    @setupPollution()
    @setupRain()
    @setupSunlight() if @includeSunlight

    @nextRainEnd = 0
    @raining = false

    @draw()
    @refreshPatches = false

  reset: ->
    super
    @setup()
    @anim.draw()

  step: ->
    @moveWind()
    @moveCars()
    @movePollution()
    @pollute()

    @moveAndEmitSunlight() if @includeSunlight
    @moveRain()
    @checkForRain()

    @notifyGraphs() if @anim.ticks % @graphSampleInterval is 0

    return

  setupWind: ->
    @wind.setDefaultSize 5
    @wind.setDefaultColor [0, 0, 255, 0.2]
    @wind.setDefaultShape "arrow"
    @wind.setDefaultHidden true
    @wind.setDefaultHeading 0

    @wind.create 30, (w)=>
      row = Math.floor((@wind.length-1) / 5)
      x = ((@wind.length-1) % 5) * 90 + (row * 30)
      y = row * 30 + 10
      w.moveTo @patches.patchXY(x,y)


  setupCars: ->
    @cars.setDefaultSize 1
    tracks = []

    p = ABM.patches.patchXY ABM.patches.maxX, ABM.patches.maxY

    for i in [0..1]
      until p.color[0] ==  255 and p.color[1] == 0
        p = p.n[1]
        break if p.y < 1

      tracks[i] = @followTrack p
      p = p.n[1]

    # The first track (track[0]) "starts" at the edge and proceeds to the city.
    # Reverse the second track, so it "starts" at the city and proceeds to the edge.
    tracks[1].reverse()

    @tracks = tracks.map (track, i) ->
      headingLeft = i is 0
      [yMin, yMax] = [track[0].y, track[track.length-1].y].sort (a, b) -> a - b

      track.map (p) ->
        dist = (p.y - yMin) / (yMax - yMin)
        distsq = dist*dist
        greenChannelHigh = p.color[1] > 100
        blueChannelHigh  = p.color[2] > 100

        {
          patch:
            p
          dwellTime:
            1 + Math.ceil 5 * distsq
          scale:
            do ->
              scale = 1 - 0.9 * distsq
              if blueChannelHigh then scale * 0.8 else scale
          shapeSuffix:
            if greenChannelHigh
              if headingLeft then 'rear-quarter' else 'front-quarter'
            else if blueChannelHigh
              if headingLeft then 'rear' else 'front'
            else
              if headingLeft then 'left-side' else 'right-side'
        }

    @cars.create 1, (car) =>
      car.track = @tracks[0]
      car.moveTo car.track[0].patch

    @cars.create 1, (car) =>
      car.track = @tracks[1]
      car.moveTo car.track[0].patch


  followTrack: (p) ->
    track = []
    reversed = false

    while p.color[0] > 50
      track.push p

      # Basic line following. We have a 1-px, non-aliased colored line to follow.
      #
      # Search "forward leading" neighbors if we haven't gone around the bend, "backwards leading"
      # neighbors if we have. Never search both sets at the same time or we could get stuck in an
      # infinite loop taking one step forward, then one step back.

      neighbors = if reversed then [4, 7, 6, 5] else [3, 5, 6, 7]
      patches = (p.n[i] for i in neighbors)
      reds = patches.map (p) -> p.color[0]
      indexOfReddest = reds.indexOf Math.max.apply(null, reds)
      p = patches[indexOfReddest]

      # The line is such that the first time we follow a pixel into the northeast quadrant, that
      # means we've gone around the bend and only travel to the right until the end of the road.
      if indexOfReddest == 3 and not reversed then reversed = true

    track


  setupFactories: ->
    @factories.setDefaultSize 1
    @factories.setDefaultHeading @LEFT
    @factories.setDefaultShape "factory"
    @factories.setDefaultColor [0,0,0]
    @factories.setDefaultHidden true

    @factories.create @maxNumFactories, (f)=>
      pos = @FACTORY_SPAWN_POS[@factories.length-1]
      f.moveTo @patches.patchXY pos.x, pos.y
      f.size = pos.size
      f.createTick = @anim.ticks || 0

    @setNumFactories 1

  setupPollution: ->
    @primary.setDefaultSize 3
    @primary.setDefaultHeading @UP
    @primary.setDefaultShape "circle"
    @primary.setDefaultColor AirPollutionModel.pollutantColors.primary
    @primary.setDefaultHidden false

    @secondary.setDefaultSize 3
    @secondary.setDefaultHeading @UP
    @secondary.setDefaultShape "circle"
    @secondary.setDefaultColor AirPollutionModel.pollutantColors.secondary
    @secondary.setDefaultHidden false

  setupRain: ->
    # Create rain which falls according to wind speed.
    @rain.create 220, (c)=>
      x = ABM.util.randomInt(@world.maxX - @world.minX) + @world.minX
      y = ABM.util.randomInt(@rainMax - @world.minY) + @world.minY
      c.moveTo @patches.patchXY(x,y)
      c.heading = @DOWN
      c.size = 2
      c.shape = "circle"
      c.color = [0, 0, 128]
      c.hidden = true

  setupSunlight: ->
    @sunlight.setDefaultSize 2
    @sunlight.setDefaultHeading Math.PI*7/4
    @sunlight.setDefaultShape "circle"
    @sunlight.setDefaultColor [255,255,0]
    @sunlight.setDefaultHidden false

  setWindSpeed: (speed)->
    @windSpeed = speed
    for w in @wind
      w.hidden = (speed is 0)
      w.size = Math.abs(@_intSpeed(10)) + 5
      w.heading = if speed >= 0 then 0 else @LEFT

    for r in @rain
      r.heading = @DOWN + ABM.util.degToRad(@windSpeed/2)

    if speed <= 0
      @inversionStrength = 0
    else
      @inversionStrength = speed*4.5 / 100
    @draw() if @anim.animStop

  setNumCars: (n) ->

  getNumVisible: (xs) -> xs.filter((x) -> not x.hidden).length

  getNumCars: -> @getNumVisible @cars

  setNumFactories: (n)->
    for i in [0...(@factories.length)]
      f = @factories[i]
      f.hidden = (i >= n)

    @draw() if @anim.animStop

  getNumFactories: -> @getNumVisible @factories

  moveWind: ->
    speed = @_intSpeed(15)
    for w in @wind
      y = w.y
      x = w.x+speed
      if x > @mountainsX
        x = x-@mountainsX
      else if x < 0
        x = x+@mountainsX
      w.moveTo @patches.patchXY x, y

  moveCars: ->
    for car in @cars
      car.trackIndex ?= 0
      car.ttlAtPatch ?= 1

      continue unless --car.ttlAtPatch is 0

      if ++car.trackIndex is car.track.length then car.trackIndex = 0
      patchInfo = car.track[car.trackIndex]

      car.moveTo patchInfo.patch
      car.ttlAtPatch = patchInfo.dwellTime
      car.size = patchInfo.scale
      car.shape = 'sedan-' + patchInfo.shapeSuffix
    null

  movePollution: ->
    pollutionToRemove = []

    for a in @primary
      if @_movePollutionAgent(a)
        pollutionToRemove.push a

    for a in @secondary
      if @_movePollutionAgent(a)
        pollutionToRemove.push a

    for a in pollutionToRemove
      a.die()

  _movePollutionAgent: (a)->
    u = ABM.util

    # First, do a basic movement based on a randomly drifting base heading,
    # with speed determined by the turbulence of the model. Keep a.heading in range [-pi, pi]
    a.heading += u.randomCentered(Math.PI/9)
    a.heading -= (2 * Math.PI) if a.heading > Math.PI
    a.heading += (2 * Math.PI) if a.heading < -Math.PI

    if @includeInversionLayer
      if (@inversionY-10) < a.p.y <= @inversionY
        if 0 < a.heading < Math.PI
          trapProb = @inversionStrength - (@inversionY - a.p.y) * (@inversionStrength/10)
          if Math.random() < trapProb
            a.heading -= Math.PI

    speed = (@temperature+1)/250 # TODO Base this on some turbulence factor!
    a.forward speed
    return true if @_shouldRemovePollution a

    # Now move horizontally based on wind speed, which can be reduced by the patch color (derived
    # from the mask image.) The mask is used to simulate blockage of the airflow by the mountains.
    distance = (@windSpeed / 100) * (1 - a.p.color[0] / 255)
    a.setXY a.x + distance, a.y

    return true if @_shouldRemovePollution a

    # Now move vertically based on temperature. The higher the temp, the more upward motion.
    if not @includeInversionLayer
      a.setXY a.x, a.y + Math.pow(2, (@temperature-130)/20)
      @_resetHeading a

    return false

  _resetHeading: (a)->
    if a.y <= 20
      a.heading = u.randomFloat2(Math.PI/4, Math.PI*3/4)
    else if a.y >= 340
      a.heading = u.randomFloat2(-Math.PI/4, -Math.PI*3/4)

  _shouldRemovePollution: (a)->
    return (a.x < @world.minX + 1 or a.x > @world.maxX - 1 or a.y < @world.minY + 1 or a.y > @world.maxX - 1)

  _killPollutionOnPatch: (p)->
    for a in p.agentsHere()
      if a? and (a.breed is @primary or a.breed is @secondary)
        a.die()

  setRainRate: (@rainRate) ->
    @nextRainEnd = 0
    @checkForRain(@rainRate is 6)

  checkForRain: (force=false) ->
    if @anim.ticks > @nextRainEnd or force
      @nextRainStart = @anim.ticks + u.randomInt(300) + 1800 - (@rainRate*300)
      if force then @nextRainStart = @anim.ticks + 10

      @nextRainEnd =  u.randomInt(130) + (30 * @rainRate)
      @nextRainEnd += if @raining then @anim.ticks else @nextRainStart

    @startRain() if @anim.ticks is @nextRainStart
    @stopRain() if @anim.ticks is @nextRainEnd

  moveRain: ->
    if @raining
      for r in @rain
        continue if r.hidden
        for p in @patches.patchRect(r.p, 3, 3, true)
          @_killPollutionOnPatch p
        r.forward 2
        if r.y > @rainMax
          r.setXY r.x, @rainMax

  startRain: ->
    return if @raining

    for r in @rain
      r.hidden = false

    @raining = true
    @nextRainStart = 0

  stopRain: ->
    return unless @raining

    for r in @rain
      r.hidden = true

    @raining = false
    @nextRainEnd = 0

  _convertPollutionOnPatch: (p)->
    converted = false
    for a in p.agentsHere()
      if a? and a.breed is @primary
        if u.randomInt(4) is 0             # 25% of the time generate a new secondary
          p.sprout 1, @secondary, (_a)->
            _a.heading = Math.PI/2
        else                              # else simply convert to secondary
          newA = a.changeBreed(@secondary)[0]
          newA.heading = a.heading
        converted = true
    return converted

  setSunlight: (amount) ->
    @sunlightAmount = amount

  moveAndEmitSunlight: ->
    interval = 21 - (@sunlightAmount * 2)
    interval = 30 if @raining
    if @anim.ticks % interval is 0
      @sunlight.create 1, (s)=>
        [x,y] = @randomLocationFromNWCorner()
        s.setXY x, y

    toKill = []
    for s in @sunlight
      converted = false
      for p in @patches.patchRect(s.p, 2, 2, true)
        converted ||= @_convertPollutionOnPatch p

      if converted or s.x + 2 > @world.maxX or s.x - 2 < @world.minX or s.y - 2 < @world.minY
        toKill.push s
      else
        s.forward 2

    for s in toKill
      s.die()

  randomLocationFromNWCorner: ->
    loc = u.randomInt (@world.width + @world.height - @landY)
    if loc < @world.width
      return [loc, @world.maxY]
    else
      return [2, (@landY + loc - @world.width)]

  pollute: ->
    for c in @cars
      if c? and !c.hidden
        if ABM.util.randomInt(3000) < @carPollutionRate and ABM.util.randomInt(100) > @electricCarPercentage
            @primary.create 1, (p)=>
              x = if c.heading is 0 then c.x-37 else c.x+37
              p.moveTo @patches.patchXY x, c.y-10

    for f in @factories
      if f? and !f.hidden
        if ABM.util.randomInt(2500) < @factoryPollutionRate
          @primary.create 1, (p)=>
            offset = @FACTORY_POLLUTION_SPAWN_OFFSETS[ABM.util.randomInt(@FACTORY_POLLUTION_SPAWN_OFFSETS.length)]
            p.moveTo @patches.patchXY f.x + Math.round(offset.x * f.size), f.y + Math.round(offset.y * f.size)

  notifyGraphs: ->
    $(document).trigger AirPollutionModel.GRAPH_INTERVAL_ELAPSED

  primaryAQI: ->
    p = @primary.length
    # TODO Better coversion from raw pollutants to AQI
    return p

  secondaryAQI: ->
    p = @secondary.length
    # TODO Better coversion from raw pollutants to AQI
    return p

  _intSpeed: (divisor)->
    speed = @windSpeed/divisor
    return if @windSpeed < 0 then Math.floor(speed) else Math.ceil(speed)

window.AirPollutionModel = AirPollutionModel
