class ClimateModel extends ABM.Model
  u = ABM.util # static variable
  setup: -> # called by Model ctor
    @anim.ticks = 1
    @refreshPatches = true
    @agentBreeds "sunrays heat IR CO2 clouds"

    @patches.usePixels() # 24fps
    @agents.setUseSprites() # 24->46-48fps
    @anim.setRate 100, true

    # remove all existing agents
    while @agents.length
      @agents[@agents.length - 1].die()

    # globals
    @sunBrightness = 100
    @albedo = 0.3
    @temperature = 5
    @agentSize = 0.75
    @skyTop = (@patches.maxY) - 5
    @earthTop = 8 + @patches.minY
    @sunlightHeading = -1.1
    @numClouds = 0
    @initialYear = new Date().getFullYear()
    @ticksPerYear = 300
    @hiding90 = false
    @showFPS = false

    @agents.setDefaultSize @agentSize
    @agents.setDefaultShape "arrow"
    @sunrays.setDefaultColor [255,255,0]
    @heat.setDefaultShape "circle"
    @IR.setDefaultColor [200, 32, 200]

    @spacePatches =        (p for p in @patches when p.y == @patches.maxY)
    @skyTopPatches =       (p for p in @patches when p.y <  @patches.maxY && p.y > @skyTop)
    @skyPatches =          (p for p in @patches when p.y <= @skyTop && p.y > @earthTop)
    @earthSurfacePatches = (p for p in @patches when p.y == @earthTop)
    @earthPatches =        (p for p in @patches when p.y <  @earthTop)

    p.color = [0, 0, 0] for p in @spacePatches

    for p in @skyTopPatches
      p.color = [196, 196, 196] if p.y == @skyTop + 1
      p.color = [128, 128, 128] if p.y == @skyTop + 2
      p.color = [64, 64, 64]    if p.y == @skyTop + 3
      p.color = [32, 32, 32]    if p.y == @skyTop + 4

    p.color = [100, 150, 255] for p in @skyPatches
    p.color = [255, 200, 200] for p in @earthPatches
    @updateAlbedoOfSurface()
    @createVolcano()
    @createCO2(30)
    @createHeat(20)
    @draw()

  setAlbedo: (percent) ->
    @albedo = percent
    @updateAlbedoOfSurface()

  getAlbedo : ->
    @albedo

  setSunBrightness: (val) ->
    @sunBrightness = val

  getSunBrightness : ->
    @sunBrightness

  getTemperature : ->
    @temperature

  getCO2Count : ->
    @CO2.length

  addCO2: ->
    @createCO2( Math.max 1, Math.round @CO2.length*0.1 )

  subtractCO2: ->
    quant = Math.ceil @CO2.length*0.1
    while quant--
      @CO2.oneOf().die()

  updateAlbedoOfSurface: ->
    p.color = [Math.floor(196 * @albedo), Math.floor(255 * @albedo), Math.floor(196 * @albedo)]   for p in @earthSurfacePatches

  reflectOffHorizontalPlane: (a) ->
    heading = a.heading
    newheading = heading
    if heading > Math.PI
      newheading = Math.PI - (heading - Math.PI)
    if heading < Math.PI
      newheading = Math.PI + (Math.PI - heading)
    else
      newheading = 0
    a.heading = newheading

  headingUp: (a) ->
    heading = a.heading % Math.PI*2
    heading > 0 && heading < Math.PI

  transformToIR: (_a) ->
    a = _a.changeBreed(@IR)[0]
    a.heading = -@sunlightHeading
    # a.heading = u.randomFloat2(2.6, 0.5)
    # a.heading = u.randomCentered(Math.PI/4) + Math.PI/2

  transformToHeat: (_a) ->
    a = _a.changeBreed(@heat)[0]
    a.y = @earthTop-1
    a.heading = u.randomFloat2(-0.5, -Math.PI+0.5)
    a.shape = "circle"
    randomLightness = u.randomInt2(32, 128)
    a.color = [255, randomLightness, randomLightness]

  #
  # CO2
  #
  createCO2: (num, location, heading) ->
    while num--
      @CO2.create 1, (a) =>
        a.size = @agentSize
        a.color = [0, 255, 0]
        a.shape ="pentagon"
        a.heading = if heading? then heading else u.randomCentered(Math.PI)
        [x,y] = if location? then location else @getRandomLocation(@earthTop+1, @skyTop)
        a.setXY x, y

  runCO2: ->
    for a in @CO2
      if a
        a.heading = a.heading + u.randomCentered(Math.PI/9)
        a.forward 0.1
        if a.y <= (-14)
          a.heading = u.randomFloat2(0.1, Math.PI-0.1)
        if a.y <= @earthTop + 1
          a.heading = u.randomFloat2(Math.PI/4, Math.PI*3/4)
        if a.y >= @skyTop + 1
          a.heading = u.randomFloat2(-Math.PI/4, -Math.PI*3/4)

  addCO2Spotlight: ->
    agents = @CO2.getWithProp "hidden", false
    if agents.any()
      a = agents.oneOf()
      @setSpotlight a

  #
  # IR
  #
  runIR: ->
    for a in @IR
      if a
        a.forward 0.5
        if @CO2.inRadius(a, 1).any()
          a.heading = u.randomFloat2(-Math.PI/4, -Math.PI*3/4)
        a.die() if a.heading == -@sunlightHeading && a.y > (14)
        if a.y <= @earthTop
          @transformToHeat(a)

  #
  # Heat
  #
  runHeat: ->
    @updateTemperature()
    for a in @heat
      if a
        a.heading = a.rotate(u.randomCentered(0.3))
        a.forward u.randomFloat2(0.05, 0.2)
        if a.y <= @patches.minY
          a.heading = u.randomFloat2(0.1, Math.PI-0.1)
        if a.y >= @earthTop
          if @returnToSky
            @transformToIR(a)
          else
            a.heading = u.randomCentered(2)

  returnToSky: ->
    u.randomInt(100) < (temperature * 20) && u.randomInt(20) < 2

  updateTemperature: ->
    @temperature = 0.99 * @temperature + 0.01 * (-7 + 0.5 * @heat.length)

  leaveToSpace: (a) ->
    heading = a.heading % Math.PI
    ypos = a.y
    if heading < Math.PI && heading > 0
      if ypos < @patches.minY || ypos >= @patches.maxY
        a.die()

  createHeat: (num) ->
    while num--
      [x,y] = @getRandomLocation(@patches.minY, @earthTop)
      @heat.create 1, (a) =>
        a.heading = u.randomFloat2(-0.5, -Math.PI+0.5)
        randomLightness = u.randomInt2(32, 128)
        a.color = [255, randomLightness, randomLightness]
        a.setXY x, y


  #
  # Clouds
  #
  addCloud: ->
    @numClouds++
    @setupClouds(@numClouds)

  subtractCloud: ->
    @numClouds = Math.max @numClouds-1, 0
    @setupClouds(@numClouds)

  setupClouds: (num) ->
    hiddenClouds = {}
    for a in @clouds
      if a
        if a.hidden then hiddenClouds[a.cloudNum] = true
        a.die()
    numHiddenClouds = Object.keys(hiddenClouds).length
    i = 0
    while i < num
      @makeCloud(i, num, i < numHiddenClouds)
      i++

  hide90Clouds: ->
    cloudsToHide = Math.floor @numClouds * 0.9
    hiddenClouds = {}
    for a in @clouds
      cloudNum = a.cloudNum
      if hiddenClouds[cloudNum] or Object.keys(hiddenClouds).length < cloudsToHide
        a.hidden = true
        hiddenClouds[cloudNum] = true

  makeCloud: (cloudNum, total, hidden) ->
    width = @skyTop - @earthTop
    mid = (@skyTop + @earthTop)/2
    y = mid + width * ((cloudNum/total) - 0.3) - 2
    y = 6 if cloudNum == 0
    x = 2 * u.randomFloat(@patches.maxX) + @patches.minX
    cloudParts = 3 + u.randomInt(16)
    while cloudParts--
      @clouds.create 1, (a) =>
        a.cloudNum = cloudNum
        a.color = [255,255,255]
        a.size = @agentSize + 0.5 + u.randomFloat(1)
        a.shape = "circle"
        a.heading = 0
        a.hidden = hidden
        a.setXY x + u.randomFloat(5) - 4,  y + (u.randomFloat(u.randomFloat(3)))

  runClouds: ->
    for a in @clouds
      if a
        a.forward 0.3 * (0.1 + (3 + a.cloudNum) / 10)

  #
  # Sunshine
  #
  runSunshine: ->
    for a in @sunrays
      if a
        a.forward 0.5
        @leaveToSpace(a)
    @createSunshine()
    @reflectSunshineFromClouds()
    @encounterEarth()

  reflectSunshineFromClouds: ->
    for a in @sunrays
      if a
        if @clouds.inRadius(a, 1).any()
          heading = u.randomFloat2(Math.PI/4, Math.PI*3/4)
          if @headingUp a
            heading = -heading
          a.heading = heading

  encounterEarth: ->
    for a in @sunrays
      if a? and a.y <= @earthTop
        if @albedo * 100 > u.randomInt(100)
          @reflectOffHorizontalPlane(a)
        else
          @transformToHeat(a)

  createSunshine: ->
    modelWidth = @patches.maxX - @patches.minX
    if 0.1 * @sunBrightness > u.randomInt(50)
      @sunrays.create 1, (a) =>
        a.heading = @sunlightHeading
        a.setXY @patches.minX + u.randomFloat(modelWidth), @patches.maxY
        a.hidden = unless @hiding90 and Math.random() > 0.1 then false else true

  addSunraySpotlight: ->
    # try to add spotlight to a sunray at very top heading downwards
    foundOne = false
    for a in @sunrays.shuffle()
      if not @headingUp(a) and a.y > @patches.maxY-5 and not a.hidden
        foundOne = true
        @setSpotlight a
        break
    if not foundOne
      # if we did not find one, add spotlight to random VISIBLE sunray
      agents = @sunrays.getWithProp "hidden", false
      if agents.any()
        a = agents.oneOf()
        @setSpotlight a

  #
  # Volcano
  #
  createVolcano: ->
    @agents.create 1, (a) =>
      a.size = 7
      a.color = [188, 140, 56]
      a.shape ="triangle"
      a.heading = Math.PI / 2
      a.setXY -17, -3
    @agents.create 1, (a) =>
      a.size = 3
      a.color = [255, 255, 255]
      a.shape ="triangle"
      a.heading = Math.PI / 2
      a.setXY -17, -1
    @agents.create 1, (a) =>
      a.size = 6
      a.color = [100, 150, 255]
      a.shape ="circle"
      a.setXY -17, 1

  erupt: ->
    for i in [0...15]
      @createCO2 1, [-17, -1.5], Math.PI/2

  #
  # Global Functions
  #
  hide90: ->
    @hiding90 = true
    for agentSet in [@sunrays, @CO2, @IR, @heat]
      for a in agentSet[Math.ceil(agentSet.length/10)..]
        a.hidden = true unless a is @spotlightAgent

    # have to do clouds seperately
    @hide90Clouds()

  showAll: ->
    @hiding90 = false
    for a in @agents
      a.hidden = false

  getRandomLocation: (minY, maxY) ->
    [
      u.randomFloat2 @patches.minX, @patches.maxX
      u.randomFloat2 minY, maxY
    ]

  getYear: ->
    return Math.floor @initialYear + @anim.ticks / @ticksPerYear

  #
  # Main Model Loop
  #
  step: ->
    @runSunshine()
    @runClouds()
    @runHeat()
    @runIR()
    @runCO2()

window.ClimateModel = ClimateModel

# this is a bit of a hack, to allow the page to know when this
# script has been loaded and parsed by coffeescript.
# it would be good to work out a better way to do this
modelLoaded.resolve()