class FrackingModel extends ABM.Model
  DEBUG: false
  u: ABM.util
  airDepth: 0
  landDepth: 0
  waterDepth: 0
  oilDepth: 0
  baseDepth: 0
  width: 0
  height: 0
  setup: ->
    @anim.setRate 30, false
    @setFastPatches()
    @agentBreeds "gas"

    @setupGlobals()
    @setupPatches()
    @setupGas()

    setTimeout =>
      @draw()
    , 100

  reset: ->
    super
    @setup()
    @anim.draw()

  step: ->
    # other stuff

  setPatchColor: (p)->
    return unless p?
    p.color = switch p.type
      when "air"   then [ 93, 126, 186]
      when "land"  then [ 29, 159, 120]
      when "water" then [ 52,  93, 169]
      when "shale" then [237, 237,  49]
      when "rock"  then [157, 110,  72]
      when "well"  then [141, 141, 141]
      when "wellWall" then [87, 87, 87]

  setupGlobals: ->
    @airDepth   = Math.round(@patches.minY + @patches.maxY * 0.8)
    @landDepth  = Math.round(@patches.minY + @patches.maxY * 0.75)
    @waterDepth = Math.round(@patches.minY + @patches.maxY * 0.6)
    @oilDepth   = Math.round(@patches.minY + @patches.maxY * 0.4)
    @baseDepth  = Math.round(@patches.minY + @patches.maxY * 0.2)
    @width  = @patches.maxX - @patches.minX
    @height = @patches.maxY - @patches.minY

  setupPatches: ->
    for p in @patches
      p.type = "n/a"
      p.color = [255,255,255]
      # continue if p.isOnEdge()
      if p.y > @airDepth
        p.type = "air"
        @setPatchColor(p)
      else if p.y > @landDepth and p.y <= @airDepth
        p.type = "land"
        @setPatchColor(p)
      else if p.y > (@waterDepth + @height * Math.sin(@u.degToRad(1.5*p.x - (@width / 4))) / 20) and (p.y <= @landDepth)
        p.type = "water"
        @setPatchColor(p) if @DEBUG
      else if (p.y > @oilDepth + @height * Math.sin(@u.degToRad(0.9 * p.x)) / 15) and (p.y <= @waterDepth + @height * Math.sin(@u.degToRad(1.5 * p.x - (@width / 4))) / 20)
        p.type = "rock"
        @setPatchColor(p) if @DEBUG
      else if (p.y > @baseDepth + @height * 0.9 * Math.sin(@u.degToRad((1.8 * p.x) + 45)) / 25 + (p.x / 14)) and (p.y <= @oilDepth + @height * Math.sin(@u.degToRad(0.9 * p.x)) / 15)
        p.type = "shale"
        @setPatchColor(p) if @DEBUG
      else if (p.y <= @baseDepth + @height * 0.9 * Math.sin(@u.degToRad((1.8 * p.x) + 45)) / 25 + (p.x / 14))
        p.type = "rock"
        @setPatchColor(p) if @DEBUG

  setupGas: ->
    @gas.create 4000, (a)=>
      placed = false
      while not placed or a.p.type isnt "shale"
        x = 2 + @u.randomInt(@width - 4)
        y = 2 + @u.randomInt(@height - 4)
        a.moveTo @patches.patchXY(x, y)
        placed = true
      a.color = [255, 0, 0]
      a.heading = @u.degToRad(180)
      a.size = 4
      a.moveable = false
      a.trapped = (@u.randomInt(100) <= 14)
      a.shape = "triangle"
      a.hidden = not @DEBUG

  drill: (p)->
    # drill at the specified patch
    well = @findNearbyWell(p)
    if well?
      # if we're up in the land area, go vertically
      if p.y > @landDepth and p.y <= @airDepth
        # drill one deeper
        @drillVertical(well)
      else
        # TODO drill horizontally
        console.log "drilling horizontally (" + p.x + ", " + p.y + ")"
    else if p.type is "land" and p.x > (@patches.minX + 3) and p.x < (@patches.maxX - 3)
      well = {x: p.x, depth: @airDepth} # TODO some richer well object... ?
      # start a new vertical well as long as we're not too close to the wall
      for y in [@airDepth..(p.y)]
        @drillVertical(well)
    @draw()

  drillVertical: (well)->
    y = well.depth - 1
    return if y < (@patches.minY - 5)
    return if well.goneHorizontal

    #draw the well
    for x in [(well.x - 1)..(well.x + 1)]
      pw = @patches.patchXY x, y
      pw.well = well
      pw.type = "well"

    # and the well walls
    for x in [(well.x - 2), (well.x + 2)]
      pw = @patches.patchXY x, y
      pw.well = well
      pw.type = "wellWall"

    # Also expose the color of the 5 patches to either side
    for x in [(well.x - 7)..(well.x + 7)]
      @setPatchColor @patches.patchXY x, y

    well.depth = y

  findNearbyWell: (p)->
    if p.type is "well" or p.type is "wellWall"
      return p.well
    else
      # look within an N patch radius of us for a well or wellWall patch
      near = @patches.patchRect p, 5, 5, true
      for pn in near
        if pn.type is "well" or pn.type is "wellWall"
          return pn.well

window.FrackingModel = FrackingModel
