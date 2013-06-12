class WaterModel extends ABM.Model
  setup: ->
    @showFPS = true
    @setCacheAgentsHere()

    # init all the patches as sky color
    for p in @patches
      p.color = [205, 237, 252]
      p.type = "sky"

    @draw()
    @refreshPatches = false

  step: ->
    if @ticks % 2 == 1
      @agents.create 10, (a)=>
        a.shape = "circle"
        a.color = [0,0,255]
        a.breed = "falling-water"
        a.size = 1
        a.y = @patches.maxY
        a.x = @random(@patches.maxX - @patches.minX) + @patches.minX
        a.heading = ABM.util.degToRad(270)

    @moveFallingWater()

  isOnSurface: (p)->
    return p.type is not "sky" and p.n4[0].type is "sky"

  getNextPatch: (a)->
    dir = Math.round(ABM.util.radToDeg(a.heading))
    return switch dir
      when 0   then a.p.n4[2]
      when 90  then a.p.n4[3]
      when 180 then a.p.n4[1]
      when 270 then a.p.n4[0]
      else a.p.n4[2]

  isPatchFree: (p)->
    return p.agentsHere().length == 0

  resistance: (p)->
    # 1/resistance is the prob of moving, it is like a resistance to flow
    return switch p.type
      when "soil"  then (if @isOnSurface(p) then  2 else 2)
      when "rock1" then (if @isOnSurface(p) then  4 else 8)
      when "rock2" then (if @isOnSurface(p) then  8 else 18)
      when "rock3" then (if @isOnSurface(p) then 16 else 26)
      when "rock4" then (if @isOnSurface(p) then 32 else 1000000)
      else 1

  random: (n)->
    return Math.floor(Math.random()*n)

  moveFallingWater: ->
    for a in @agents.breed("falling-water")
      # TODO evaporation

      # only move water that's not at the bottom of the model
      if a.y > @patches.minY
        if @isOnSurface(a.p)
          # you reach here if the dot is in the surface. Now move it, giving preference for motion within the surface
          if @random(@resistance(a.p)) == 0
            a.heading = ABM.util.degToRad(90 * @random(4))
            nextPatch = @getNextPatch(a)
            if @isPatchFree(nextPatch)
              if nextPatch.type is "sky" and a.heading != ABM.util.degToRad(270)
                # move to the free patch
                a.moveTo(nextPatch)
              else if isOnSurface(nextPatch)
                a.forward 1
              else if @random(Math.round(@resistance(nextPatch)/@resistance(a.p))) == 0
                a.forward 1
        else
          # you get here is the dot is NOT in the surface layer (and not on the bottom), so it can be rain or in the rock
          a.heading = ABM.util.degToRad(270)
          nextPatch = @getNextPatch(a)
          if @isPatchFree(nextPatch)
            # you get here if there are no dots on the patch ahead
            if nextPatch.type is "sky"
              a.forward 1
            else
              a.heading = if @random(2) == 0 then 0 else ABM.util.degToRad(180)
              possSkyPatch = @getNextPatch(a)
              if possSkyPatch.type is "sky"
                a.forward 1
                # bubble upward
                # a.heading = ABM.util.degToRad(90)
                # while not @isPatchFree(a.p)
                #   a.forward 1
              else if @random(@resistance(nextPatch)) == 0
                a.heading = ABM.util.degToRad(180 + @random(181))
                a.forward 1
          else
            # you get here if there are dots on the patch ahead, so the dot cannot move forward
            a.heading = if @random(2) == 0 then 0 else ABM.util.degToRad(180)
            nextPatch = @getNextPatch(a)
            if @isPatchFree(nextPatch)
              if nextPatch.type is "sky"
                a.moveTo(nextPatch)
              else if @random(@resistance(nextPatch)) == 0
                a.moveTo(nextPatch)

APP=new WaterModel "layers", 3, -124, 124, -40, 40, true
APP.setRootVars()