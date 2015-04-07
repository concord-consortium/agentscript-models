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

  # Properties.
  phone.addListener 'set', (content) ->
    switch content.name
      when 'wind'
        wind = content.value
        vx = wind.magnitude*Math.cos(wind.direction)/30
        vy = wind.magnitude*Math.sin(wind.direction)/30

        model.setWindSpeed vx, vy

  getOutputs = ->
    result =
      cityAQuality: model.aQuality
      cityBQuality: model.bQuality
      cityCQuality: model.cQuality

    return result

  # Set initial output values.
  phone.post 'outputs', getOutputs()

  $(document).on 'tick', ->
    # We could also write:
    # phone.post('outputs', { ... })
    # phone.post('tick')
    # However Lab supports outputs in 'tick' handler too, so we can send only one message.
    phone.post 'tick',
      outputs: getOutputs()

  phone.initialize()

labIntegrationLoaded.resolve()
