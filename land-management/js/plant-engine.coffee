
class PlantEngine

  u = ABM.util

  NORTH = Math.PI/2

  managementPlan = ["bare", "bare"]
  intensive = [false, false]

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
    types = type.split "-"
    managementPlan[zone] = types[0]
    intensive[zone] = types[1] is "intensive"

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
      v = data.periodVariation
      a.growthPeriods = (p + (p*u.randomFloat2(-v, v)) for p in data.growthPeriods)
      a.growthRates = data.growthRates
      a.period = 0
      a.periodAge = 0

  runPlants: ->
    killList = []

    for a in @agents
      poorWater = @precipitation < @plantData[a.type].minimumPrecipitation or
                  @precipitation > @plantData[a.type].maximumPrecipitation
      if a.isSeed
        # try to germinate on germination date. If we're annual and there isn't enough
        # water, we grow fewer plants. If we're not annual, push back germination date
        if @yearTick is a.germinationDate
          if poorWater and @plantData[a.type].annual
            if u.randomFloat(1) < 0.5
              killList.push a
              continue
          else if poorWater and not @plantData[a.type].annual
            if u.randomFloat(1) < 0.15
              killList.push a
            else
              a.germinationDate += 40
            continue
          a.isSeed = false
      else
        a.periodAge++
        if a.periodAge > a.growthPeriods[a.period]
          a.period++
          a.periodAge = 0

          switch a.period
            when 3
              @splitRoots a unless a.isRoot
            when 4
              if not @plantData[a.type].annual and not a.isRoot
                #reseed
                xModifier = if a.x <= 0 then -1 else 1
                patch = @surfaceLand[@patches.maxX + (u.randomInt(@patches.maxX) * xModifier)]
                @plantSeed a.type, patch
            when 5
              kill = false
              if not a.isRoot
                kill = true
              else
                if a.type = "wheat"
                  zone = if a.x <= 0 then 0 else 1
                  if not intensive[zone] and u.randomFloat(1) < 0.2
                    kill = true
                  if intensive[zone] and u.randomFloat(1) < 0.85
                    kill = true
                else if u.randomFloat(1) < 0.5 then kill = true

              if kill
                killList.push a
                continue

              a.period = 0

        growthRate = a.growthRates[a.period]
        if poorWater then growthRate -= 0.001

        a.size += growthRate

        if a.size <= 0 then killList.push a

    a.die() for a in killList

  splitRoots: (plant) ->
    plant.p.sprout 1, @[plant.type], (root) =>
      root.size = plant.size
      root.type = plant.type
      root.shape = plant.shape + "-root"
      root.isSeed = false
      root.isRoot = true
      root.growthPeriods = plant.growthPeriods
      root.growthRates = @plantData[plant.type].rootGrowthRates
      root.period = plant.period
      root.periodAge = 0
    plant.isBody = true
    plant.shape = plant.shape + "-body"

  # check if we need plants to settle due to ground eroding beneath them
  settlePlants: ->
    zoneWidth = @patches.maxX
    for a in @agents
      surfacePatch = @surfaceLand[zoneWidth + a.x]
      if surfacePatch.y < (a.y - 1)
        a.setXY a.x, a.y-0.2


  plantData:
    trees:
      quantity: 19
      inRows: false
      annual: false
      minGermination: 100
      maxGermination: 1200
      growthPeriods: [100, 1800, 4800, 1300, 1200]
      growthRates: [0.0014, 0.0018, 0.0001, -0.001, -0.001]
      rootGrowthRates: [0, -0.0005, 0, -0.0005, -0.0005]
      periodVariation: 0.22
      minimumPrecipitation: 14
      maximumPrecipitation: 450
      shapes: ["tree1", "tree2", "tree3"]
    grass:
      quantity: 33
      inRows: false
      annual: false
      minGermination: 1
      maxGermination: 800
      growthPeriods: [120, 210, 1400, 150, 100]
      growthRates: [0.002, 0.004, 0.0001, -0.005, -0.002]
      rootGrowthRates: [0, -0.001, 0, -0.001, -0.001]
      periodVariation: 0.15
      minimumPrecipitation: 14
      maximumPrecipitation: 450
      shapes: ["grass1", "grass2"]
    wheat:
      quantity: 19
      inRows: true
      annual: true
      minGermination: 60
      maxGermination: 90
      growthPeriods: [120, 210, 350, 100, 100]
      growthRates: [0.003, 0.005, 0.0001, -0.002, -0.005]
      rootGrowthRates: [0, 0, 0, -0.001, -0.001]
      periodVariation: 0.04
      minimumPrecipitation: 14
      maximumPrecipitation: 450
      shapes: ["wheat1"]

window.PlantEngine = PlantEngine
