mixOf = (base, mixins...) ->
  class Mixed extends base
  for mixin in mixins by -1 #earlier mixins override later ones
    for name, method of mixin::
      Mixed::[name] = method
  Mixed


class LandManagementModel extends mixOf ABM.Model, LandGenerator, ErosionEngine, PlantEngine

  dateString: 'Jan 2013'
  initialYear: 2013
  year: 2013
  month: 0
  monthLength: 100
  monthStrings: "Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec".split(" ")

  setup: ->
    @setFastPatches()
    @anim.setRate 100, true

    @yearTick = 0

    @setCacheAgentsHere()
    @setupLand()
    @setupPlants()
    @draw()

  reset: ->
    super
    @setup()
    @updateDate()
    @notifyListeners(LandManagementModel.STEP_INTERVAL_ELAPSED)
    @notifyListeners(LandManagementModel.MONTH_INTERVAL_ELAPSED)
    @anim.draw()

  step: ->
    if (@anim.ticks % 20) == 1
      @updateDate()
      @notifyListeners(LandManagementModel.STEP_INTERVAL_ELAPSED)

    if (@anim.ticks % @monthLength) == 1
      @updatePrecipitation()
      @notifyListeners(LandManagementModel.MONTH_INTERVAL_ELAPSED)

    @erode()
    @setSoilDepths()
    @manageZones()
    @runPlants()

    if (@anim.ticks % 50) == 1
      @settlePlants()

  updateDate: ->
    monthsPassed = Math.floor @anim.ticks/@monthLength
    @year = @initialYear + Math.floor monthsPassed/12
    @month = monthsPassed % 12

    @dateString = @monthStrings[@month] + " " + @year

  @STEP_INTERVAL_ELAPSED: 'step-interval-elapsed'
  @MONTH_INTERVAL_ELAPSED: 'month-interval-elapsed'

  notifyListeners: (type) ->
    $(document).trigger type


window.LandManagementModel = LandManagementModel
modelLoaded.resolve()
