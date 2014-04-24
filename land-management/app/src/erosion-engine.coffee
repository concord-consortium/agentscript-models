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
      y-- while @patches.patch(x, y).type is SKY and y > @patches.minY
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

    signOf = (x) -> if x is 0 then 1 else Math.round x / Math.abs(x)

    for p, i in @surfaceLand

      localSlope = @getLocalSlope p.x, p.y
      slopeContribution = Math.min(1, 2 * Math.abs localSlope)

      vegetation = @getLocalVegetation p.x, p.y
      totalVegetationSize = 0
      totalVegetationSize += (if a.isBody then a.size/3 else if a.isRoot then a.size*2/3 else a.size) for a in vegetation
      vegetationContribution = 0.2 + 0.8 * (1 - Math.min(1, totalVegetationSize / 2))

      precipitationContribution  = @precipitation / 500

      probabilityOfErosion = 0.1 * slopeContribution * vegetationContribution * precipitationContribution * p.stability

      continue if u.randomFloat(1) > probabilityOfErosion

      p.direction = signOf -localSlope

      # remember, indices into p.n relative to patch p (in the center of the below diagram):
      # 5  6  7
      # 3  -  4
      # 0  1  2

      if p.x is @patches.minX and p.direction is -1 or p.x is @patches.maxX and p.direction is 1
        # We're moving off the edge, so disappear (no target)
        target = null
      else if p.n[1+p.direction]?.type is SKY
        # move downward and in the previous lateral direction
        target = p.n[1+p.direction]
      else if p.n[1-p.direction]?.type is SKY
        # move downward and laterally in the opposite of the previous lateral direction
        target = p.n[1-p.direction]
        #p.direction = -p.direction
      else if p.n[3.5+(p.direction/2)]?.type is SKY
        # move horizontally in the previous lateral direction
        target = p.n[3.5+(p.direction/2)]
      else if p.n[3.5-(p.direction/2)]?.type is SKY
        # move horizontally in the opposite of the previous lateral direction
        target = p.n[3.5-(p.direction/2)]
        #p.direction = -p.direction
      else
        # We're stuck! Don't change at all.
        p.direction = 0
        continue

      # count erosion in zones -- note this is not the same as the target's
      # origin zone (it's color), but where is it *currently* eroding from.
      if p.x <= 0 then @zone1ErosionCount++ else @zone2ErosionCount++

      if target?
        target = target.n[1] while target.n[1]?.type is SKY
        @swapSkyAndLand target, p
        target.eroded = true

      # make sure p becomes sky, whether target exists or not
      p.type = SKY
      p.color = SKY_COLOR

      # Now, look UP from the patch p (which is now sky) and see if we left a land patch "hanging"
      # above a sky patch. (All land patches are settled on terra firma after each iteration of
      # this loop, so we need to look upward no more than 1 patch.)
      @swapSkyAndLand p, p.n[6] if p.n[6]?.type is LAND

  swapSkyAndLand: (sky, land) ->
    for property in ['direction', 'eroded', 'type', 'color', 'zone', 'stability', 'quality', 'isTopsoil', 'isTerrace']
      [land[property], sky[property]] = [sky[property], land[property]]
    null

  getBoxAroundPoint: (x, y, xStep, yStep) ->
    xStep = 3
    yStep = 5

    # Minimize edge effects by making sure to sample a window of width 2*xStep
    if x - xStep < @patches.minX
      leftEdge = @patches.minX
      rightEdge = leftEdge + 2 * xStep
    else if x + xStep > @patches.maxX
      rightEdge = @patches.maxX
      leftEdge = rightEdge - 2 * xStep
    else
      leftEdge  = x - xStep
      rightEdge = x + xStep

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
