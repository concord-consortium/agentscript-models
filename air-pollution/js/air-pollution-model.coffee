class AirPollutionModel extends ABM.Model
  mountainsX: 410
  windSpeed: 0
  carDensity: 5
  factoryDensity: 5

  setup: ->
    @anim.setRate 30, false
    @setFastPatches()
    @patches.usePixels true
    @setTextParams {name: "drawing"}, "10px sans-serif"
    @setLabelParams {name: "drawing"}, [255,255,255], [0,-20]

    @patches.importColors "img/air-pollution-bg-mask.png"
    @patches.importDrawing "img/air-pollution-bg.png"

    carImg = document.getElementById('car-sprite')
    factoryImg = document.getElementById('factory-sprite')

    ABM.shapes.add "left-car", false, (ctx)->
      ctx.scale(-1, 1) # if heading leftward...
      ctx.rotate ABM.util.degToRad(180)
      ctx.drawImage(carImg, 0, 0)
    ABM.shapes.add "right-car", false, (ctx)->
      ctx.rotate ABM.util.degToRad(180)
      ctx.drawImage(carImg, 0, 0)
    ABM.shapes.add "factory", false, (ctx)->
      ctx.scale(-1, 1)
      ctx.rotate ABM.util.degToRad(180)
      ctx.drawImage(factoryImg, 0, 0)

    @agentBreeds "wind cars factories primary secondary"

    @setupFactories()
    @setupWind()
    @setupCars()

    @draw()
    @refreshPatches = false

    $(document).trigger 'model-ready'

  reset: ->
    super
    @setup()
    @anim.draw()

  step: ->
    @moveWind()
    return

  setupWind: ->
    @wind.setDefaultSize 5
    @wind.setDefaultColor [0, 0, 255]
    @wind.setDefaultShape "arrow"
    @wind.setDefaultHidden true
    @wind.setDefaultHeading 0

    @wind.create 15, (w)=>
      row = Math.floor((@wind.length-1) / 5)
      x = ((@wind.length-1) % 5) * 90 + (row * 30)
      y = row * 30 + 100
      w.moveTo @patches.patchXY(x,y)

  setupCars: ->
    console.log "car setup"
    @cars.setDefaultSize 1
    @cars.setDefaultHeading ABM.util.degToRad 180
    @cars.setDefaultShape "left-car"
    @cars.setDefaultColor [0,0,0]
    @cars.setDefaultHidden false

    @cars.create 1, (c)=>
      c.moveTo @patches.patchXY 520, 40

  setupFactories: ->
    console.log "factory setup"
    @factories.setDefaultSize 1
    @factories.setDefaultHeading ABM.util.degToRad 180
    @factories.setDefaultShape "factory"
    @factories.setDefaultColor [0,0,0]
    @factories.setDefaultHidden false

    @factories.create 1, (c)=>
      c.moveTo @patches.patchXY 160, 160

  setWindSpeed: (speed)->
    @windSpeed = speed
    for w in @wind
      w.hidden = (speed is 0)
      w.size = Math.abs(@_intSpeed(10)) + 5
      w.heading = if speed >= 0 then 0 else ABM.util.degToRad(180)

    @draw() if @anim.animStop

  moveWind: ->
    speed = @_intSpeed(15)
    for w in @wind
      y = w.y
      x = w.x+speed
      if x > @mountainsX
        x = x-@mountainsX
      else if x < 0
        x = x+@mountainsX
      w.moveTo @patches.patchXY x, y

  _intSpeed: (divisor)->
    speed = @windSpeed/divisor
    return if @windSpeed < 0 then Math.floor(speed) else Math.ceil(speed)

window.AirPollutionModel = AirPollutionModel
$(document).trigger 'air-pollution-model-loaded'