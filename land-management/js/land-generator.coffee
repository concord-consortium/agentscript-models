SKY_COLOR = [131, 216, 240]
LIGHT_LAND_COLOR = [135, 79, 49]
DARK_LAND_COLOR = [105, 49, 19]
TERRACE_COLOR = [60, 60, 60]

SKY  = "sky"
LAND = "land"

MAX_INTERESTING_SOIL_DEPTH = 2

class LandGenerator

  u = ABM.util

  type = "Plain"
  amplitude = -4

  zone1Slope: 0
  zone2Slope: 0

  setupLand: ->

    @skyPatches = []
    @landPatches = []

    for p in @patches
      p.zone = if p.x <= 0 then 1 else 2
      if p.y > @landShapeFunction p.x
        p.color = SKY_COLOR
        p.type = SKY
        p.depth = -1
        @skyPatches.push p
      else
        p.color = DARK_LAND_COLOR
        p.type = LAND
        p.depth = MAX_INTERESTING_SOIL_DEPTH
        p.eroded = false
        p.erosionDirection = 0
        p.stability = 1
        p.quality = 1
        @landPatches.push p

        if type is "Terraced" and p.x < 0 and
         ((p.x % Math.floor(@patches.minX/5) is 0 and p.y > @landShapeFunction (p.x-1)) or
         ((p.x-1) % Math.floor(@patches.minX/5) is 0 and p.y > @landShapeFunction (p.x-2)))
          p.isTerrace = true
          p.color = TERRACE_COLOR
          p.stability = 100

    @setSoilDepths()


  setLandType: (t) ->
    type = t
    switch type
      when "Nearly Flat"  then amplitude = -0.00001
      when "Plain"        then amplitude = -4
      when "Rolling"      then amplitude = -10
      when "Hilly"        then amplitude = -20
      else                     amplitude = 0

  landShapeFunction: (x) ->
    if type is "Terraced"
      modelHeight = @patches.maxY - @patches.minY
      if x < 0
        step = Math.floor (x+1) / (@patches.minX/5)
        @patches.minY + modelHeight * (0.6 - (0.1*step))
      else
        -25 * Math.sin( u.degToRad(x - 20) ) - 1
    else if type is "Sliders"
      slope = if x < 0 then @zone1Slope else @zone2Slope
      slope /= 10
      midHeight = if (@zone1Slope > 3 and @zone2Slope < -3) then 6 # yes, ugly...
      else if (@zone1Slope > 2 or @zone2Slope < -2) then 0 
      else if (@zone1Slope < -3 and @zone2Slope > 3) then -22 
      else if (@zone1Slope < -2 or @zone2Slope > 2) then -15 
      else -12
      val = x * slope + midHeight
      Math.min @patches.maxY, Math.max @patches.minY, val
    else
      amplitude * Math.sin( u.degToRad(x - 10) )

window.LandGenerator = LandGenerator