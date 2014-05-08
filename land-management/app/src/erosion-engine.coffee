SKY_COLOR = [131, 216, 240]

LIGHT_LAND_COLOR = [135, 79, 49]
DARK_LAND_COLOR = [105, 49, 19]
TERRACE_COLOR = [60, 60, 60]

GOOD_SOIL_COLOR = [88, 41, 10]
POOR_SOIL_COLOR = [193, 114, 7]

MAGENTA = [255, 50, 185]
ORANGE  = [255, 195, 50]
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

  minErosionProbability: 0.1
  fullyProtectiveVegetationLevel: 1

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



  # We need some way to avoid the overaccumulation of eroded soil and other edge effects that occur
  # at the left and right edges of the model, which occur because the model doesn't actually
  # simulate what happens when particles move past the edge of the model window.
  #
  # This just forces the left and rightmost edges to have the a height that matches the local slope
  # at the left and right edges of the model. We use a linear regression here instead of the cruder
  # (but faster) single-sample estimate made by @getLocalSlope, because this is only done twice per
  # tick and probably helps to avoid visual artifacts.
  adjustEdges: ->
    @adjustEdge 0, 1
    @adjustEdge @surfaceLand.length - 1, -1

  adjustEdge: (iLim, direction) ->
    SURFACE_WIDTH = 10

    currentY = @surfaceLand[iLim].y
    data = ([i, @surfaceLand[i].y] for i in [iLim + direction .. iLim + SURFACE_WIDTH * direction])
    desiredY = Math.round(ss.linear_regression().data(data).line()(iLim))
    x = @surfaceLand[iLim].x

    if currentY < desiredY
      @convertSkyToLand(@patches.patch x, y) for y in [currentY + 1 .. desiredY]
    else if currentY > desiredY
      @convertLandToSky(@patches.patch x, y) for y in [desiredY + 1 .. currentY]
    null

  # A little tricky. This takes a sky patch p and converts it to land. It uses majority rules to
  # guess its zone of origin and whether it's topsoil or subsoil.
  convertSkyToLand: (p) ->
    xMin = Math.max(0, p.x - 5)
    xMax = Math.min(@patches.maxX - 1, p.x + 5)

    # take a census of nearby patches to see if we should be topsoil and which zone we came from
    zones =   [0, 0]
    topsoil = [0, 0]

    for x in [xMin..xMax]
      ySurface = @surfaceLand[x - @patches.minX].y
      for y in [ySurface - 2 .. ySurface]
        p1 = @patches.patch x, y
        continue if p1.type isnt LAND

        ++zones[p1.zone]
        ++topsoil[p1.isTopsoil+0]

    p.zone = if zones[0] > zones[1] then 0 else 1
    p.isTopsoil = topsoil[1] > topsoil[0]

    p.type = LAND
    p.eroded = true
    p.isTerrace = false
    p.stability = 1

    # we'll let @updateSurfaceLandPatches sort it out next cycle
    p.quality = 1
    p.color = if p.isTopsoil then LIGHT_LAND_COLOR else DARK_LAND_COLOR

  convertLandToSky: (p) ->
      p.type = SKY
      p.color = SKY_COLOR
      @removeLandProperties p

  erode: ->

    signOf = (x) -> if x is 0 then 1 else Math.round x / Math.abs(x)

    @adjustEdges()

    for i in [1...@surfaceLand.length-1]
      p = @surfaceLand[i]

      localSlope = @getLocalSlope p.x, p.y
      slopeContribution = Math.min(1, 2 * Math.abs localSlope)

      vegetation = @getLocalVegetation p.x
      totalVegetationSize = 0
      totalVegetationSize += (if a.isBody then a.size/3 else if a.isRoot then a.size*2/3 else a.size) for a in vegetation
      vegetationContribution = @minErosionProbability + 0.8 * (1 - Math.min(1, totalVegetationSize / Math.max(@fullyProtectiveVegetationLevel, 0.01)))

      precipitationContribution  = @precipitation / 500

      probabilityOfErosion = 0.1 * slopeContribution * vegetationContribution * precipitationContribution * p.stability

      continue if u.randomFloat(1) > probabilityOfErosion

      p.direction = signOf -localSlope

      # remember, indices into p.n relative to patch p (in the center of the below diagram):
      # 5  6  7
      # 3  -  4
      # 0  1  2

      if p.x is @patches.minX and p.direction is -1
        # Trying a very simple formula. Basic idea is to extrapolate height to left of leftmost
        # patch of model, *without* using the leftmost patch itself to determine that height.
        expectedHeightToLeft = 2 * @surfaceLand[1].y - @surfaceLand[3].y
        # if land is expected to be higher to the left, we can't erode leftwards
        continue if expectedHeightToLeft >= p.y
        # we'll move left and leave the model (p will become sky but not be cloned to a target)
        target = null
      else if p.x is @patches.maxX and p.direction is 1
        lastIndex = @surfaceLand.length - 1
        expectedHeightToRight = 2 * @surfaceLand[lastIndex - 1].y - @surfaceLand[lastIndex - 3].y
        continue if expectedHeightToRight >= p.y
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
      @convertLandToSky p

      # Now, look UP from the patch p (which is now sky) and see if we left a land patch "hanging"
      # above a sky patch. (All land patches are settled on terra firma after each iteration of
      # this loop, so we need to look upward no more than 1 patch.)
      @swapSkyAndLand p, p.n[6] if p.n[6]?.type is LAND

  swapSkyAndLand: (sky, land) ->
    for property in @landPropertyNames.concat(['type', 'color'])
      [land[property], sky[property]] = [sky[property], land[property]]
    null

  removeLandProperties: (p) ->
    p[property] = null for property in @landPropertyNames
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


  # Returns all the vegetation agents (unsplit plants, roots, and bodies) with x-values between
  # x-5 and x+5. Note that it makes specific assumptions about calling patterns:
  #
  #   We'll make a very specific assumption for efficient searching: we're always called in "sweeps"
  #   of increasing x-order, so that when called with a smaller x value than the previous call, we
  #   know we're starting a new sweep.
  #   NOTE: agents must not be added between sweeps.
  #
  getLocalVegetation: do ->

    # we'll search for vegetation within SEARCH_HALF_WIDTH of either side of x
    SEARCH_HALF_WIDTH = 5

    # previous x value, used to identify new "sweeps"
    lastX = null

    # Agents sorted by increasing x coordinate. (The agents === the vegetation)
    sortedAgents = null

    # index (into sortedAgents) of the leftmost agent in the "search region"
    lastIndex = null

    (x) ->
      if not lastX? or x < lastX
        sortedAgents = (a for a in @agents).sort (a, b) -> a.x - b.x
        lastIndex = 0

      lastX = x

      # Find the leftmost agent in the search window
      length = sortedAgents.length
      lastIndex++ while lastIndex < length and sortedAgents[lastIndex].x < x - SEARCH_HALF_WIDTH

      return [] if lastIndex is length

      # return array with all the vegetation between the left and right sides of the search window
      vegetation = []
      i = lastIndex
      while i < length and sortedAgents[i].x < x + SEARCH_HALF_WIDTH
        vegetation.push sortedAgents[i]
        i++

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

  topsoilInZones: ->
    ret = []
    ret[1] = 0
    ret[2] = 0
    count = 0
    for p in @patches
      if p.isTopsoil
        count++
        if p.x < 0 then ret[1]++ else ret[2]++
    ret

window.ErosionEngine = ErosionEngine
