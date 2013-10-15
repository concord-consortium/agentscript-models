class WaterModel extends ABM.Model
  DOWN:  ABM.util.degToRad(270)
  LEFT:  ABM.util.degToRad(180)
  UP:    ABM.util.degToRad(90)
  CONE:  ABM.util.degToRad(110)
  RIGHT: 0

  template: null
  templateData: { url: null, data: null }

  ticksPerYear: 730

  evapProbability: 10
  rainProbability: 0.33

  setup: ->
    @anim.setRate 30, false
    @setFastPatches()

    # init all the patches as sky color
    # unless we have a template to load
    if @template? and @template isnt ""
      loadData = (data)=>
        ImportExport.import(@, data)
      if @templateData[@template]?
        loadData(@templateData[@template])
      else
        # load in the defined template json
        $.getJSON(@template, (data)=>
          @templateData[@template] = data
          loadData(data)
        ).fail =>
          @_clear()
    else
     @_clear()

    @setCacheAgentsHere()

    @agentBreeds "rain evap"

    @setupRain()
    @setupEvap()

    @draw()
    @refreshPatches = false

  _clear: ->
    for p in @patches
      p.color = [205, 237, 252]
      p.type = "sky"

  reset: ->
    super
    @setup()
    @anim.draw()

  start: ->
    super
    for p in @patches
      p.isOnSurface = @isOnSurface(p)
      p.isOnAirSurface = @isOnAirSurface(p)

  step: ->
    console.log @anim.toString() if @anim.ticks % 100 is 0

    @createRain()

    for r in @rain
      @moveFallingWater(r)

    for e in @evap
      @moveEvaporation(e)

    @evaporateWater()

    return true # avoid inadventently returning a large array of things

  setupRain: ->
    @rain.setDefault "size", 2/@world.size  # try to keep water around 2px in size
    @rain.setDefault "color", [0, 0, 255]
    @rain.setDefault "shape", "circle"
    @rain.setDefault "heading", @DOWN

  setupEvap: ->
    @evap.setDefault "size", 2/@world.size  # try to keep water around 2px in size
    @evap.setDefault "color", [0, 255, 0]
    @evap.setDefault "shape", "circle"
    @evap.setDefault "heading", @UP

  createRain: ->
    # too many agents will make it really slow
    if @rain.length < 8000 && (@anim.ticks % @ticksPerYear) < (@rainProbability * @ticksPerYear)
      @rain.create 5, (a)=>
        p = null
        while not @isPatchFree(p)
          px = @random(@patches.maxX - @patches.minX) + @patches.minX
          p = @patches.patchXY px, @patches.maxY
        a.moveTo p

  isOnSurface: (p)->
    # The first patch of a layer is the "surface".
    # We are the surface if the patch immediately above or diagonally above isn't the same type.
    # However, don't use surface dynamics if we're under an impermeable layer (rock4).
    isSurface = (p.type isnt p.n[6]?.type and p.n[6]?.type isnt "rock4") or
           (p.type isnt p.n[5]?.type and p.n4[5]?.type isnt "rock4") or
           (p.type isnt p.n[7]?.type and p.n4[7]?.type isnt "rock4")

    return isSurface

  isOnAirSurface: (p)->
    # Patches with an air patch directly or diagonally above is on the "air surface".
    # This is used to decide whether water is eligible for evaporation
    isFirstRockLayer = p.type isnt "sky" and
                (p.n[5]?.type is "sky" or
                 p.n[6]?.type is "sky" or
                 p.n[7]?.type is "sky")
    isLastSkyLayer = p.type is "sky" and
                (p.n[0]?.type isnt "sky" or
                 p.n[1]?.type isnt "sky" or
                 p.n[2]?.type isnt "sky")

    return isFirstRockLayer or isLastSkyLayer

  getNextPatch: (a)->
    dir = Math.round(ABM.util.radToDeg(a.heading))
    return switch dir
      when 0   then a.p.n4[2]
      when 90  then a.p.n4[3]
      when 180 then a.p.n4[1]
      when 270 then a.p.n4[0]
      else a.p.n4[0]

  isPatchFree: (p)->
    return p? and p.agentsHere().length == 0

  resistance: (p)->
    # 1/resistance is the prob of moving, it is like a resistance to flow.
    # If the patch is the top patch of a layer, resist water flow more than usual to
    # encourage travel along layer surfaces.
    return switch p.type
      when "soil"  then (if p.isOnSurface then  32 else   4)
      when "rock1" then (if p.isOnSurface then  64 else   8)
      when "rock2" then (if p.isOnSurface then 128 else  16)
      when "rock3" then (if p.isOnSurface then 256 else  32)
      when "rock4" then 1000000
      else 1

  random: (n)->
    return Math.floor(Math.random()*n)

  moveFallingWater: (a)->
    ps = []
    resistanceModifier = 1
    for i in [{ idx: 1, priority: 0 }, { idx: 0, priority: 1}, { idx: 2, priority: 1}, { idx: 3, priority: 2}, {idx: 4, priority: 2}]
      i.patch = a.p.n[i.idx]
      continue unless i.patch?
      continue unless @isPatchFree(i.patch)

      preferred = false
      i.priority += 1 unless i.patch.type is "sky"
      # if the patch to the right is occupied, bump up either of the left patches in priority and preference
      if (i.idx == 3 or i.idx == 2) and not @isPatchFree(a.p.n[4])
        i.priority -= 1
        resistanceModifier = 0.2
        preferred = true
        a.heading = @LEFT
      # if the patch to the left is occupied, bump up either of the right patches in priority and preference
      else if (i.idx == 4 or i.idx == 0) and not @isPatchFree(a.p.n[3])
        i.priority -= 1
        resistanceModifier = 0.2
        preferred = true
        a.heading = @RIGHT

      if @random(Math.round(@resistance(i.patch)*resistanceModifier)) == 0
        ps[i.priority] ||= []
        ps[i.priority].push i
        ps[i.priority].push {patch: i.patch} if preferred
        ps[i.priority].push {patch: i.patch} if preferred

    n = -1
    while not destinations? and n++ < 5
      destinations = ps[n]

    if destinations?
      # if one is the direction we're heading, chose it. Otherwise, randomly select.
      dests = []
      for d in destinations
        if ABM.util.inCone a.heading, @CONE, 2, a.x, a.y, d.patch.x, d.patch.y
          dests.push d

      if dests.length == 0
        dests = destinations
      dest = destinations[@random(dests.length)]
      if dest?
        a.moveTo dest.patch
        return true

    return false

  evaporateWater: ->
    for a in @rain
      if a? and a.p.isOnAirSurface and @random(10000) < @evapProbability
        # move to the surface of any pools of water
        nextP = a.p.n4[3]
        while nextP? and nextP.agentsHere().length > 0
          nextP = nextP.n4[3]

        @evap.setBreed a
        a.moveTo nextP if nextP?

  moveEvaporation: (a)->
    return unless a?
    a.heading = ABM.util.degToRad(@random(90)+45)
    if a.y+1 > @world.maxY
      a.die()
      return

    # keep agents within the left-right bounds of the model
    if (a.heading > @UP and a.x-1 < @world.minX) or
       (a.heading < @UP and a.x+1 > @world.maxX)
      a.heading = @UP + (@UP - a.heading)

    a.forward 1

  addRainSpotlight: ->
    # try to add spotlight to a raindrop at very top
    foundOne = false
    for a in @rain
      if a? and a.y > @patches.maxY-5
        foundOne = true
        @setSpotlight a
        break
    if not foundOne
      # if we did not find one, add spotlight to random raindrop
      a = @rain.oneOf()
      @setSpotlight a

  removeSpotlight: ->
    @setSpotlight null

  setTemplate: (str)->
    @template = str
    @reset()

window.WaterModel = WaterModel
