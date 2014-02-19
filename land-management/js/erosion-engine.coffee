SKY_COLOR = [131, 216, 240]

LIGHT_LAND_COLOR = [135, 79, 49]
DARK_LAND_COLOR = [105, 49, 19]
TERRACE_COLOR = [60, 60, 60]

GOOD_SOIL_COLOR = [88, 41, 10]
POOR_SOIL_COLOR = [193, 114, 7]

MAGENTA = [255, 0, 255]
ORANGE = [255, 127, 0]

MAX_INTERESTING_SOIL_DEPTH = 3

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

  #
  # Set soil depth such that the top of each "column" of soil's depth is 0,
  # the next depth is 1, etc, up to MAX_INTERESTING_SOIL_DEPTH
  #
  setSoilDepths: ->
    @surfaceLand = []

    for x in [@patches.minX..@patches.maxX]
      lastDepth = -1
      for y in [@patches.maxY..@patches.minY]
        p = @patches.patch x, y
        continue if p.type is SKY
        p.depth = ++lastDepth
        p.color = if @showErosion and p.eroded
          if p.zone is 1 then ORANGE else MAGENTA
        else if p.isTerrace
          TERRACE_COLOR
        else
          if not @showSoilQuality
            LIGHT_LAND_COLOR
          else
            zone = if p.x <= 0 then 0 else 1
            if p.quality < @soilQuality[zone] then p.quality += 0.001
            if p.quality > @soilQuality[zone] then p.quality -= 0.001

            if p.quality < 0.5
              POOR_SOIL_COLOR
            else if p.quality > 1.5
              GOOD_SOIL_COLOR
            else
              LIGHT_LAND_COLOR

        if p.depth is 0 then @surfaceLand.push p

        if lastDepth >= MAX_INTERESTING_SOIL_DEPTH then break

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

      target = null

      if p.n[1+direction]?.type is SKY
        target = p.n[1+direction]
      else if p.n[1-direction]?.type is SKY
        target = p.n[1-direction]
        direction = direction * -1
      else if p.n[3.5+(direction/2)]?.type is SKY
        target = p.n[3.5+(direction/2)]
      else if p.n[3.5-(direction/2)]?.type is SKY
        target = p.n[3.5-(direction/2)]
        direction = direction * -1
      else
        p.direction = 0
        continue

      # check below target to make sure it drops down to solid ground
      while target.n[1].type is SKY
        target = target.n[1]

      # "move" patch to target
      p.type = SKY
      p.color = SKY_COLOR
      p.eroded = false

      target.type = LAND
      target.direction = direction
      target.eroded = true
      target.zone = p.zone
      target.stability = p.stability
      target.isTerrace = p.isTerrace
      target.quality = p.quality

      # count erosion in zones -- note this is not the same as the target's
      # origin zone (it's color), but where is it *currently* eroding from.
      if p.x < 0 then @zone1ErosionCount++ else @zone2ErosionCount++

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
