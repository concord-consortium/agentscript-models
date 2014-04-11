SKY_COLOR = [131, 216, 240]

LIGHT_LAND_COLOR = [135, 79, 49]
DARK_LAND_COLOR = [105, 49, 19]
TERRACE_COLOR = [60, 60, 60]

GOOD_SOIL_COLOR = [88, 41, 10]
POOR_SOIL_COLOR = [193, 114, 7]

MAGENTA = [255, 0, 255]
ORANGE = [255, 127, 0]

SKY  = "sky"
LAND = "land"

class ErosionEngine

  u = ABM.util

  climateData = {
    temperate: {
      precipitation: [22, 26, 43, 73, 108, 115, 89, 93, 95, 58, 36, 27]
    },
    tropical: {
      precipitation: [200, 290, 380, 360, 280, 120, 80, 40, 30, 30, 70, 100]
    },
    arid: {
      precipitation: [11.4, 13.2, 23.5, 8.8, 14.8, 34.1, 133.1, 120.2, 47, 7.8, 7.7, 6.8]
    }
  }
  climate = climateData.temperate
  userPrecipitation = 166

  precipitation: 0

  erosionProbability = 30
  maxSlope = 2 # necessary?
  showErosion: true

  zone1ErosionCount: 0
  zone2ErosionCount: 0

  showSoilQuality: false

  findSurfaceLandPatches: ->
    surfaceLand = []
    for x in [@patches.minX..@patches.maxX]
      y = @patches.maxY
      y-- while @patches.patch(x, y).type is SKY
      surfaceLand.push @patches.patch x, y

    surfaceLand

  # Called every tick to modify colors of surface-most INITIAL_TOPSOIL_DEPTH patches.
  # (A reasonable assumption is made that the patches that change during a tick are no more than
  # INITIAL_TOPSOIL_DEPTH deeper the land-sky boundary. Hower, we must process at least that depth
  # because the land generator relies on this method for the initial setup of the topsoil patches.)
  updateSurfacePatches: ->
    @surfaceLand = @findSurfaceLandPatches()

    for surfacePatch in @surfaceLand
      [x, y] = [surfacePatch.x, surfacePatch.y]

      for i in [0...@INITIAL_TOPSOIL_DEPTH]
        p = @patches.patch x, y - i
        newColor =
          if p.isTerrace
            TERRACE_COLOR
          else if p.isTopsoil
            if @showErosion and p.eroded
              if p.zone is 1 then ORANGE else MAGENTA
            else if @showSoilQuality
              zone = if p.x <= 0 then 0 else 1
              if p.quality < @soilQuality[zone] then p.quality += 0.001
              if p.quality > @soilQuality[zone] then p.quality -= 0.001

              if p.quality < 0.5
                POOR_SOIL_COLOR
              else if p.quality > 1.5
                GOOD_SOIL_COLOR
              else
                LIGHT_LAND_COLOR
            else
              LIGHT_LAND_COLOR
        if newColor? then p.color = newColor

  erode: ->
    # Find and sort the surface patches most exposed to the sky
    for p in @surfaceLand
      p.skyCount = 0
      p.skyCount++ for n in p.n when n?.type is SKY
      p.skyCount += 3 if p.y is @patches.maxY

    @surfaceLand.sort (a,b) ->
      return if a.skyCount <= b.skyCount then 1 else -1

    # Take the top 25% of most exposed soil patches and erode them
    for i in [0...@surfaceLand.length/2] by 1
      p = @surfaceLand[i]

      localSlope = @getLocalSlope p.x, p.y
      slopeContribution = 0.35 * Math.abs(localSlope/2)
      vegetation = @getLocalVegetation p.x, p.y
      totalVegetationSize = 0
      totalVegetationSize += (if a.isBody then a.size/3 else if a.isRoot then a.size*2/3 else a.size) for a in vegetation
      vegetationStoppingPower = Math.min totalVegetationSize/5, 0.99
      vegetiationContribution = 0.65 * (1 - vegetationStoppingPower)
      localErosionProbability = erosionProbability / p.stability
      probabilityOfErosion = localErosionProbability * (@precipitation/400) * (slopeContribution + vegetiationContribution)

      if (u.randomFloat(100) > probabilityOfErosion) then continue

      # pick a random direction first, then check
      # bottom corners, then sides for a patch of sky
      direction = p.direction or direction = 1 - (u.randomInt(2) * 2)

      # remember, indices into p.n relative to patch p (in the center of the below diagram):
      # 5  6  7
      # 3  -  4
      # 0  1  2

      if p.x is @patches.minX and direction is -1 or p.x is @patches.maxX and direction is 1
        # We're moving off the edge, so disappear (no target)
        target = null
      else if p.n[1+direction]?.type is SKY
        # move downward and in the previous lateral direction
        target = p.n[1+direction]
      else if p.n[1-direction]?.type is SKY
        # move downward and laterally in the opposite of the previous lateral direction
        target = p.n[1-direction]
        direction = direction * -1
      else if p.n[3.5+(direction/2)]?.type is SKY
        # move horizontally in the previous lateral direction
        target = p.n[3.5+(direction/2)]
      else if p.n[3.5-(direction/2)]?.type is SKY
        # move horizontally in the opposite of the previous lateral direction
        target = p.n[3.5-(direction/2)]
        direction = direction * -1
      else
        # We're stuck! Don't change at all.
        p.direction = 0
        continue

      # count erosion in zones -- note this is not the same as the target's
      # origin zone (it's color), but where is it *currently* eroding from.
      if p.x < 0 then @zone1ErosionCount++ else @zone2ErosionCount++

      # become sky
      p.type = SKY
      p.color = SKY_COLOR
      p.eroded = false

      # unless we're disappearing off the edge, "move" to target by making target a clone of p
      if target?
       # first, check below target to make sure it drops down to solid ground
        while target.n[1].type is SKY
          target = target.n[1]

        # 'move' p to target by cloning the land-related properties of p
        target.type = LAND
        target.eroded = true
        target[property] = p[property] for property in ['direction', 'zone', 'stability', 'quality', 'isTopsoil', 'isTerrace']



  getBoxAroundPoint: (x, y, xStep, yStep) ->
    xStep = 3
    yStep = 5

    leftEdge  = Math.max x-xStep, @patches.minX
    rightEdge = Math.min x+xStep, @patches.maxX
    top       = Math.min y+yStep, @patches.maxY
    bottom    = Math.max y-yStep, @patches.minY
    [leftEdge, rightEdge, top, bottom]


  getLocalSlope: (x, y) ->
    [leftEdge, rightEdge, top, bottom] = @getBoxAroundPoint x, y, 3, 5

    leftHeight  = bottom
    rightHeight = bottom

    while leftHeight < top and @patches.patch(leftEdge, leftHeight).type is LAND
      leftHeight++

    while rightHeight < top and @patches.patch(rightEdge, rightHeight).type is LAND
      rightHeight++

    slope = (rightHeight - leftHeight) / (rightEdge - leftEdge)

  getLocalVegetation: (x, y) ->
    [leftEdge, rightEdge, top, bottom] = @getBoxAroundPoint x, y, 5, 5

    vegetation = []

    for x in [leftEdge..rightEdge]
      for y in [bottom..top]
        vegetation.push.apply vegetation, @patches.patch(x,y).agents

    vegetation

  resetErosionCounts: ->
    @zone1ErosionCount = 0
    @zone2ErosionCount = 0

  setClimate: (c) ->
    climate = if c isnt "user" then climateData[c] else null
    @updatePrecipitation()

  setUserPrecipitation: (p) ->
    userPrecipitation = p
    @precipitation = userPrecipitation unless climate?

  updatePrecipitation: ->
    if climate
      @precipitation = climate.precipitation[@month]
    else
      @precipitation = userPrecipitation

  getCurrentClimateData: ->
    if climate
      climate.precipitation
    else
      return (userPrecipitation for i in [0...12])

window.ErosionEngine = ErosionEngine
