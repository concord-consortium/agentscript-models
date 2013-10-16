
class PlantEngine

  u = ABM.util

  NORTH = Math.PI/2

  BARE  = "bare"
  TREES = "trees"

  managementPlan = [BARE, BARE]

  setupPlants: ->
    @agentBreeds "trees"

    @trees.setDefaultShape "arrow"
    @trees.setDefaultColor [0,255,0]

    tree1Img = document.getElementById('tree-1-sprite')
    ABM.shapes.add "tree1", false, (ctx)=>
      ctx.scale(-0.05, 0.05);
      ctx.translate(77,140)
      ctx.rotate Math.PI
      ctx.drawImage(tree1Img, 0, 0)
    tree2Img = document.getElementById('tree-2-sprite')
    ABM.shapes.add "tree2", false, (ctx)=>
      ctx.scale(-0.05, 0.05);
      ctx.translate(57,160)
      ctx.rotate Math.PI
      ctx.drawImage(tree2Img, 0, 0)
    tree3Img = document.getElementById('tree-3-sprite')
    ABM.shapes.add "tree3", false, (ctx)=>
      ctx.scale(-0.05, 0.05);
      ctx.translate(78,160)
      ctx.rotate Math.PI
      ctx.drawImage(tree3Img, 0, 0)
  
  ###
    Defines the planting system of the two zones. Zone is defined
    by index, 0 or 1.
  ###
  setZoneManagement: (zone, type) ->
    managementPlan[zone] = type

  manageZones: ->
    if managementPlan.join() is "#{BARE},#{BARE}" then return

    @yearTick = @anim.ticks % (12 * @monthLength)

    if @yearTick is 1
      @plantPlants()

  plantPlants: ->
    zoneWidth = @patches.maxX

    for zone in [0, 1]
      plantType = managementPlan[zone]
      continue if plantType is BARE
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
      a.germinationDate = u.randomInt2 data.minGermination, data.maxGermination

  runPlants: ->
    for a in @agents
      if a.isSeed
        if @yearTick is a.germinationDate
          a.isSeed = false
      else
        a.size += @plantData[a.type].growthRate unless a.size > @plantData[a.type].maxSize


  plantData:
    trees:
      quantity: 15
      inRows: false
      annual: false
      minGermination: 1
      maxGermination: 300
      growthRate: 0.005
      maxSize: 3
      shapes: ["tree1", "tree2", "tree3"]

window.PlantEngine = PlantEngine
