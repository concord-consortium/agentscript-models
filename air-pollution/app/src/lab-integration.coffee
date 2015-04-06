require 'src/model'
require 'src/controls'

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
      when 'includeSunlight'
        model.includeSunlight = content.value
      when 'includeInversionLayer'
        model.includeInversionLayer = content.value
      when 'windSpeed'
        model.setWindSpeed content.value
      when 'numCars'
        model.setNumCars content.value
      when 'sunlightAmount'
        model.setSunlight content.value
      when 'rainRate'
        model.setRainRate content.value
      when 'carPollutionRate'
        model.carPollutionRate = content.value
      when 'carPollutionControl'
        model.carPollutionRate = 100 - content.value
      when 'electricCarPercentage'
        model.setElectricCarPercentage content.value
      when 'numFactories'
        model.setNumFactories content.value
      when 'factoryPollutionRate'
        model.factoryPollutionRate = content.value
      when 'factoryPollutionControl'
        model.factoryPollutionRate = 100 - content.value
      when 'temperature'
        model.temperature = content.value

  getOutputs = ->
    result =
      ticks: Math.floor(model.anim.ticks / model.graphSampleInterval)
      primaryAQI: model.primaryAQI()
      secondaryAQI: model.secondaryAQI()

    return result

  # Set initial output values.
  phone.post 'outputs', getOutputs()

  $(document).on AirPollutionModel.GRAPH_INTERVAL_ELAPSED, ->
    # We could also write:
    # phone.post('outputs', { ... })
    # phone.post('tick')
    # However Lab supports outputs in 'tick' handler too, so we can send only one message.
    phone.post 'tick',
      outputs: getOutputs()

  phone.initialize()
