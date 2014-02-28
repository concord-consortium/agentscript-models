class ClimateModel extends ABM.Model

  u = ABM.util

  setup: -> # called by Model ctor
    @anim.ticks = 1
    @refreshPatches = true
    @agentBreeds "sunrays heat IR CO2 clouds factories volcanoes"


    @setFastPatches()
    @anim.setRate 100, true

    # remove all existing agents
    while @agents.length
      @agents[@agents.length - 1].die()

    # globals
    @sunBrightness = 70
    @albedo = 0.4
    @iceAlbedo = 0.95
    @temperature = 6
    @temperaturePerHeat = 0.2
    @agentSize = 0.75
    @skyTop = (@patches.maxY) - 5
    @earthTop = 8 + @patches.minY
    @sunlightHeading = -1.1
    @numClouds = 0
    @initialYear = new Date().getFullYear()
    @ticksPerYear = 300
    @hiding90 = false
    @hidingRays = false
    @hidingGases = false
    @hidingHeat = false
    @showFPS = false
    @humanEmissionRate = 0
    @numFactories = 0

    # import images
    @setCacheAgentsHere()
    factoryImg = document.getElementById('factory-sprite')
    ABM.shapes.add "factory", false, (ctx) ->
      ctx.scale -0.1, 0.1
      ctx.rotate Math.PI
      ctx.drawImage factoryImg, 0, 0

    volcanoImg = document.getElementById('volcano-sprite')
    if volcanoImg then ABM.shapes.add "volcano", false, (ctx) ->
      ctx.scale -0.1, 0.1
      ctx.rotate Math.PI
      ctx.drawImage volcanoImg, 0, 0

    cloudImg = document.getElementById 'cloud-sprite-1'
    if cloudImg then  ABM.shapes.add "cloud", false, (ctx) ->
      ctx.scale -0.1, 0.1
      ctx.rotate Math.PI
      ctx.drawImage cloudImg, 0, 0

    # set default agent shapes
    @agents.setDefaultSize @agentSize
    @agents.setDefaultShape "arrow"
    @sunrays.setDefaultColor [255,255,0]
    @heat.setDefaultShape "circle"
    @IR.setDefaultColor [200, 32, 200]
    @factories.setDefaultShape "factory"
    @factories.setDefaultColor [0,0,0]
    @factories.setDefaultSize 1

    @volcanoes.setDefaultShape "volcano"
    @volcanoes.setDefaultColor [0,0,0]
    @volcanoes.setDefaultSize 1

    @skyPatches =          (p for p in @patches when p.y > @earthTop)
    @earthSurfacePatches = (p for p in @patches when p.y == @earthTop)
    @earthPatches =        (p for p in @patches when p.y <  @earthTop)

    @drawBackgroundImages()

    @createVolcano()
    @createCO2(13)
    @createHeat(15)

    @draw()

  loadBackgroundImages: ->
    @images = []
    @backgroundImageUrls.map (url) =>
      dfd = $.Deferred()
      u.importImage url, (img) =>
        @images[url] = img
        dfd.resolve img
      dfd

  backgroundImageUrls: ['img/earth.svg', 'img/ground.svg', 'img/sky.svg']

  drawBackgroundImages: ->
    $.when(@loadBackgroundImages()...).then =>
      ctx = ABM.drawing
      p = ABM.patches
      left = p.minX - 0.5
      right = p.maxX + 0.5
      width = right - left
      # the only sensible way to understand these are as min/max; yMin is the top
      yMin = p.minY - 0.5
      yMax = p.maxY + 0.5

      ctx.save()
      ctx.scale 1, -1
      ctx.drawImage @images['img/sky.svg'], left, yMin,  width, yMax - yMin
      ctx.drawImage @images['img/earth.svg'], left, yMax - (@earthTop - yMin),  width, @earthTop - yMin
      # The 'ground.svg' image wouldn't stretch from edge to edge in Safari until I moved the left
      # coordinate by 0.5 and increased the width by 1:
      ctx.drawImage @images['img/ground.svg'], left - 0.5, -@earthTop - 1, width + 1, 2
      ctx.restore()

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
    @setSpotlight a if _a is @spotlightAgent
    a.heading = -@sunlightHeading
    a.hidden = unless @hidingRays or (@hiding90 and Math.random() > 0.1) then false else true
    # a.heading = u.randomFloat2(2.6, 0.5)
    # a.heading = u.randomCentered(Math.PI/4) + Math.PI/2

  transformToHeat: (_a) ->
    a = _a.changeBreed(@heat)[0]
    @setSpotlight a if _a is @spotlightAgent
    a.y = @earthTop-1
    a.heading = u.randomFloat2(-0.5, -Math.PI+0.5)
    a.shape = "circle"
    randomLightness = u.randomInt2(32, 128)
    a.color = [255, randomLightness, randomLightness]
    a.hidden = unless @hidingHeat or (@hiding90 and Math.random() > 0.1) then false else true

  #
  # CO2
  #
  createCO2: (num, location, heading) ->
    while num--
      @CO2.create 1, (a) =>
        a.size = @agentSize
        a.color = [0, 255, 0]
        a.shape = "pentagon"
        a.heading = if heading? then heading else u.randomCentered(Math.PI)
        [x,y] = if location? then location else @getRandomLocation(@earthTop+1, @skyTop)
        a.setXY x, y
        a.hidden = unless @hidingGases then false else true

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
    agents = @CO2.getPropWith "hidden", false
    if agents.any()
      a = agents.oneOf()
      @setSpotlight a

  removeSpotlight: ->
    @setSpotlight null

  #
  # IR
  #
  runIR: ->
    for a in @IR
      if a
        a.forward 0.5
        if @CO2.inRadius(a, 1).any()
          a.heading = u.randomFloat2(-Math.PI/4, -Math.PI*3/4)
        if a.heading == -@sunlightHeading && a.y > (14)
          a.die()
          @setSpotlight null if a is @spotlightAgent
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
    @temperature = 0.99 * @temperature + 0.01 * (1 + @temperaturePerHeat * @heat.length)

  leaveToSpace: (a) ->
    heading = a.heading % Math.PI
    ypos = a.y
    if heading < Math.PI && heading > 0
      if ypos < @patches.minY || ypos >= @patches.maxY
        a.die()
        @setSpotlight null if a is @spotlightAgent

  createHeat: (num) ->
    while num--
      [x,y] = @getRandomLocation(@patches.minY, @earthTop)
      @heat.create 1, (a) =>
        a.heading = u.randomFloat2(-0.5, -Math.PI+0.5)
        randomLightness = u.randomInt2(32, 128)
        a.color = [255, randomLightness, randomLightness]
        a.setXY x, y
        a.hidden = unless @hidingHeat or (@hiding90 and Math.random() > 0.1) then false else true


  #
  # Clouds
  #
  addCloud: ->
    @numClouds++
    @makeCloud @numClouds-1, @numClouds, false

  subtractCloud: ->
    return if @numClouds is 0
    @numClouds--
    for a in @clouds by -1
      if a.cloudNum is @numClouds then a.die()

  setupClouds: (num) ->
    hiddenClouds = {}
    while @clouds.length
      a = @agents.last()
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
    mid = (@skyTop + @earthTop) / 2
    y = if cloudNum is 0 then 6 else mid + width * (cloudNum / total - 0.3) - 2
    x = 2 * u.randomFloat(@patches.maxX) + @patches.minX
    @clouds.create 1, (a) =>
      a.cloudNum = cloudNum
      a.shape = "cloud"
      a.heading = 0
      a.hidden = hidden
      a.setXY x + u.randomFloat(5) - 4,  y + u.randomFloat(u.randomFloat(3))

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
        if "#{a.p.color}" is "#{[255,255,255]}" and @iceAlbedo * 100 > u.randomInt(100)  # if ice
          @reflectOffHorizontalPlane(a)
        else if @albedo * 100 > u.randomInt(100)
          @reflectOffHorizontalPlane(a)
        else
          @transformToHeat(a)

  createSunshine: ->
    modelWidth = @patches.maxX - @patches.minX
    if 0.1 * @sunBrightness > u.randomInt(50)
      @sunrays.create 1, (a) =>
        a.heading = @sunlightHeading
        a.setXY @patches.minX + u.randomFloat(modelWidth), @patches.maxY
        a.hidden = unless @hidingRays or (@hiding90 and Math.random() > 0.1) then false else true

  addSunraySpotlight: ->
    # try to add spotlight to a sunray at very top heading downwards
    foundOne = false
    for a in @sunrays
      if not @headingUp(a) and a.y > @patches.maxY-5 and not a.hidden
        foundOne = true
        @setSpotlight a
        break
    if not foundOne
      # if we did not find one, add spotlight to random VISIBLE sunray
      agents = @sunrays.getPropWith "hidden", false
      if agents.any()
        a = agents.oneOf()
        @setSpotlight a

  #
  # Volcano
  #
  createVolcano: ->
    @volcanoes.create 1, (a) =>
      a.shape = "volcano"
      a.setXY -23.5, -1

  erupt: ->
    for i in [0...15]
      @createCO2 1, [-17, -1.5], Math.PI/2

  #
  # HumanEmissions (Factories)
  #
  setHumanEmissionRate: (r) ->
    @humanEmissionRate = r
    if r >= 0.1
      @setNumFactories 1
    else @setNumFactories 0

  getHumanEmissionRate: ->
    @humanEmissionRate

  setNumFactories: (n) ->
    return if n is @numFactories

    while n < @numFactories
      @factories[0].die()
      @numFactories--

    if n > @numFactories
      while @factories.length
        @factories.last().die()

      @numFactories = n

      while n--
        @factories.create 1, (a) =>
          a.setXY 8 / (0.5 * n + 1) - 28, @earthTop + 9.6
          a.size = 1 / (0.5 * n + 1)

    @draw()

  runPollution: ->
    emissionStep = Math.floor 1/(@humanEmissionRate/30)+30    # 0.5 = 90 steps, 1.0 = 60 steps
    if @anim.ticks % emissionStep is 0
      @emitPollution()

  emitPollution: ->
    @createCO2 1, [-15, @earthTop+8], Math.PI/2

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
    for agentSet in [@sunrays, @IR]
      for a in agentSet
        a.hidden = @hidingRays
    for a in @CO2
      a.hidden = @hidingGases
    for a in @heat
      a.hidden = @hidingHeat

  showRays: (show) ->
    @hidingRays = !show
    for agentSet in [@sunrays, @IR]
      for a in agentSet
        a.hidden = @hidingRays

  showGases: (show) ->
    @hidingGases = !show
    for a in @CO2
      a.hidden = @hidingGases

  showHeat: (show) ->
    @hidingHeat = !show
    for a in @heat
      a.hidden = @hidingHeat


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
    @runPollution()

window.ClimateModel = ClimateModel

# This Coffeescript may be compiled and executed async, and the images used by the model are loaded
# async. When we get here the Coffescript is ready, so once the images finish loading, resolve the
# jQuery deferred object that lets the page know that the model is ready to be instantiated and set
# up.
imagesLoaded = $('#sprites img').map (img) ->
  dfd = $.Deferred()
  if this.width > 0 and this.height > 0
    dfd.resolve()
  else
    this.onload = -> dfd.resolve()
  dfd

$.when(imagesLoaded...).done -> modelLoaded.resolve()
