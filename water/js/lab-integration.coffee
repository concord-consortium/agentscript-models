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

  registerCustomFunc 'stop', ->
    model.stop()

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
      when 'controls'
        processControls(content.value)

  getOutputs = ->
    result =
      month: model.getMonth()
      year: model.getYear()

    if model.getFractionalMonth() == model.getMonth()
      for well, i in model.wells
        result['well' + i] = well.killed
        well.killed = 0

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

  model.startCallback = ->
    # Notify iframe model that we received 'play' message and reacted appropriately.
    phone.post('play.iframe-model')

  model.stopCallback = ->
    # Notify iframe model that we received 'stop' message and reacted appropriately.
    phone.post('stop.iframe-model')

  phone.initialize()

layout = () ->
  newHeight = $(window).height()
  $('body').css('font-size', Math.min((newHeight / 20), 15) + 'px')
  controlsHeight = $('#controls').height()
  if controlsHeight
    margin = 6;
    $('#model').height(newHeight - controlsHeight - margin)

# Helper that hides or displays buttons, it's based on the provided hash.
processControls = (options) ->
  $controls = $('#controls')
  if options.draw
    $controls.find('.draw-group').removeClass('hidden')
  if options.remove
    $controls.find('.remove-group').removeClass('hidden')
    # Single option, e.g. water, well, layer.
    if typeof options.remove == 'string'
      # Select given option (it will update main button).
      $controls.find('.remove-option.' + options.remove).click()
      # Deactivate remove mode (activated by previous click).
      WaterControls.stopDraw()
      # Hide options.
      $controls.find('#remove-button-type').addClass('hidden')
    # Array of enabled options.
    if options.remove.length?
      # First, hide all the options and then show ones that were passed in array.
      $controls.find('.remove-option').closest('li').addClass('hidden')
      for opt in options.remove
        $controls.find('.remove-option.' + opt).closest('li').removeClass('hidden')
      # Select the first provided option (it will update main button).
      $controls.find('.remove-option.' + options.remove[0]).click()
      # Deactivate remove mode (activated by previous click).
      WaterControls.stopDraw()
  if options.water
    $controls.find('.water-btn').removeClass('hidden')
  if options.irrigationWell
    $controls.find('.irrigation-well-btn').removeClass('hidden')
  if options.removalWell
    $controls.find('.removal-well-btn').removeClass('hidden')
  # Call layout function, as controls have been modified.
  layout()
  # and make sure that layout is updated when window is resized.
  $(window).off '.lab-integration'
  $(window).on 'resize.lab-integration', layout
