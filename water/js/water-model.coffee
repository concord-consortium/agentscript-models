class WaterModel extends ABM.Model
  DOWN:  ABM.util.degToRad(270)
  LEFT:  ABM.util.degToRad(180)
  UP:    ABM.util.degToRad(90)
  CONE:  ABM.util.degToRad(110)
  RIGHT: 0
  setup: ->
    @anim.setRate 30, false

    # init all the patches as sky color
    for p in @patches
      p.color = [205, 237, 252]
      p.type = "sky"

    @setCacheAgentsHere()
    @draw()
    @refreshPatches = false

  reset: ->
    super
    @setup()
    @anim.draw()

  start: ->
    super
    for p in @patches
      p.isOnSurface = @isOnSurface(p)

  step: ->
    console.log @anim.toString() if @anim.ticks % 100 is 0
    # too many agents will make it really slow
    if @agents.length < 8000
      @agents.create 5, (a)=>
        a.shape = "circle"
        a.color = [0,0,255]
        a.breed = "falling-water"
        a.size = 1
        p = null
        while not @isPatchFree(p)
          px = @random(@patches.maxX - @patches.minX) + @patches.minX
          p = @patches.patchXY px, @patches.maxY
        a.moveTo p
        a.heading = @DOWN

    for a in @agents
      @moveFallingWater(a)
    return true # avoid inadventently returning a large array of things

  isOnSurface: (p)->
    # The first patch of a layer is the "surface".
    # We are the surface if the patch immediately above or diagonally above isn't the same type.
    # However, don't use surface dynamics if we're under an impermeable layer (rock4).
    isSurface = (p.type isnt p.n[6]?.type and p.n[6]?.type isnt "rock4") or
           (p.type isnt p.n[5]?.type and p.n4[5]?.type isnt "rock4") or
           (p.type isnt p.n[7]?.type and p.n4[7]?.type isnt "rock4")

    return isSurface

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
    for i in [{ idx: 1, priority: 0 }, { idx: 0, priority: 1}, { idx: 2, priority: 1}, { idx: 3, priority: 2}, {idx: 4, priority: 2}]
      i.patch = a.p.n[i.idx]
      continue unless i.patch?
      i.resistance = @resistance(i.patch)
      i.priority += 1 unless i.patch.type is "sky"
      if i.idx == 3 and not @isPatchFree(a.p.n[4])
        i.priority -= 1
      else if i.idx == 4 and not @isPatchFree(a.p.n[3])
        i.priority -= 1
      if @isPatchFree(i.patch) and @random(i.resistance) == 0
        ps[i.priority] ||= []
        ps[i.priority].push i

    n = -1
    while not destinations? and n++ < 5
      destinations = ps[n]

    if destinations?
      dest = destinations[@random(destinations.length)]
      if dest?
        a.moveTo dest.patch
        return true

    return false

APP=new WaterModel "layers", 2, -200, 199, -65, 64, false
APP.setRootVars()