class AirPollutionModel extends ABM.Model
  @GRAPH_INTERVAL_ELAPSED: 'graph-interval-lapsed'

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

  mountainsX: 410
  oceanX: 120
  rainMax: 310
  sunX: 91
  sunY: 349

  graphSampleInterval: 10

  windSpeed: 0
  numCars: 10
  numFactories: 5
  factoryDensity: 5
  carPollutionRate: 10
  carElectricRate: 25
  factoryPollutionRate: 5
  raining: false
  temperature: 50

  setup: ->
    @anim.setRate 30, false
    @setFastPatches()
    @patches.usePixels true
    @setTextParams {name: "drawing"}, "10px sans-serif"
    @setLabelParams {name: "drawing"}, [255,255,255], [0,-20]

    @patches.importColors "img/air-pollution-bg-mask.png"
    @patches.importDrawing "img/air-pollution-bg.png"

    @setCacheAgentsHere()

    carImg = document.getElementById('car-sprite')
    factoryImg = document.getElementById('factory-sprite')
    cloudImg = document.getElementById('cloud-sprite')

    ABM.shapes.add "left-car", false, (ctx)=>
      ctx.scale(-1, 1) # if heading leftward...
      ctx.rotate @LEFT
      ctx.drawImage(carImg, 0, 0)
    ABM.shapes.add "right-car", false, (ctx)=>
      ctx.rotate @LEFT
      ctx.drawImage(carImg, 0, 0)
    ABM.shapes.add "factory", false, (ctx)=>
      ctx.scale(-1, 1)
      ctx.rotate @LEFT
      ctx.drawImage(factoryImg, 0, 0)
    ABM.shapes.add "pollutant", false, (ctx)=>
      ctx.arc -0.5, -0.5, 0.5, 0, @PI2, false
      ctx.fill()
      ctx.arc 0.5, -0.5, 0.5, 0, @PI2, false
      ctx.fill()
      ctx.arc 0, 0.5, 0.5, 0, @PI2, false
      ctx.fill()
    ABM.shapes.add "cloud", false, (ctx)=>
      ctx.rotate @LEFT
      ctx.drawImage(cloudImg, 0, 0)

    @CAR_SPAWN = [
      {x: @world.maxX -  45, heading: @LEFT},
      {x: @world.maxX - 404, heading: @RIGHT},
      {x: @world.maxX - 223, heading: @LEFT},
      {x: @world.maxX - 226, heading: @RIGHT},
      {x: @world.maxX - 134, heading: @LEFT},
      {x: @world.maxX - 315, heading: @RIGHT},
      {x: @world.maxX - 312, heading: @LEFT},
      {x: @world.maxX - 137, heading: @RIGHT},
      {x: @world.maxX - 401, heading: @LEFT},
      {x: @world.maxX -  48, heading: @RIGHT}
    ]

    @agentBreeds "wind cars factories primary secondary clouds rain sunlight"

    @setupFactories()
    @setupWind()
    @setupCars()
    @setupPollution()
    @setupRain()
    @setupSunlight()

    @draw()
    @refreshPatches = false

    $(document).trigger 'model-ready'

  reset: ->
    super
    @setup()
    @anim.draw()

  step: ->
    @moveWind()
    @moveCars()
    @movePollution()
    @pollute()

    @moveAndEmitSunlight()
    @moveRainAndClouds()
    @startRain() if @anim.ticks % 600 is 0
    @stopRain() if @raining and @anim.ticks % 600 is 200

    @notifyGraphs() if @anim.ticks % @graphSampleInterval is 0

    return

  setupWind: ->
    @wind.setDefaultSize 5
    @wind.setDefaultColor [0, 0, 255]
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
    @cars.setDefaultHeading @LEFT
    @cars.setDefaultShape "left-car"
    @cars.setDefaultColor [0,0,0]
    @cars.setDefaultHidden true

    @cars.create @numCars, (c)=>
      pos = @CAR_SPAWN[@cars.length - 1]
      c.moveTo @patches.patchXY pos.x, 40
      c.heading = pos.heading
      c.shape = if pos.heading is 0 then 'right-car' else 'left-car'
      c.createTick = @anim.ticks || 0

    @setCars 1

  setupFactories: ->
    @factories.setDefaultSize 1
    @factories.setDefaultHeading @LEFT
    @factories.setDefaultShape "factory"
    @factories.setDefaultColor [0,0,0]
    @factories.setDefaultHidden true

    @factories.create @numFactories, (f)=>
      pos = @FACTORY_SPAWN_POS[@factories.length-1]
      f.moveTo @patches.patchXY pos.x, pos.y
      f.size = pos.size
      f.createTick = @anim.ticks || 0

    @setFactories 1

  setupPollution: ->
    @primary.setDefaultSize 3
    @primary.setDefaultHeading @UP
    @primary.setDefaultShape "pollutant"
    @primary.setDefaultColor [120,30,30]
    @primary.setDefaultHidden false

    @secondary.setDefaultSize 3
    @secondary.setDefaultHeading @UP
    @secondary.setDefaultShape "pollutant"
    @secondary.setDefaultColor [30,120,30]
    @secondary.setDefaultHidden false

  setupRain: ->
    # Create clouds which move left to right, or right to left, depending on wind speed
    @clouds.create 8, (c)=>
      c.heading = 0
      c.size = 1
      c.shape = "cloud"
      c.hidden = false
      x = (@clouds.length-1) * 71 + 1
      y = @world.maxY-1
      c.moveTo @patches.patchXY(x,y)

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
    @sunlight.setDefaultSize 1
    @sunlight.setDefaultHeading @DOWN
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

    for c in @clouds
      c.heading = if @windSpeed >= 0 then 0 else @LEFT

    @draw() if @anim.animStop

  setCars: (n)->
    for i in [0...(@cars.length)]
      c = @cars[i]
      c.hidden = (i >= n)

    @draw() if @anim.animStop

  setFactories: (n)->
    for i in [0...(@factories.length)]
      f = @factories[i]
      f.hidden = (i >= n)

    @draw() if @anim.animStop

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
    for c in @cars
      if (c.x-1) < @oceanX
        c.heading = @RIGHT
        c.shape = "right-car"
        c.x += 37
      else if (c.x+1) >= (@world.maxX-5)
        c.heading = @LEFT
        c.shape = "left-car"
        c.x -= 37
      c.forward 1

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
    # with speed determined by the turbulence of the model.
    a.baseHeading += u.randomCentered(Math.PI/9)
    a.heading = a.baseHeading
    speed = (@temperature+1)/250 # TODO Base this on some turbulence factor!
    a.forward speed
    return true if @_shouldRemovePollution a

    # Now move horizontally based on wind speed
    if @windSpeed < 0
      a.heading = @LEFT
      speed = Math.abs(@windSpeed / 100)
    else if a.x < @mountainsX and @windSpeed > 0
      a.heading = @RIGHT
      speed = Math.abs(@windSpeed / 100)
    a.forward speed
    return true if @_shouldRemovePollution a

    # Now move vertically based on temperature. The higher the temp, the more upward motion.
    a.heading = @UP
    speed = Math.pow(2, (@temperature-130)/20)
    a.forward speed

    @_resetBaseHeading a
    return false

  _resetBaseHeading: (a)->
    if a.y <= 20
      a.baseHeading = u.randomFloat2(Math.PI/4, Math.PI*3/4)
    else if a.y >= 340
      a.baseHeading = u.randomFloat2(-Math.PI/4, -Math.PI*3/4)

  _shouldRemovePollution: (a)->
    return (a.x < @world.minX + 1 or a.x > @world.maxX - 1 or a.y < @world.minY + 1 or a.y > @world.maxX - 1)

  _killPollutionOnPatch: (p)->
    for a in p.agentsHere()
      if a? and (a.breed is @primary or a.breed is @secondary)
        a.die()

  moveRainAndClouds: ->
    for c in @clouds
      continue if c.hidden
      c.forward 1

    if @raining
      for r in @rain
        continue if r.hidden
        for p in @patches.patchRect(r.p, 3, 3, true)
          @_killPollutionOnPatch p
        r.forward 2
        if r.y > @rainMax
          r.setXY r.x, @rainMax

  _convertPollutionOnPatch: (p)->
    converted = false
    for a in p.agentsHere()
      if a? and a.breed is @primary
        newA = a.changeBreed(@secondary)[0]
        newA.baseHeading = a.baseHeading
        converted = true
    return converted

  moveAndEmitSunlight: ->
    interval = if @raining then 20 else 5
    if @anim.ticks % interval is 0
      @sunlight.create 1, (s)=>
        s.setXY @sunX, @sunY
        s.heading = ABM.util.randomFloat2 Math.PI, @PI2

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

  startRain: ->
    for r in @rain
      r.hidden = false
    @raining = true

  stopRain: ->
    for r in @rain
      r.hidden = true
    @raining = false

  pollute: ->
    for c in @cars
      if c? and !c.hidden
        if @carPollutionRate isnt 100 and (@anim.ticks - c.createTick) % @carPollutionRate is 0
          if ABM.util.randomInt(100) > @carElectricRate
            @primary.create 1, (p)=>
              p.baseHeading = p.heading
              x = if c.heading is 0 then c.x-37 else c.x+37
              p.moveTo @patches.patchXY x, c.y-10

    for f in @factories
      if f? and !f.hidden
        if @factoryPollutionRate isnt 100 and (@anim.ticks - f.createTick) % @factoryPollutionRate is 0
          @primary.create 1, (p)=>
            p.baseHeading = p.heading
            offset = @FACTORY_POLLUTION_SPAWN_OFFSETS[ABM.util.randomInt(@FACTORY_POLLUTION_SPAWN_OFFSETS.length)]
            p.moveTo @patches.patchXY f.x + Math.round(offset.x * f.size), f.y + Math.round(offset.y * f.size)

  notifyGraphs: ->
    $(document).trigger AirPollutionModel.GRAPH_INTERVAL_ELAPSED

  primaryAQI: ->
    p = @primary.length
    # TODO Better coversion from raw pollutants to AQI
    return p / 4

  secondaryAQI: ->
    p = @secondary.length
    # TODO Better coversion from raw pollutants to AQI
    return p / 4

  _intSpeed: (divisor)->
    speed = @windSpeed/divisor
    return if @windSpeed < 0 then Math.floor(speed) else Math.ceil(speed)

window.AirPollutionModel = AirPollutionModel
$(document).trigger 'air-pollution-model-loaded'