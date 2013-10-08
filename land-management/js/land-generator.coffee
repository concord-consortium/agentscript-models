SKY_COLOR = [131, 216, 240]
LIGHT_LAND_COLOR = [135, 79, 49]
DARK_LAND_COLOR = [105, 49, 19]
MAGENTA = [255, 0, 255]
ORANGE = [255, 127, 0]

SKY  = "sky"
LAND = "land"

MAX_INTERESTING_SOIL_DEPTH = 6

class LandGenerator

  u = ABM.util

  amplitude = -4
  erosionProbability = 30
  precipitation = 100
  maxSlope = 2 # necessary?
  showErosion: true

  setupLand: ->

    @skyPatches = []
    @landPatches = []

    for p in @patches
      p.zone = if p.y <= 0 then 1 else 2
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
        @landPatches.push p

    @setSoilDepths()


  setLandType: (type) ->
    switch type
      when "Nearly Flat"  then amplitude = -0.00001
      when "Plain"        then amplitude = -4
      when "Rolling"      then amplitude = -10
      when "Hilly"        then amplitude = -20
      else                     amplitude = 0

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
        else
          ( c-(p.depth*5) for c in LIGHT_LAND_COLOR )   # get darker as you go down

        if p.depth is 0 then @surfaceLand.push p

        if lastDepth >= MAX_INTERESTING_SOIL_DEPTH then break

  erode: ->
    # Find and sort the surface patches most exposed to the sky
    for p in @surfaceLand
      p.skyCount = 0
      p.skyCount++ for n in p.n when n?.type is SKY

    @surfaceLand.sort (a,b) ->
      return if a.skyCount <= b.skyCount then 1 else -1

    # Take the top 25% of most exposed soil patches and erode them
    for i in [0...@surfaceLand.length/4] by 1
      p = @surfaceLand[i]

      localSlope = @getLocalSlope p.x, p.y
      slopeContribution = 0.35 * (localSlope/2)
      vegetiationContribution = 0.65
      probabilityOfErosion = erosionProbability * (precipitation/400) * (slopeContribution + vegetiationContribution)

      if (u.randomInt(100) > probabilityOfErosion) then continue

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

      # "move" patch to target
      p.type = SKY
      p.color = SKY_COLOR
      p.eroded = false

      target.type = LAND
      target.direction = direction
      target.eroded = true
      target.zone = p.zone


  getLocalSlope: (x, y) ->
    xStep = 3
    yStep = 5

    leftEdge  = Math.max x-xStep, @patches.minX
    rightEdge = Math.min x+xStep, @patches.maxX
    bottom    = Math.max y-yStep, @patches.minY
    top       = Math.min y+yStep, @patches.maxY

    leftHeight  = bottom
    rightHeight = bottom

    while leftHeight < top and @patches.patch(leftEdge, leftHeight).type is LAND 
      leftHeight++

    while rightHeight < top and @patches.patch(rightEdge, rightHeight).type is LAND
      rightHeight++

    slope = (rightHeight - leftHeight) / (rightEdge - leftEdge)




  landShapeFunction: (x) ->
    amplitude * Math.sin( u.degToRad(x - 10) )

window.LandGenerator = LandGenerator