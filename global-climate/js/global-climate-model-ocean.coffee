class OceanClimateModel extends ClimateModel
  u = ABM.util # static variable

  oceanContour = [
    [0.0000, 1.0000]
    [0.0107, 0.7392]
    [0.0243, 0.4431]
    [0.1002, 0.1827]
    [0.1698, 0.0187]
    [0.1888, 0.0000]
  ]

  twoPI = Math.PI * 2

  includeVapor: true
  nCO2Emission: 0.25
  vaporPerDegreeModifier: 10

  oceanLeft: -10
  oceanBottom: -15

  constructor: ->
    @contextsInit.gases = {z: 3, ctx: "2d"}
    super

  setup: -> # called by Model ctor
    super

    # remove all existing agents
    while @agents.length
      @agents[@agents.length - 1].die()

    # make sure to clear out any co2 from the ocean floor
    @_clearCtx @contexts.gases

    @agentBreeds "vapor"

    @vapor.setDefaultShape "circle"
    @vapor.setDefaultColor [0, 0, 255]

    # globals
    @oceanAlbedo = @albedo
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

  _clearCtx: (ctx) ->
    ctx.save()
    ctx.setTransform(1, 0, 0, 1, 0, 0)
    ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height)
    ctx.restore()

  backgroundImageUrls: ['img/earth.png', 'img/ground.png', 'img/sky.png', 'img/ocean.png']

  draw: ->
    super
    @drawIceSheet()

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
      ctx.drawImage @images['img/sky.png'], left, yMin,  width, yMax - yMin
      ctx.drawImage @images['img/earth.png'], left, yMax - (@earthTop - yMin),  width, @earthTop - yMin

      ctx.save()
      ctx.beginPath()
      ctx.moveTo left,  -@earthTop - 1
      ctx.lineTo @oceanLeft + 0.2, -@earthTop - 1
      ctx.lineTo @oceanLeft + 0.2, -@earthTop + 1
      ctx.lineTo left,  -@earthTop + 1
      ctx.clip()

      # The 'ground.png' image wouldn't stretch from edge to edge in Safari until I moved the left
      # coordinate by 0.5 and increased the width by 1:
      ctx.drawImage @images['img/ground.png'], left - 0.5, -@earthTop - 1, width + 1, 2
      ctx.restore()

      ctx.drawImage @images['img/ocean.png'], @oceanLeft, -@earthTop - 0.7, right - @oceanLeft, @earthTop  + 0.7 - yMin
      ctx.restore()

  oceanBoundaryAndNormalAngleAt: (y) ->
    # bottom left corner of ocean is at [@oceanLeft, yMin]
    # width is:  right - @oceanLeft
    # height is: @earthTop + 0.7 - yMin

    # oceanContour[i] = [x, y]
    # where x = fraction of width
    #       y = fraction of height

    yMin = @patches.minY
    xMin = @patches.minX
    width  = @patches.maxX - @oceanLeft
    height = @earthTop - yMin
    # scaled
    py = (y - yMin) / height

    return [xMin, 0] if py <= 0 or py >= 1

    for coords, i in oceanContour
      break if coords[1] < py

    [px0, py0] = oceanContour[i]
    xLeft = px0 * width + @oceanLeft

    if i is 0
      return [xLeft, Math.PI*3/2]
    else
      [px1, py1] = oceanContour[i-1]

      dx = (px0 - px1) * width
      dy = (py0 - py1) * height

      t = Math.atan2(dy, dx)

      return [xLeft, t]

  setOceanAlbedo: (percent) ->
    @oceanAlbedo = percent
    @updateAlbedoOfSurface()

  getOceanAlbedo : ->
    @oceanAlbedo

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
    oceanAlbedo = (Math.min(Math.floor(a+@oceanAlbedo*120),255) for a in [0, 0, 220])
    p.color = earthAlbedo for p in @earthSurfacePatches when p.x < @oceanLeft
    p.color = oceanAlbedo for p in @earthSurfacePatches when p.x >= @oceanLeft

    l = @iceLeft @icePercent
    r = @iceRight @icePercent

    # NOTA BENE: Although these patches are not visible, it's important to change the color because
    # the sunlight reflection is determined by the color of the patches. (AgentScript more or less
    # inentionally encourages using color to represent model properties.)
    p.color = [255, 255, 255] for p in @earthSurfacePatches when p.x <= l or p.x >= r

    @draw()

  iceLeft:  (p) -> @patches.minX - 0.5 + p * (@oceanLeft - @patches.minX + 0.5)
  iceRight: (p) -> @patches.maxX + 0.5 - p * (@patches.maxX - @oceanLeft + 0.5)

  #
  # Ice
  #
  getIcePercent: ->
    @icePercent

  setIcePercent: (p) ->
    @icePercent = p
    @updateAlbedoOfSurface()

  # Draw the "ice sheet" that meets up with the iceberg graphic, onto the agents layer. (This method
  # is called by the overridden @draw() method so that Agentscript doesn't draw over the ice sheet.)
  drawIceSheet: ->
    @icebergImage ||= document.getElementById "iceberg-sprite"

    return unless @icebergImage?

    scale = 0.03

    # height of the left (or right) edge of the iceberg relative to its maximum height
    edgeHeightFraction = 0.822

    # The height of the edge of the iceberg in the units used by agents canvas context
    height = scale * edgeHeightFraction * @icebergImage.height

    # y coordinate of the top of the edge of the iceberg
    y = -@earthTop - 1.3
    sheetY = scale * (1 - edgeHeightFraction) * @icebergImage.height + y

    # The width of the iceberg graphic
    width = scale * @icebergImage.width

    ctx = @contexts.agents

    ctx.save()
    ctx.scale 1, -1

    # match the color gradient of the SVG source of the iceberg graphic
    grd = ctx.createLinearGradient 0, sheetY + height, 0, sheetY
    grd.addColorStop 0,     "#CAE8E6"
    grd.addColorStop 0.069, "#D9EFED"
    grd.addColorStop 0.179, "#EAF6F5"
    grd.addColorStop 0.314, "#F6FBFB"
    grd.addColorStop 0.502, "#FDFEFE"
    grd.addColorStop 1,     "#FFFFFF"
    ctx.fillStyle = grd

    leftEdgePatchX  = Math.floor @iceLeft(@icePercent || 0)
    rightEdgePatchX = Math.ceil  @iceRight(@icePercent || 0)

    if rightEdgePatchX - leftEdgePatchX <= 1
      # If ice patches completely cover the earth surface, draw a continuous ice sheet with no
      # iceberg graphic; this is less visually confusing than the alrernative.
      ctx.fillRect @patches.minX - 0.5, sheetY, @patches.maxX - @patches.minX + 1, height
      ctx.restore()
    else
       # The 0.2 adjustment ensures that there's a little overlap between the "glacier"/"ice sheet"
       # and the iceberg graphic it joins up with. Without the overlap, there's a little bit of
       # flickering.
      l = @patches.minX - 0.5
      ctx.fillRect l, sheetY, @iceLeft(@icePercent) - width - l + 0.2, height
      l = @iceRight(@icePercent) + width - 0.2
      ctx.fillRect l, sheetY, @patches.maxX + 0.5 - l, height
      ctx.restore()

      ctx.save()
      ctx.translate @iceLeft(@icePercent), -y
      ctx.scale -scale, -scale
      ctx.drawImage @icebergImage, 0, 0
      ctx.restore()

      ctx.save()
      ctx.translate @iceRight(@icePercent), -y
      ctx.scale scale, -scale
      ctx.drawImage @icebergImage, 0, 0
      ctx.restore()

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
        else if a.y <= @earthTop + 0.9 and a.x < @oceanLeft  # we're in the ground somehow
          if @earthTop+0.9 - a.y < a.x - @patches.minX
            a.heading = Math.PI/2
          else
            a.heading = Math.PI
        else if a.y <= @earthTop - 2 and a.x >= @oceanLeft
          [actualOceanLeft, normal] = @oceanBoundaryAndNormalAngleAt a.y
          if a.x < actualOceanLeft
            # "bounce" off land-ocean boundary
            a.heading = u.randomFloat2 normal, normal + Math.PI/4
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
  # Sunlight
  #

  encounterEarth: ->
    for a in @sunrays
      if a? and a.y <= @earthTop
        if ("#{a.p.color}" is "#{[255,255,255]}" and @iceAlbedo * 100 > u.randomInt(100)) or  # if ice
           (a.x >= @oceanLeft and @oceanAlbedo * 100 > u.randomInt(100)) or                   # or ocean
           (a.x < @oceanLeft and @albedo * 100 > u.randomInt(100))                            # or land
          @reflectOffHorizontalPlane(a)
        else
          @transformToHeat(a)

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
          # bounce it off the surface, but not as a perfect reflection.
          # use a weighted random, preferring to head straight up.
          while a.heading < Math.PI/3 or a.heading > Math.PI*2/3
            a.heading = u.randomNormal(Math.PI/2, Math.PI)
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
          if @IREmits
            a.heading = u.randomFloat2(0, Math.PI*2)
          else
            a.heading = u.randomFloat2(-Math.PI/4, -Math.PI*3/4)
        if a.y > (14)
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
    if show then $(@contexts.gases.canvas).show() else $(@contexts.gases.canvas).hide()

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
