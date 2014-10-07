SKY_TOP_COLOR = [41, 129, 187]
SKY_BTM_COLOR = [188, 230, 251]
SKY_COLOR_CHANGE = [
  SKY_BTM_COLOR[0]-SKY_TOP_COLOR[0],
  SKY_BTM_COLOR[1]-SKY_TOP_COLOR[1],
  SKY_BTM_COLOR[2]-SKY_TOP_COLOR[2],
]
LIGHT_LAND_COLOR = [135, 79, 49]
DARK_LAND_COLOR = [105, 49, 19]
TERRACE_COLOR = [60, 60, 60]

SKY  = "sky"
LAND = "land"

class LandGenerator

  u = ABM.util

  type = "Plain"
  amplitude = -4

  zone1Slope: 0
  zone2Slope: 0

  landPropertyNames: ['direction', 'eroded', 'zone', 'stability', 'quality', 'isTopsoil', 'isTerrace']

  setupLand: ->
    for x in [@patches.minX..@patches.maxX]
      for y in [@patches.minY..@patches.maxY]
        p = @patches.patch x, y
        p.zone = if p.x <= 0 then 1 else 2

        # TODO: memoize landShapeFunction when setting up land?
        if p.y > @landShapeFunction p.x
          p.color = @_calculateSkyColor(p.y)
          p.type = SKY
          # help js engine by making sure all patches have the same fields
          p[property] = null for property in @landPropertyNames
        else
          p.isTopsoil = p.y > @landShapeFunction(p.x) - @INITIAL_TOPSOIL_DEPTH
          p.stability = if p.isTopsoil then 1 else 0.2

          # topsoil and terrace colors will be updated by @updateSurfacePatches
          p.color = DARK_LAND_COLOR
          p.type = LAND
          p.eroded = false
          p.direction = 0
          p.quality = 1

          if type is "Terraced" and p.x < 0 and
           ((p.x % Math.floor(@patches.minX/5) is 0 and p.y > @landShapeFunction (p.x-1)) or
           ((p.x-1) % Math.floor(@patches.minX/5) is 0 and p.y > @landShapeFunction (p.x-2)))
            p.isTerrace = true
            p.color = TERRACE_COLOR
            p.stability = 0.01
          else
            p.isTerrace = false

    @updateSurfacePatches(true)


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

  _calculateSkyColor: (y)->
    # simple linear gradient
    pct = 1-(y-@patches.minY)/(@patches.maxY-@patches.minY)

    result = [
      pct*SKY_COLOR_CHANGE[0] + SKY_TOP_COLOR[0],
      pct*SKY_COLOR_CHANGE[0] + SKY_TOP_COLOR[1],
      pct*SKY_COLOR_CHANGE[0] + SKY_TOP_COLOR[2]
    ]


window.LandGenerator = LandGenerator
