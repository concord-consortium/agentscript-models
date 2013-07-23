class OceanClimateModel extends ClimateModel
  u = ABM.util # static variable
  twoPI = Math.PI * 2
  setup: -> # called by Model ctor
    super

    # remove all existing agents
    while @agents.length
      @agents[@agents.length - 1].die()

    @agentBreeds "vapor"

    @vapor.setDefaultShape "circle"
    @vapor.setDefaultColor [0, 0, 255]

    # globals
    @oceanLeft = -10
    @oceanBottom = -15
    @vaporPerDegree = 0.6
    @nCO2Emission = 0.25

    @oceanAbsorbtionChangable = false
    @useFixedTemperature = false
    @fixedTemperature = 5
    @oceanTemperature = 5
    @oceanTimeConstant = 1 / (10 * @ticksPerYear)
    @oceanZeroAbsorbtionTemp = 20
    @oceanCO2AbsorbtionMax = 1
    @oceanCO2Absorbtion = @oceanCO2AbsorbtionMax

    @earthPatches =        (p for p in @patches when p.y <  @earthTop and p.x < @oceanLeft)
    @oceanPatches =        (p for p in @patches when p.y <  @earthTop and p.x >= @oceanLeft)

    p.color = [255, 200, 200] for p in @earthPatches

    for p in @oceanPatches
      if      p.y == @patches.minY   then p.color = [5, 5, 100]
      else if p.y == @patches.minY+1 then p.color = [10, 10, 150]
      else if p.y  < @patches.minY+4 then p.color = [20, 20, 200]
      else p.color = [30, 30, 240]

    @updateAlbedoOfSurface()
    @createCO2(13)
    @createVapor(5)
    @createHeat(22)
    @draw()

  getVaporCount : ->
    @vapor.length

  getAtmosphereCO2Count : ->
    @CO2.with("o.y > #{@earthTop}").length

  getOceanCO2Count : ->
    @CO2.with("o.y <= #{@earthTop}").length

  updateAlbedoOfSurface: ->
    earthAlbedo = (Math.floor(a+@albedo*100) for a in [96, 155, 96])
    oceanAlbedo = (Math.floor(a+@albedo*200) for a in [0, 0, 220])
    p.color = earthAlbedo for p in @earthSurfacePatches when p.x < @oceanLeft
    p.color = oceanAlbedo for p in @earthSurfacePatches when p.x >= @oceanLeft

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
        if a.y <= @earthTop + 1 and a.x < @oceanLeft    # bounce off land
          a.heading = u.randomFloat2(Math.PI/4, Math.PI*3/4)
        if a.y <= @earthTop + 1 and a.y > @earthTop + 0.9 and a.x >= @oceanLeft    # bounce off sea?
          if @oceanCO2Absorbtion < u.randomFloat 1
            a.heading = Math.PI/2
        if a.y >= @skyTop + 1                           # bounce off sky
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
    while num--
      @vapor.create 1, (a) =>
        a.heading = u.randomCentered(Math.PI)
        a.hidden = unless @hiding90 and Math.random() > 0.1 then false else true
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
    target = Math.max 0, Math.round @temperature * @vaporPerDegree
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
        a.die() if a.heading == -@sunlightHeading && a.y > (14)
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

  updateTemperature: ->
    super
    if @useFixedTemperature
      @temperature = @fixedTemperature
      @oceanTemperature = (1-@oceanTimeConstant) * @oceanTemperature + @oceanTimeConstant * @temperature

  setOceanCO2Absorption: ->
    if @oceanAbsorbtionChangable
      @oceanCO2Absorbtion = (1 - @oceanTemperature / @oceanZeroAbsorbtionTemp) * @oceanCO2AbsorbtionMax

  #
  # Main Model Loop
  #
  step: ->
    super
    @runVapor()

    # less-frequent functions
    if @anim.ticks % 20 is 0
      @emitCO2()
    if @anim.ticks % 30 is 0
      @updateVapor()
      @setOceanCO2Absorption()


window.OceanClimateModel = OceanClimateModel
oceanModelLoaded.resolve()