class WaterModelStaticLayers extends WaterModel
  setup: ->
    super

    # FIXME: For some reason, importing the same .png for both calls no longer works
    @patches.importColors "img/static-layers.png"
    @patches.importDrawing "img/static-layers-800.png"

    setTimeout =>
      @refreshPatches = true
      @draw()
      @refreshPatches = false

      # set patch types based on color
      for p in @patches
        if ABM.util.colorsEqual p.color, [205, 237, 252]
          p.type = "sky"
        else if ABM.util.colorsEqual p.color, [255, 255, 0]
          p.type = "soil"
        else if ABM.util.colorsEqual p.color, [255, 0, 0]
          p.type = "rock1"
        else if ABM.util.colorsEqual p.color, [117,117,176]
          p.type = "rock2"
        else if ABM.util.colorsEqual p.color, [0, 255, 0]
          p.type = "rock3"
        else if ABM.util.colorsEqual p.color, [0, 0, 0]
          p.type = "rock4"
        else
          # FIXME: Should probably interpolate the type from the gradient color...
          console.log("No direct match: " + p.color.toString())

    , 500

window.WaterModelStaticLayers = WaterModelStaticLayers