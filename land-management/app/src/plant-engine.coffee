
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
    @addImage "grass2", "grass-2-sprite", 39, 80
    @addImage "browngrass1", "brown-grass-1-sprite", 39, 80
    @addImage "browngrass2", "brown-grass-2-sprite", 39, 80
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
    previousPlantType = managementPlan[zone]
    types = type.split "-"
    plantType = types[0]
    managementPlan[zone] = types[0]
    intensive[zone] = types[1] is "intensive"

    unless @yearTick is 0  # (in which case, manageZones() will handle planting)
      @plantPlantsInZone(zone) if previousPlantType is "bare"

  manageZones: ->
    if managementPlan.join() is "bare,bare" then return

    if @yearTick() is 1
      @killOffUnwantedPerennials()
      @plantPlants()

  killOffUnwantedPerennials: ->
    killList = []

    for a in @agents
      zone = if a.p?.x <= 0 then 0 else 1
      if not a.isRoot and not @plantData[a.type]?.annual and a.type isnt managementPlan[zone]
        killList.push a

    a.die() for a in killList

  isPrecipitationOptimalFor: (type) ->
    plantData = @plantData[type]
    plantData.minimumPrecipitation <= @precipitation <= plantData.maximumPrecipitation

  isPrecipitationTooLowFor: (type) ->
    ret = @precipitation < @plantData[type].minimumPrecipitation
    ret

  # returns the number of plants (seeds and plant bodies, but not detached roots) in zone
  plantPopulationInZone: (zone) ->
    @agents.reduce ((x, a) => if @isAgentAPlantInZone(a, zone) then x + 1 else x), 0

  adjustPlantPopulationInZone: (zone) ->
    killList = []
    plantType = managementPlan[zone]

    return if not @plantData[plantType]?.isAffectedByPoorWaterAfterPlanting

    actualPopulation = @plantPopulationInZone zone
    populationIfOptimalPrecipitation = @plantData[plantType].quantity

    if @isPrecipitationOptimalFor managementPlan[zone]
      # add actualPopulation seeds
      if actualPopulation < populationIfOptimalPrecipitation then @plantPlantsInZone zone
    else
      if actualPopulation is populationIfOptimalPrecipitation
        # need to kill off some plants
        for a in @agents
          if @isAgentAPlantInZone(a, zone) and u.randomFloat(1) < @plantData[plantType].mortalityInPoorWater
            killList.push(a)

    for a in killList
      # split into roots and body, unless already split
      if not a.isBody then @splitRoots(a)
      a.die()

  isAgentAPlantInZone: (a, zone) ->
    if zone is 0
      a.x <= 0 and not a.isRoot
    else
      a.x > 0 and not a.isRoot

  plantPlantsInZone: (zone) ->
    zoneWidth = @patches.maxX
    plantType = managementPlan[zone]

    return if plantType is "bare"

    # Wait to next year to plant if last germination date has passed for this year.
    return if @yearTick() > @plantData[plantType].maxGermination

    # OK, we're planting:
    desiredPopulation  = @plantData[plantType].quantity
    # note that currently, we kill off undesired plants before planting something new, so there
    # should be no reason to check that the plants are the desired type
    actualPopulation = @plantPopulationInZone zone

    sign = zone * 2 - 1      # -1, 1
    inRows = @plantData[plantType].inRows

    plantAt = (x) =>
      patch = @surfaceLand[zoneWidth + x]     # surface patch with given x coordinate
      @plantSeed plantType, patch

    if inRows and actualPopulation is 0
      for i in [0...desiredPopulation]
        plantAt sign * Math.floor (i + 1) * zoneWidth / (desiredPopulation+1)
    else if not inRows
      for i in [actualPopulation...desiredPopulation]
        plantAt sign * u.randomInt zoneWidth

  plantPlants: ->
    @plantPlantsInZone(zone) for zone in [0, 1]
    null

  plantSeed: (type, patch) ->
    data = @plantData[type]
    patch.sprout 1, @[type], (a) =>
      a.size = data.initialSize
      a.type = type
      a.shape = u.oneOf data.shapes
      a.isSeed = true
      a.dying = false
      a.germinationDate = u.randomInt2 Math.max(@yearTick()+1, data.minGermination), data.maxGermination
      v = data.periodVariation
      a.growthPeriods = (p * u.randomFloat2(1-v, 1+v) for p in data.growthPeriods)
      a.growthRates = data.growthRates
      a.period = 0
      a.periodAge = 0
      a.isBrowned = false

  runPlants: ->
    killList = []

    @adjustPlantPopulationInZone(zone) for zone in [0, 1]

    for a in @agents
      poorWater = not @isPrecipitationOptimalFor a.type

      if @plantData[a.type].hasBrownVariant and not a.isSeed
        if @isPrecipitationTooLowFor a.type
          if not a.isBrowned
            a.shape = "brown" + a.shape
            a.isBrowned = true
        else if a.isBrowned
          a.shape = a.shape.match(/brown(.*)/)[1]
          a.isBrowned = false

      if a.isSeed
        # try to germinate on germination date. If we're annual and there isn't enough
        # water, we grow fewer plants. If we're not annual, push back germination date
        if @yearTick() is a.germinationDate
          if poorWater
            if u.randomFloat(1) < @plantData[a.type].mortalityInPoorWater
              killList.push a
            else if not @plantData[a.type].annual
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
              # plants which don't live indefinitely get split into body and root at period 3, and
              # these have slightly different growth (decay) trajectories. Indefinitely-lived plants
              # should only be split (elsewhere) when the body is killed off.
              @splitRoots a unless a.isRoot or a.growthPeriods[a.period] is Infinity
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
                if a.type is "wheat"
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

        growthRate = a.growthRates[a.period] * @topsoilRateFactor(a)
        if poorWater then growthRate *= 0.85

        a.size *= (growthRate + 1)

        if a.size <= 0 then killList.push a

    a.die() for a in killList


  # Returns a factor in the range [0.7, 1] that is proportional to the fraction of current topsoil
  # depth below the plant agent to the initial topsoil depth. Returns 1 if the current topsoil depth
  # is as deep or deeper then the initial topsoil depth.

  # Note that, for wheat, a reduction in the daily growth rate by a factor of 0.7 results in a
  # maximum size that is 1/2 that of wheat without a reduced growth rate
  topsoilRateFactor: (agent) ->
    [x, y] = [agent.p.x, agent.p.y]
    topsoilDepth = 0
    topsoilDepth++ while @patches.patch(x, y - topsoilDepth).isTopsoil

    0.3 * Math.min(topsoilDepth, @INITIAL_TOPSOIL_DEPTH) / @INITIAL_TOPSOIL_DEPTH + 0.7

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
      root.isBrowned = plant.isBrowned
    plant.isBody = true
    plant.shape = plant.shape + "-body"

  # check if we need plants to settle due to ground eroding beneath them
  settlePlants: ->
    zoneWidth = @patches.maxX
    for a in @agents
      surfacePatch = @surfaceLand[zoneWidth + a.x]
      if surfacePatch.y < (a.y - 1)
        a.setXY a.x, a.y-0.2

  soilQuality: [1, 1]

  calculateSoilQuality: ->
    for zone in [0..1]
      quality = @soilQuality[zone]
      if managementPlan[zone] is "wheat"
        # intensive tillage decreases soil quality,
        # while conservative tilled maintains current quality levels
        if intensive[zone] then quality -= 0.02
      else if managementPlan[zone] is "bare"
        # quality decreases most rapidly of all
        quality -= 0.03
      else
        quality += 0.01
      quality = Math.max(Math.min(quality, 2), 0)
      @soilQuality[zone] = quality

  plantData:
    trees:
      quantity: 19
      inRows: false
      annual: false
      minGermination: 100
      maxGermination: 1200
      initialSize: 0.4
      growthPeriods: [100, 1800, 4800, 1300, 1200]
      growthRates: [0.00042, 0.00116,  0.00003, -0.00018, -0.00019]
      rootGrowthRates: [0, -0.0005, 0, -0.0005, -0.0005]
      periodVariation: 0.22
      minimumPrecipitation: 14
      maximumPrecipitation: 450
      isAffectedByPoorWaterAfterPlanting: false
      mortalityInPoorWater: 0.15
      shapes: ["tree1", "tree2", "tree3"]
    grass:
      quantity: 33
      inRows: false
      annual: false
      initialSize: 0.2
      minGermination: 1
      maxGermination: 800
      rootGrowthRates: [0, -0.001, 0, -0.001, -0.001]
      growthPeriods: [120, 210, 1400, Infinity, Infinity]
      growthRates: [0.0043, 0.0053,  0.0003, 0, 0]
      periodVariation: 0.15
      minimumPrecipitation: 14
      maximumPrecipitation: 450
      isAffectedByPoorWaterAfterPlanting: true
      mortalityInPoorWater: 0.15
      shapes: ["grass1", "grass2"]
      hasBrownVariant: true
    wheat:
      quantity: 19
      inRows: true
      annual: true
      initialSize: 0.2
      minGermination: 60
      maxGermination: 90
      growthPeriods: [120, 210, 350, 100, 100]
      growthRates: [0.0049,  0.0061,  0.0008,  0.0003, -0.0027]
      rootGrowthRates: [0, 0, 0, -0.001, -0.001]
      periodVariation: 0.04
      minimumPrecipitation: 14
      maximumPrecipitation: 450
      isAffectedByPoorWaterAfterPlanting: false
      mortalityInPoorWater: 0.5
      shapes: ["wheat1"]

window.PlantEngine = PlantEngine
