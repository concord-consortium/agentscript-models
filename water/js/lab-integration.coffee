window.setupLabCommunication = (model) ->
  phone = iframePhone.getIFrameEndpoint()
  optionalOutputs = {}

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
    # Notify iframe model that we received 'play' message and reacted appropriately.
    phone.post('play.iframe-model')

  registerCustomFunc 'stop', ->
    model.stop()
    # Notify iframe model that we received 'stop' message and reacted appropriately.
    phone.post('stop.iframe-model')

  registerCustomFunc 'step', (content) ->
    steps = content
    while (steps--)
      model.step()
    model.draw()

  registerModelFunc('addRainSpotlight');
  registerModelFunc('removeSpotlight');

  # Properties.
  phone.addListener 'set', (content) ->
    switch content.name
      when 'template'
        model.setTemplate content.value
      when 'rainProbability'
        model.rainProbability = content.value
      when 'evapProbability'
        model.evapProbability = content.value
      when 'rainCountOptions'
        # This property is a bit complex. When you set 'rainCountOptions', it activates rain counting on
        # every month change. Result is available as 'rainCount' output. It's following the same
        # behaviour and naming convention that was used in the original model.
        countOptions = content.value
        center = model.patches.patchXY countOptions.x, countOptions.y
        optionalOutputs.rainCount = ->
          # Calculate value only when month changes. This is following the original model behaviour.
          return undefined if model.getFractionalMonth() != model.getMonth()
          model.rainCount center, countOptions.dx, countOptions.dy, true, countOptions.debug

  getOutputs = ->
    result =
      month: model.getMonth()
      year: model.getYear()
    for name, valueFunc of optionalOutputs
      val = valueFunc()
      # Skip if output returns undefined or null.
      result[name] = val if val?

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

  phone.initialize()
