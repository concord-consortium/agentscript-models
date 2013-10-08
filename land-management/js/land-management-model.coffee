mixOf = (base, mixins...) ->
  class Mixed extends base
  for mixin in mixins by -1 #earlier mixins override later ones
    for name, method of mixin::
      Mixed::[name] = method
  Mixed


class LandManagementModel extends mixOf ABM.Model, LandGenerator, ErosionEngine
  RIGHT: 0
  UP:    1/2 * Math.PI
  LEFT:  Math.PI
  DOWN:  3/2 * Math.PI

  setup: ->
    @setFastPatches()
    @anim.setRate 100, true

    @setCacheAgentsHere()
    @setupLand()
    @draw()

  reset: ->
    super
    @setup()
    @anim.draw()

  step: ->
    @erode()
    @setSoilDepths()

window.LandManagementModel = LandManagementModel
modelLoaded.resolve()
