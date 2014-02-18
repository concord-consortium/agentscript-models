class GasWell extends Well
  open: null
  openShale: null
  filling: null
  exploding: null
  fracking: null
  pumping: null
  pond: null

  leaks: false
  pondLeaks: false

  # state management
  explodingInProgress: false
  exploded: false
  fillingInProgress: false
  filled: false
  frackingInProgress: false
  fracked: false

  @LOOKAHEAD_TYPES: ["open","cleanWaterOpen","cleanPropaneOpen","dirtyWaterOpen","dirtyPropaneOpen"]

  # fill types
  @PROPANE: 'Propane'
  @WATER:   'Water'

  # some event types
  @CAN_EXPLODE: "canExplode"
  @EXPLODED: 'exploded'
  @FILLED: 'filled'
  @FRACKED: 'fracked'

  # some graphical images
  @POOL_IMG: ABM.util.importImage 'img/fracking_pool01.png'

  constructor: (@model, @x, @depth, @leaks=false, @pondLeaks=false)->
    # set these here so all Well instances don't share the same arrays
    @open = []
    @openShale = []
    @filling = []
    @exploding = []
    @fracking = []
    @pumping = []
    @pond = []

    console.log "*" if @leaks
    console.log "+" if @pondLeaks

    super

  drawWell: ->
    img = @constructor.WELL_IMG
    @drawUI img, @head.x, @head.y, 0.5, 0.03

  drawLabel: ->
    ctx = @model.contexts.drawing
    
    ctx.save()
    ctx.translate @head.x, @head.y
    ctx.scale 1/ABM.patches.size, -1/ABM.patches.size
    ctx.translate 0, -60
    
    ctx.save()
    ctx.scale 0.8, 1

    ctx.fillStyle = 'white'

    ctx.beginPath()
    ctx.moveTo 0, 26
    ctx.lineTo -15, 5
    ctx.lineTo 15, 5
    ctx.lineTo 0, 26
    ctx.fill()    
    ctx.closePath()

    ctx.beginPath()
    ctx.arc 0, 0, 16, 2 * Math.PI, false
    ctx.fill()
    ctx.closePath()

    ctx.fillStyle = ABM.util.colorStr @getLabelColor @id
    ctx.beginPath()
    ctx.arc 0, 0, 13, 2 * Math.PI, false
    ctx.fill()
    ctx.closePath()
    ctx.restore()

    ctx.font = '16px "Helvetica Neue\", Helvetica, sans-serif'
    ctx.fillStyle = 'white'
    ctx.fillText '' + @id, -4.5, 6
    ctx.restore()

  getLabelColor: (id) ->
    switch id
      when 1 then [228,26,28]
      when 2 then [27,158,119]
      when 3 then [152,78,163]
      else [255,255,255]    

  addOpen: (p)->
    @open.push p
    p.well = @

  addExploding: (p)->
    @openShale.push p if p.type is "shale"
    p.type = "exploding"
    p.well = @
    @model.patchChanged p
    @exploding.push p

  drill: (drillDirection, drillSpeed)->
    return if @explodingInProgress or
      @fillingInProgress or @filled or
      @frackingInProgress or @fracked
    super

  drillHorizontal: ->
    super
    if @goneHorizontal
      # set up "exploding" patches every 10
      if Math.abs(@x - @head.x) % 10 == 0
        for y in [(@depth-4)..(@depth-2)]
          pw = @model.patches.patchXY @x, y
          @addExploding pw
        for y in [(@depth+4)..(@depth+2)]
          pw = @model.patches.patchXY @x, y
          @addExploding pw
        @exploded = false
        $(document).trigger GasWell.CAN_EXPLODE

      # Also expose the color of the 5 patches to top/bottom
      for y in [(@depth - 7)..(@depth + 7)]
        @model.patchChanged @model.patches.patchXY @x, y

  processSet: (set, done, n4processor = null, pProcessor = null)->
    for p in set
      pProcessor(p) if pProcessor?
      if n4processor?
        for pn in p.n4
          if pn?
            n4processor(pn)
    @model.redraw()
    done()

  explode: ->
    return unless @goneHorizontal
    if @exploding.length <= 0
      @exploded = true if @explodingInProgress
      @explodingInProgress = false
      $(document).trigger @constructor.EXPLODED
      return
    @explodingInProgress = true
    currentExploding = ABM.util.clone @exploding
    @exploding = []
    setTimeout =>
      @processSet currentExploding, =>
        @explode()
      , (p)=>
        return if p.isWell
        switch p.type
          when "shale"
            if ABM.util.randomInt(100) < @model.shaleFractibility
              @addExploding p
          when "rock"
            if ABM.util.randomInt(100) < @model.rockFractibility
              @addExploding p
      , (p)=>
        return if p.isWell
        p.type = "open"
        @addOpen p
        @model.patchChanged p
    , 50

  fill: ->
    if @filling.length <= 0
      @filled = true if @fillingInProgress
      @fillingInProgress = false
      $(document).trigger @constructor.FILLED
      setTimeout =>
        @cycleWaterColors()
      , 500
      return
    currentFilling = ABM.util.clone @filling
    @filling = []
    setTimeout =>
      @processSet currentFilling, =>
        @fill()
      , (p)=>
        return if p.isWell
        switch p.type
          when "open"
            if p.well? and p.well is @
              p.type = "clean" + @fillType + "Open"
              @model.patchChanged p
              @filling.push p
    , 50

  floodWater: ->
    @fillType = @constructor.WATER
    @flood()

  floodPropane: ->
    @fillType = @constructor.PROPANE
    @flood()

  flood: ->
    return if @capped or @filled or @fracked or not @exploded
    for p in @patches
      if @fillType is @constructor.WATER
        p.color = [45, 141, 190]
      else
        p.color = [122, 192, 99]
      @model.patchChanged p

    @createWastePond() if @fillType is @constructor.WATER

    @fillingInProgress = true
    @model.redraw()

    @filling = ABM.util.clone @walls
    @fill()

  frack: ->
    return unless @filled
    if @fracking.length <= 0
      @fracked = true if @frackingInProgress
      @frackingInProgress = false
      $(document).trigger @constructor.FRACKED
      return
    @frackingInProgress = true
    currentFracking = ABM.util.clone @fracking
    @fracking = []
    fractibilityModifier = switch @fillType
      when @constructor.WATER then 1.05
      when @constructor.PROPANE then 1.1
      else 1
    setTimeout =>
      @processSet currentFracking, =>
        @frack()
      , (p)=>
          return if p.isWell
          switch p.type
            when "shale"
              if ABM.util.randomInt(100) < (@model.shaleFractibility * fractibilityModifier)
                @fracking.push p
                p.type = "dirty" + @fillType + "Open"
                @addOpen p
                @model.patchChanged p
    , 50

  pumpOut: ->
    return unless @filled and @fracked
    # start with all of the "open" patches
    opens = ABM.util.clone @open
    opens.sort (a,b)=>
      Math.abs(b.y - @depth) - Math.abs(a.y - @depth)

    # then add all of the well interior patches, sorted by their distance
    # to the well head.
    interiors = ABM.util.clone @patches
    interiors.sort (a,b)=>
      ABM.util.distance(b.x,b.y,@head.x,@head.y) - ABM.util.distance(a.x,a.y,@head.x,@head.y)

    @pumping = opens.concat interiors
    @cappingInProgress = true

    numberOfPumpingRounds = Math.ceil @pumping.length / 100
    @numberOfPondPatchesPerRound = Math.ceil @pond.length / numberOfPumpingRounds

    @numberOfPondPatchesToDirty = @pond.length
    @empty()

  empty: ->
    if @pumping.length <= 0
      @filled = false
      @capped = true if @cappingInProgress
      @cappingInProgress = false
      $(document).trigger @constructor.CAPPED
      @tickOpened = @model.anim.ticks
      return

    currentPumping = @pumping.slice(0,100)
    @pumping = @pumping.slice(100)

    setTimeout =>
      @processSet currentPumping, =>
        @empty()
      , null, (p)=>
        if p.isWell
          p.color = [141, 141, 141]
        else
          p.type = "open"
        @model.patchChanged p

      # turn @numberOfPondPatchesPerRound pond patches from air to dirty water
      n = @numberOfPondPatchesPerRound

      while n-- > 0 and @numberOfPondPatchesToDirty-- > 0
        p = @pond[@numberOfPondPatchesToDirty]
        p.type = "dirtyWaterPond"
        @model.patchChanged p

    , 50

  cycleWaterColors: ->
    if @fillType is @constructor.WATER
      colors = [
        [ 67, 160, 160],
        [ 64, 152, 152],
        [ 61, 144, 144],
        [ 57, 137, 137],
        [ 64, 129, 129],
        [ 51, 121, 121],
        [ 48, 113, 113],
        [ 45, 105, 105],
        [ 41,  98,  98],
        [ 38,  90,  90]
      ]
    else
      colors = [[122, 192, 99]]
    @nextColor(colors)

  nextColor: (colors)->
    if colors.length <= 0
      setTimeout =>
        for p in @patches
          if @fillType is @constructor.WATER
            p.color = [38,  90,  90]
          else
            p.color = [122, 192, 99]

        @fracking = ABM.util.clone @open
        @frack()
      , 250
      return
    c = colors.shift()
    setTimeout =>
      for p in @patches
        p.color = c
        @model.toRedraw.push p

      for p in @open
        p.color = c
        @model.toRedraw.push p

      @model.redraw()
      @nextColor(colors)
    , 100

  spawnNewGas: ->
    return unless @capped
    return unless @openShale.length > 0
    # spawn new gas at a rate dependent on the age of the well
    # this ensures we get a nice reduction curve over time
    numToSpawn = 0
    age = @ageFloat()
    return if age is 0
    wellSize = @openShale.length * 1.5
    numToSpawn = wellSize/((age+1)*150) + 0.5
    if (deci = numToSpawn % 1) > 0
      numToSpawn = (if ABM.util.randomFloat(1) < deci then Math.ceil(numToSpawn) else Math.floor(numToSpawn))
    if numToSpawn > 0
      @model.gas.create numToSpawn, (g)=>
        g.moveTo ABM.util.oneOf @openShale
        g.well = @
        g.trapped = false
        g.heading = ABM.util.degToRad(180)
        g.moveable = false
        g.hidden = false

  createWastePond: ->
    imgParams = [@constructor.POOL_IMG, @head.x + 10.5, @head.y, 0, 0.89]
    @drawUI imgParams...
    bbox = @getDrawUIBBox imgParams...
    @belowPond =
      y: Math.floor(bbox.y) - 1
      xMin: Math.floor(bbox.x)
      xMax: Math.floor(bbox.x) + Math.round(bbox.width) 

    # find the pixels in the "open" interior of the pond
    pondPixels = @findEmptyPixels @constructor.POOL_IMG
    
    # Offset for finding patches corresponding to pixels. The values -2 is an empirical adjustment
    # for visual fit, which is necessary because the patches are a non-integer number of pixels
    # wide. Bounding box height is subtracted from y0 because (x0, y0) needs to be the upper left of
    # the pond area when mapping pixels to patches. (bbox.x, bbox.y) is the lower left.
    x0 = Math.round(bbox.x)
    y0 = Math.round(bbox.y + bbox.height) - 2

    # pondPixels are x, y offsets from a raster image, meaning x, y is the top left corner and y
    # increases downwards. However, the patches' y coordinates increase upwards.
    pondPatches = pondPixels.map ([x, y]) => @model.patches.patchXY x + x0 , y0 - y
    for p in pondPatches
      if p?
        p.type = "air"
        @model.patchChanged p
        # top of actual wastewater should be ~4 patches below ground level
        @pond.push(p) if p.y <= @head.y - 4

    # sort resulting patches first by height, then by lateral distance from well. This way they
    # fill up in a predictable order
    before = (a, b) -> (a.y < b.y) or (a.y == b.y and a.x < b.x)
    @pond.sort (a, b) ->
      return -1 if before b, a
      return 1 if before a, b
      return 0

    null

  # Given the image `img`, scales it so that 1 pixel of the drawn image corresponds to 1 patch (when
  # the image is drawn with @drawUI) and returns a list of the [x, y] coordinates of the empty
  # pixels in the interior of the image. These are found by flood filling all pixels with value 0,
  # starting at the center of the image.
  #
  # (Note that when the same image is drawn with @drawUI, each patch spans > 1.0 pixels. The 1:1 
  # scaling used in this method allows us to easily find the patches underneath the empty pixels of
  # the drawn image.)
  findEmptyPixels: (img) -> 
    scale = 0.5

    canvas = document.createElement 'canvas'
    canvas.width = img.width * scale
    canvas.height = img.height * scale
    ctx = canvas.getContext '2d'
    ctx.scale scale, scale
    ctx.drawImage img, 0, 0

    imageData = ctx.getImageData 0, 0, canvas.width, canvas.height

    w = imageData.width
    h = imageData.height

    visited = []
    visited.length = w*h
    loc = (x, y) -> w * y + x
    canVisit = (x, y) -> 0 <= x and x < w and 0 <= y and y < h and not visited[loc x, y]
    
    # imageData.data is a Uint8ClampedArray, in which each pixel is 4 consecutive 8-bit elements. 
    # Convert to an array of 32-bit elements, 1 per pixel.
    pixels = new Uint32Array imageData.data.buffer

    # a basic flood fill algorithm; see http://en.wikipedia.org/wiki/Flood_fill
    targetColor = 0
    interiorPixels = []
    q = [[Math.round(canvas.width / 2), Math.round(canvas.height / 2)]]
    while q.length > 0
      n = q.pop()
      [nx, ny] = n
      if pixels[loc nx, ny] == targetColor
        unless visited[loc nx, ny]
          interiorPixels.push n
          q.push([nx-1, ny]) if canVisit nx-1, ny
          q.push([nx+1, ny]) if canVisit nx+1, ny
          q.push([nx, ny-1]) if canVisit nx, ny-1
          q.push([nx, ny+1]) if canVisit nx, ny+1
      visited[loc nx, ny] = true

    interiorPixels

  leakWastePondWater: ->
    if @pondLeaks and @capped and @pond.length > 0 and ABM.util.randomInt(50) is 0
      @model.pondWaste += @model.pondWasteScale
      leakAreaWidth = @belowPond.xMax - @belowPond.xMin + 1
      @model.pondWater.create 1, (a)=>
        a.well = @
        a.moveTo @model.patches.patchXY @belowPond.xMin + ABM.util.randomInt(leakAreaWidth), @belowPond.y

  eraseUI: ->
    # TODO. Fix coordinate assumptions here. Also figure out if this is actually used!
    super
    ctx = @model.contexts.drawing
    ctx.save()
    ctx.globalCompositeOperation = "destination-out"
    ctx.translate @head.x, @head.y
    ctx.fillRect 0, -17, 30, 20
    ctx.restore()


  remove: ->
    if @explodingInProgress or @fillingInProgress or @frackingInProgress or @cappingInProgress
      setTimeout =>
        @remove()
      , 100
    else
      for p in @open.concat(@openShale, @filling, @exploding, @fracking, @pumping)
        p.isWell = null
        p.well = null
        @model.patchChanged p
      for p in @pond
        p.isWell = null
        p.well = null
        p.type = "land"
        @model.patchChanged p
      @open = @openShale = @filling = @exploding = @fracking = @pumping = @pond = []
      super

window.GasWell = GasWell