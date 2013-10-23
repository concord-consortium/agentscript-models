
class PlantEngine

  u = ABM.util

  NORTH = Math.PI/2

  managementPlan = ["bare", "bare"]

  setupPlants: ->
    @agentBreeds "grass trees wheat"

    @trees.setDefaultShape "arrow"
    @trees.setDefaultColor [0,255,0]

    @addImage "tree1", "tree-1-sprite", 39, 70
    @addImage "tree2", "tree-2-sprite", 29, 80
    @addImage "tree3", "tree-3-sprite", 39, 80
    @addImage "grass1", "grass-1-sprite", 39, 80
    @addImage "grass2", "grass-1-sprite", 39, 80
    @addImage "wheat1", "wheat-1-sprite", 39, 80

  addImage: (name, id, width, height, scale) ->
    image = document.getElementById(id)
    ABM.shapes.add name, false, (ctx)=>
      ctx.scale(-0.1, 0.1);
      ctx.translate(width,height)
      ctx.rotate Math.PI
      ctx.drawImage(image, 0, 0)

    ABM.shapes.add "#{name}-body", false, (ctx)=>
      ctx.scale(-0.1, 0.1);
      ctx.translate(width,height)
      ctx.rotate Math.PI
      ctx.drawImage(image, 0, -height, width*2, height*2, 0, -height, width*2, height*2)

    ABM.shapes.add "#{name}-root", false, (ctx)=>
      ctx.scale(-0.1, 0.1);
      ctx.translate(width,height)
      ctx.rotate Math.PI
      ctx.drawImage(image, 0, height, width*2, height*2, 0, height, width*2, height*2)
  
  ###
    Defines the planting system of the two zones. Zone is defined
    by index, 0 or 1.
  ###
  setZoneManagement: (zone, type) ->
    managementPlan[zone] = type

  manageZones: ->
    if managementPlan.join() is "bare,bare" then return

    @yearTick = @anim.ticks % (12 * @monthLength)

    if @yearTick is 1
      @plantPlants()

  plantPlants: ->
    zoneWidth = @patches.maxX

    for zone in [0, 1]
      plantType = managementPlan[zone]
      continue if plantType is "bare"
      continue if @anim.ticks > (12 * @monthLength) and not @plantData[plantType].annual

      quantity  = @plantData[plantType].quantity
      inRows    = @plantData[plantType].inRows
      xModifier = zone*2 - 1      # -1, 1

      for i in [0...quantity]
        x = if inRows then Math.floor((i+1) * zoneWidth/(quantity+1)) else u.randomInt(zoneWidth)
        x *= xModifier
        patch = @surfaceLand[zoneWidth + x]     # find surface patch with x coord

        @plantSeed plantType, patch

  plantSeed: (type, patch) ->
    data = @plantData[type]
    patch.sprout 1, @[type], (a)->
      a.size = 0
      a.type = type
      a.shape = u.oneOf data.shapes
      a.isSeed = true
      a.dying = false
      a.germinationDate = u.randomInt2 data.minGermination, data.maxGermination
      a.deathDate = u.randomInt2 data.maxDeath, data.minDeath

  runPlants: ->
    killList = []

    for a in @agents
      if a.isSeed
        if (@plantData[a.type].annual and @yearTick is a.germinationDate) or (!@plantData[a.type].annual and @anim.ticks is a.germinationDate)
          a.isSeed = false
      else if a.isZombieRoot
      else
        if @month < 10
          a.size += @plantData[a.type].growthRate unless a.size > @plantData[a.type].maxSize
        else if @plantData[a.type].annual
          if not a.dying 
            if u.randomInt(50) is 1
              a.p.sprout 1, @[a.type], (_a)->
                _a.size = a.size
                _a.type = a.type
                _a.shape = a.shape + "-root"
                _a.isSeed = false
                _a.dying = true
                _a.isRoot = true
                _a.deathDate = a.deathDate
              a.dying = true
              a.isBody = true
              a.shape = a.shape + "-body"
          if a.dying
            shrinkRate = if not a.isRoot then @plantData[a.type].growthRate else @plantData[a.type].growthRate/3
            a.size -= shrinkRate unless a.size <= 0
          if @yearTick is (12 * @monthLength) - a.deathDate
            if not a.isRoot
              killList.push a
            else
              if u.randomFloat(1) < 0.25
                a.isZombieRoot = true
                a.dying = false
              else killList.push a

    a.die() for a in killList

  # check if we need plants to settle due to ground eroding beneath them
  settlePlants: ->
    zoneWidth = @patches.maxX
    for a in @agents
      surfacePatch = @surfaceLand[zoneWidth + a.x]
      if surfacePatch.y < (a.y - 1)
        a.setXY a.x, a.y-0.2


  plantData:
    trees:
      quantity: 20
      inRows: false
      annual: false
      minGermination: 100
      maxGermination: 1600
      growthRate: 0.003
      maxSize: 3.2
      shapes: ["tree1", "tree2", "tree3"]
    grass:
      quantity: 25
      inRows: false
      annual: false
      minGermination: 1
      maxGermination: 150
      growthRate: 0.01
      maxSize: 1.2
      shapes: ["grass1", "grass2"]
    wheat:
      quantity: 20
      inRows: true
      annual: true
      minGermination: 60
      maxGermination: 180
      minDeath: 100
      maxDeath: 30
      growthRate: 0.01
      maxSize: 1.5
      shapes: ["wheat1"]

window.PlantEngine = PlantEngine
