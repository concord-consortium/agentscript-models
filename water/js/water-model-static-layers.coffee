class WaterModelStaticLayers extends WaterModel
  setup: ->
    super

    # FIXME: For some reason, importing the same .png for both calls no longer works
    @patches.importColors "state/WaterModel-5-23-11-goodVbadAquifers-Aquifers-Example.png"
    @patches.importDrawing "state/WaterModel-5-23-11-goodVbadAquifers-Aquifers-Example.png"

    setTimeout =>
      @refreshPatches = true
      @draw()
      @refreshPatches = false

      # set patch types based on color
      for p in @patches
        if ABM.util.colorsEqual p.color, [205, 237, 252]
          p.type = "sky"
        else if ABM.util.colorsEqual p.color, [232,189,174]
          p.type = "soil"
        else if ABM.util.colorsEqual p.color, [196,162,111]
          p.type = "rock1"
        else if ABM.util.colorsEqual p.color, [123,80,56]
          p.type = "rock2"
        else if ABM.util.colorsEqual p.color, [113,115,118]
          p.type = "rock3"
        else if ABM.util.colorsEqual p.color, [33,42,47]
          p.type = "rock4"
        else
          # FIXME: Should probably interpolate the type from the gradient color...
          console.log("No direct match: " + p.color.toString())

    , 500

window.WaterModelStaticLayers = WaterModelStaticLayers