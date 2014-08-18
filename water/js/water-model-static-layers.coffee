class WaterModelStaticLayers extends WaterModel
  @background: null
  setup: ->
    super

    @_setupPatches()

  _setupPatches: ->
    if WaterModelStaticLayers.background?
      @patches.importColors WaterModelStaticLayers.background

    setTimeout =>
      @refreshPatches = true
      @draw()
      @refreshPatches = false

      # set patch types based on color
      for p in @patches
        @_setType p

      @redraw()
    , 500

  _setType: (p)->
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
    else if p.n[6]?.type?
      p.type = p.n[6].type
    else
      # FIXME: Should probably interpolate the type from the gradient color...
      console.log("No direct match: " + p.color.toString())
      p.type = "sky"
    delete p.color
    @patchChanged(p, true)


window.WaterModelStaticLayers = WaterModelStaticLayers
