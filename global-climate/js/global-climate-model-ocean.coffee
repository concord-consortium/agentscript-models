class OceanClimateModel extends ClimateModel
  u = ABM.util # static variable
  twoPI = Math.PI * 2

  includeVapor: true
  nCO2Emission: 0.25
  vaporPerDegreeModifier: 10

  oceanLeft: -10
  oceanBottom: -15

  setup: -> # called by Model ctor
    super

    # remove all existing agents
    while @agents.length
      @agents[@agents.length - 1].die()

    @agentBreeds "vapor"

    @vapor.setDefaultShape "circle"
    @vapor.setDefaultColor [0, 0, 255]

    # globals
    @temperature = 5
    @oceanLeft = -10
    @oceanBottom = -15

    @cloudsFormedByVapor = false
    @numCloudsPerVapor = 0.3

    @iceFormedByTemperature = false
    @icePercent = 0
    @zeroIceTemp = 10
    @maxIceTemp = -2

    @oceanAbsorbtionChangable = false
    @useFixedTemperature = false
    @fixedTemperature = 5
    @oceanTemperature = 5
    @oceanTimeConstant = 1 / (1 * @ticksPerYear)
    @oceanZeroAbsorbtionTemp = 20
    @oceanCO2AbsorbtionMax = 1
    @oceanCO2Absorbtion = @oceanCO2AbsorbtionMax

    @updateAlbedoOfSurface()
    @createCO2(13)
    @createVapor(5) if @includeVapor
    @createHeat(23)
    @draw()

  backgroundImageUrls: ['img/earth.svg', 'img/ground.svg', 'img/sky.svg', 'img/ocean.png']

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

      ctx.save()
      ctx.beginPath()
      ctx.moveTo left,  -@earthTop - 1
      ctx.lineTo @oceanLeft + 0.2, -@earthTop - 1
      ctx.lineTo @oceanLeft + 0.2, -@earthTop + 1
      ctx.lineTo left,  -@earthTop + 1
      ctx.clip()

      # The 'ground.svg' image wouldn't stretch from edge to edge in Safari until I moved the left
      # coordinate by 0.5 and increased the width by 1:
      ctx.drawImage @images['img/ground.svg'], left - 0.5, -@earthTop - 1, width + 1, 2
      ctx.restore()

      ctx.drawImage @images['img/ocean.png'], @oceanLeft, yMax - (@earthTop - yMin) - 0.7,  width - @oceanLeft, @earthTop - yMin + 0.7
      ctx.restore()

  setIncludeWaterVapor: (b) ->
    @includeVapor = b
    if not @includeVapor
      while @vapor.length
        @vapor[@vapor.length - 1].die()

  getVaporCount : ->
    @vapor.length

  getAtmosphereCO2Count : ->
    @CO2.with("o.y > #{@earthTop}").length

  getOceanCO2Count : ->
    @CO2.with("o.y <= #{@earthTop}").length

  updateAlbedoOfSurface: ->
    earthAlbedo = (Math.min(Math.floor(a+@albedo*120),255) for a in [96, 155, 96])
    oceanAlbedo = (Math.min(Math.floor(a+@albedo*120),255) for a in [0, 0, 220])
    p.color = earthAlbedo for p in @earthSurfacePatches when p.x < @oceanLeft
    p.color = oceanAlbedo for p in @earthSurfacePatches when p.x >= @oceanLeft

    if @icePercent
      iceLeft  = @patches.minX - (@patches.minX - @oceanLeft) * @icePercent
      iceRight = @patches.maxX - (@patches.maxX - @oceanLeft) * @icePercent
      p.color = [255, 255, 255] for p in @earthSurfacePatches when p.x < iceLeft or p.x >= iceRight

    @draw()

  #
  # Ice
  #
  getIcePercent: ->
    @icePercent

  setIcePercent: (p) ->
    @icePercent = p
    @updateAlbedoOfSurface()

  updateIce: (p) ->
    return unless @iceFormedByTemperature

    targetPercent = 1 - (@temperature - @maxIceTemp) / (@zeroIceTemp - @maxIceTemp)
    @setIcePercent(targetPercent)

  #
  # CO2
  #
  runCO2: ->
    for a in @CO2
      if a
        a.heading = a.heading + u.randomCentered(Math.PI/9)
        if a.y <= @oceanBottom                          # stop at bottom of ocean
          a.stamp()
          a.die()
          return
        if a.y <= @earthTop + 1 and a.x < @oceanLeft    # bounce off land
          a.heading = u.randomFloat2(Math.PI/4, Math.PI*3/4)
        else if a.y <= @earthTop + 1 and a.y > @earthTop + 0.9 and a.x >= @oceanLeft    # bounce off sea?
          if @oceanCO2Absorbtion < u.randomFloat 1
            a.heading = Math.PI/2
        else if a.y >= @skyTop + 1                           # bounce off sky
          a.heading = u.randomFloat2(-Math.PI/4, -Math.PI*3/4)

        a.forward 0.1

  emitCO2: ->
    # pick a random patch from the surface
    random = Math.floor(Math.random() * @earthSurfacePatches.length)
    surfacePatch = @earthSurfacePatches[random]

    # if its on the earth
    if surfacePatch.x < @oceanLeft
      for n in [0...3]       # loop 3 times
        if @nCO2Emission > Math.random()*3
          @createCO2 1, [surfacePatch.x, surfacePatch.y+1], Math.PI/2



  #
  # Water vapor
  #
  createVapor: (num) ->
    if not @includeVapor then return
    while num--
      @vapor.create 1, (a) =>
        a.heading = u.randomCentered(Math.PI)
        a.hidden = unless @hidingGases or (@hiding90 and Math.random() > 0.1) then false else true
        [x,y] = @getRandomLocation(@earthTop+1, @skyTop)
        a.setXY x, y

  runVapor: ->
    for a in @vapor
      if a
        a.heading = a.heading + u.randomCentered(Math.PI/9)
        a.forward 0.1
        if a.y <= (-14)
          a.heading = u.randomFloat2(0.1, Math.PI-0.1)
        if a.y <= @earthTop + 1
          a.die()
        if a.y >= @skyTop + 1
          a.heading = u.randomFloat2(-Math.PI/4, -Math.PI*3/4)

  # Adds or removes water vapor based on temp
  updateVapor: ->
    ## original NLogo formula, with @vaporPerDegree = 0.6
    #target = Math.max 0, Math.round @temperature * @vaporPerDegree
    ## new log function to prevent vapor getting too high and causing too much pos feedback
    target = Math.round((Math.log(@temperature+4)*@vaporPerDegreeModifier)-(@vaporPerDegreeModifier/5*7))
    target = Math.max 0, target
    count  = @getVaporCount()

    if count > target
      for i in [count-1..target]
        @vapor[i].die()
    else
      @createVapor target-count


  #
  # IR
  #
  runIR: ->
    for a in @IR
      if a
        a.forward 0.5
        if @CO2.inRadius(a, 1).any() or @vapor.inRadius(a, 1).any()
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
    for a, i in @heat
      if a
        # random walk
        a.rotate(u.randomCentered(0.3))

        # rotate towards north
        if i%2
          heading = @normalize a.heading
          if heading > Math.PI and heading < Math.PI * 1.5
            heading -= Math.PI/50
          else if heading > Math.PI * 1.5 and heading < twoPI
            heading += Math.PI/50
          a.heading = heading

        a.forward u.randomFloat2(0.05, 0.2)
        if a.y <= @patches.minY
          a.heading = u.randomFloat2(0.1, Math.PI-0.1)
        if a.y >= @earthTop
          if @returnToSky
            @transformToIR(a)
          else
            a.heading = u.randomCentered(2)

  returnToSky: ->
    u.randomInt(100) < (temperature * 20)

  #
  # Volcano
  #
  createVolcano: ->
    # no volcano

  #
  # Global Functions
  #
  hide90: ->
    super
    for agentSet in [@vapor]
      for a in agentSet[Math.ceil(agentSet.length/10)..]
        a.hidden = true

  showAll: ->
    super
    for a in @vapor
      a.hidden = @hidingGases

  showGases: (show) ->
    @hidingGases = !show
    for agentSet in [@CO2, @vapor]
      for a in agentSet
        a.hidden = @hidingGases

  # normalizes an angle to [0,2PI)
  # this would be useful to be in agentset
  normalize: (angle) ->
    ((angle%twoPI) + twoPI) % twoPI

  #
  # Functions for model where user can set temperature
  #

  setOceanAbsorbtionChangable: (b) ->
    @oceanAbsorbtionChangable = b

  setUseFixedTemperature: (b) ->
    @useFixedTemperature = b

  setFixedTemperature: (t) ->
    @fixedTemperature = t
    @updateTemperature()

  updateTemperature: ->
    super
    if @useFixedTemperature
      @temperature = @fixedTemperature
    @oceanTemperature = (1-@oceanTimeConstant) * @oceanTemperature + @oceanTimeConstant * @temperature

  setOceanCO2Absorption: ->
    if @oceanAbsorbtionChangable
      @oceanCO2Absorbtion = (1 - @oceanTemperature / @oceanZeroAbsorbtionTemp) * @oceanCO2AbsorbtionMax

  #
  # Cloud updating from vapor
  #
  updateClouds: ->
    return unless @cloudsFormedByVapor

    target = Math.round @vapor.length * @numCloudsPerVapor

    while target > @numClouds
      @addCloud()

    while target < @numClouds
      @subtractCloud()

  #
  # Main Model Loop
  #
  step: ->
    super
    @runVapor()

    # less-frequent functions
    if @anim.ticks % 20 is 0
      @emitCO2()
    if @anim.ticks % 40 is 0
      @updateVapor()
      @setOceanCO2Absorption()
    if @anim.ticks % 100 is 0
      @updateClouds()
      @updateIce()


window.OceanClimateModel = OceanClimateModel
oceanModelLoaded.resolve()