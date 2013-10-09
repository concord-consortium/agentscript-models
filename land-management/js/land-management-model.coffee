mixOf = (base, mixins...) ->
  class Mixed extends base
  for mixin in mixins by -1 #earlier mixins override later ones
    for name, method of mixin::
      Mixed::[name] = method
  Mixed


class LandManagementModel extends mixOf ABM.Model, LandGenerator, ErosionEngine

  setup: ->
    @setFastPatches()
    @anim.setRate 100, true

    @setCacheAgentsHere()
    @setupLand()
    @draw()

  reset: ->
    super
    @setup()
    @updateDate()
    @notifyListeners()
    @anim.draw()

  step: ->
    @erode()
    @setSoilDepths()

    if (@anim.ticks % 20) == 0
      @updateDate()
      @notifyListeners()

  dateString: 'Jan 2013'
  initialYear: 2013
  year: 2013
  month: 0
  ticksPerMonth: 100
  monthStrings: "Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec".split(" ")

  updateDate: ->
    monthsPassed = Math.floor @anim.ticks/@ticksPerMonth
    @year = @initialYear + Math.floor monthsPassed/12
    @month = monthsPassed % 12

    @dateString = @monthStrings[@month] + " " + @year

  @STEP_INTERVAL_ELAPSED: 'step-interval-elapsed'

  notifyListeners: ->
    $(document).trigger LandManagementModel.STEP_INTERVAL_ELAPSED


window.LandManagementModel = LandManagementModel
modelLoaded.resolve()
