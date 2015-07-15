window.setupLabCommunication = (model) ->
  phone = iframePhone.getIFrameEndpoint()

  # Register Scripting API functions.
  registerModelFunc = (name) ->
    phone.addListener name, ->
      model[name].apply(model, arguments)
      model.draw()

    phone.post('registerScriptingAPIFunc', name)

  registerCustomFunc = (name, func) ->
    phone.addListener(name, func)
    phone.post('registerScriptingAPIFunc', name)

  registerCustomFunc 'play', ->
    model.start()

  registerCustomFunc 'stop', ->
    model.stop()

  registerCustomFunc 'step', (content) ->
    steps = content
    while (steps--)
      model.step()
    model.draw()

  registerModelFunc('explode')
  registerModelFunc('floodWater')
  registerModelFunc('floodPropane')
  registerModelFunc('pumpOut')

  # Properties.
  phone.addListener 'set', (content) ->
    switch content.name
      when 'leaks'
        model.leaks = content.value
      when 'drillDirection'
        model.drillDirection = content.value


  getOutputs = ->
    result =
      year: model.getYear()
      removeFluidPossible: false
      fillPossible: false
      explosionPossible: false

    for w in model.wells
      continue if w.capped or w.explodingInProgress or w.fillingInProgress or w.frackingInProgress or w.cappingInProgress
      if w.fracked
        result.removeFluidPossible = true
      else if w.filled
        # do nothing - we're automatically forwarded to the fracking stage.
      else if w.exploded and w.exploding.length <= 0
        result.fillPossible = true
      else if w.goneHorizontal
        result.explosionPossible = true

    if model.getFractionalYear() == model.getYear()
      for well, i in model.wells
        result['well' + i] = well.killed
        well.killed = 0
      result.wellsCombined = model.killed
      model.killed = 0

      result.leakedMethane = model.baseMethaneInWater + model.leakedMethane
      model.leakedMethane *= 0.6

      result.pondWaste = model.pondWaste
      model.pondWaste *= 0.6

    return result

  # Set initial output values.
  phone.post 'outputs', getOutputs()

  model.stepCallback = ->
    # We could also write:
    # phone.post('outputs', { ... })
    # phone.post('tick')
    # However Lab supports outputs in 'tick' handler too, so we can send only one message.
    phone.post 'tick',
      outputs: getOutputs()

  model.startCallback = ->
    # Notify iframe model that we received 'play' message and reacted appropriately.
    phone.post('play.iframe-model')

  model.stopCallback = ->
    # Notify iframe model that we received 'stop' message and reacted appropriately.
    phone.post('stop.iframe-model')

  phone.initialize()
