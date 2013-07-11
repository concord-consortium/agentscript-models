class AirPollutionModel extends ABM.Model

  setup: ->
    @anim.setRate 30, false
    @setFastPatches()
    @patches.usePixels true
    @setTextParams {name: "drawing"}, "10px sans-serif"
    @setLabelParams {name: "drawing"}, [255,255,255], [0,-20]

    @patches.importColors "img/air-pollution-bg-mask.png"
    @patches.importDrawing "img/air-pollution-bg.png"

    @draw()
    @refreshPatches = false

    $(document).trigger 'model-ready'

  reset: ->
    super
    @setup()
    @anim.draw()

  step: ->
    return

window.AirPollutionModel = AirPollutionModel
$(document).trigger 'air-pollution-model-loaded'