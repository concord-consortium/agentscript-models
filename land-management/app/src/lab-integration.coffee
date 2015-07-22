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
      when 'userPrecipitation'
        model.setUserPrecipitation content.value
        updatePrecipitationBarchart model.getCurrentClimateData()
        # Update precipitation output value
        phone.post 'outputs', getOutputs()
      when 'climate'
        model.setClimate content.value
        updatePrecipitationBarchart model.getCurrentClimateData()
        # Update precipitation output value
        phone.post 'outputs', getOutputs()
      when 'showErosion'
        model.showErosion = content.value
      when 'showSoilQuality'
        model.showSoilQuality = content.value
      when 'showSoilQuality'
        model.showSoilQuality = content.value
      when 'showPrecipitationGraph'
        if content.value
          $('#precipitation-data').show()
        else
          $('#precipitation-data').hide()
      when 'landType'
        model.setLandType(content.value)
        model.reset()
      when 'zone1Slope'
        model.zone1Slope = content.value
        model.reset()
      when 'zone2Slope'
        model.zone2Slope = content.value
        model.reset()
      when 'zone1Planting'
        model.setZoneManagement 0, content.value
      when 'zone2Planting'
        model.setZoneManagement 1, content.value

  makeSmoothed = ->
    s = null
    alpha = 0.3
    (x) -> if s is null then (s = x) else (s = alpha * x + (1 - alpha) * s)

  zone1Smoothed = makeSmoothed()
  zone2Smoothed = makeSmoothed()

  getOutputs = ->
    topsoilInZone = model.topsoilInZones()
    result =
      year: model.getFractionalYear()
      precipitation: model.precipitation
      topsoilInZone1: topsoilInZone[1]
      topsoilInZone2: topsoilInZone[2]
      zone1ErosionCount: zone1Smoothed(model.zone1ErosionCount)
      zone2ErosionCount: zone2Smoothed(model.zone2ErosionCount)
    model.resetErosionCounts()
    result

  # Set initial output values.
  phone.post 'outputs', getOutputs()

  $(document).on LandManagementModel.STEP_INTERVAL_ELAPSED, ->
    # We could also write:
    # phone.post('outputs', { ... })
    # phone.post('tick')
    # However Lab supports outputs in 'tick' handler too, so we can send only one message.
    phone.post 'tick',
      outputs: getOutputs()

  phone.initialize()
