class AirPollutionAerial extends ABM.Model
  u = ABM.util # static variables

  setup: ->
    @refreshPatches = false
    @showFPS = false

    @agentCap = 1000
    @factoryLimit = 4

    @patches.importColors "img/map-mask.png" # draws patches based on on the number of patches created when the model is initialized
    @patches.importDrawing "img/map.png" # draws the smoothly rendered image on top of the interpreted patches

    @windSpeedEast  = 0
    @windSpeedNorth = 0

    # remove all existing agents
    while @agents.length
      @agents[@agents.length - 1].die()

    @agentBreeds "factories smoke"

    @factories.setDefaultShape "circle"
    @factories.setDefaultColor [20,100,90]
    @factories.setDefaultSize 3

    @smoke.setDefaultShape "circle"
    @smoke.setDefaultColor [82,98,114]
    @smoke.setDefaultSize 0.4

    # bounding boxes of cities A, B, and C
    @aLimits = minX: 105, maxX: 123, minY: 80, maxY: 88
    @bLimits = minX:  88, maxX: 100, minY: 33, maxY: 38
    @cLimits = minX:  23, maxX:  35, minY: 16, maxY: 25

    @aQuality = 100
    @bQuality = 100
    @cQuality = 100

    @draw()

  step: ->
    @createSmoke()
    @moveSmoke()
    if @anim.ticks % 5 is 0
      @capAgents()
    if @anim.ticks % 20 is 0
      @calculateAirPollution()

  createSmoke: ->
    for f in @factories
      @smoke.create 3, (a) =>
        a.moveTo f
        a.heading = u.randomCentered(Math.PI/2) + Math.PI

  moveSmoke: ->
    for a in @smoke when a isnt undefined
      # first add random eccenticity
      a.heading = a.heading + u.randomCentered(Math.PI/2)
      a.forward 0.1
      # now check where wind will take us
      windSpeedScale = 1# 255 / a.p.color[0]
      [newX, newY] = [a.x+(@windSpeedEast*windSpeedScale), a.y+(@windSpeedNorth*windSpeedScale)]
      if @patches.minX > newX or newX >= @patches.maxX or
          @patches.minY > newY or newY >= @patches.maxY
        a.die()
      else
        newPatch = @patches.patch newX, newY
        if a.p.color[0] <= (newPatch.color[0]+5) && newPatch.agentsHere().length < 3
          a.setXY newX, newY

  # ensures we don't have too many agents slowing down model
  capAgents: ->
    while @smoke.length > @agentCap
      # kill the first smoke, as this will be the eldest and will
      # essentially have just disapated
      @smoke[0].die()

  setWindSpeed: (@windSpeedEast, @windSpeedNorth) ->

  addFactoryTo: (patch) ->
    if @factories.length < @factoryLimit
      patch.sprout 1, @factories
      @draw()

  calculateAirPollution: ->
    aPollution = 0
    bPollution = 0
    cPollution = 0

    for a in @smoke
      if @aLimits.minX < a.x < @aLimits.maxX and  @aLimits.minY < a.y < @aLimits.maxY
        aPollution++
      else if @bLimits.minX < a.x < @bLimits.maxX and  @bLimits.minY < a.y < @bLimits.maxY
        bPollution++
      else if @cLimits.minX < a.x < @cLimits.maxX and  @cLimits.minY < a.y < @cLimits.maxY
        cPollution++

    # rough emprirical adjustment for city sizes
    bPollution *= 1/0.5
    cPollution *= 1/0.7

    @aQuality = Math.max 100-aPollution, 0
    @bQuality = Math.max 100-bPollution, 0
    @cQuality = Math.max 100-cPollution, 0

window.AirPollutionAerial = AirPollutionAerial

modelLoaded.resolve()