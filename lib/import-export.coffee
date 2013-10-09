class ImportExport
  @skipProperties: ["id", "p", "n", "n4", "agents"]
  @import: (model, state)->
    # first, set up the patches
    props = state.patchProperties
    objs = state.patches

    for region in objs
      @_applyPatchRegion(region, props, model)

    for items in [["agentProperties","agents"],["linkProperties","links"]]
      props = state[items[0]]
      objs = state[items[1]]

      for own breed of props
        model[breed].clear()

      for obj in objs
        breed = obj[0]
        # apply the values to a newly created agent/link
        model[breed].create 1, (a)=>
          @_applyValues a, props[breed], obj
          a.setXY a.x, a.y

    oldRefreshPatches = model.refreshPatches
    model.refreshPatches = true
    model.draw()
    model.refreshPatches = oldRefreshPatches
    return true

  # returns an object representing the model state, which can be passed to import,
  # or JSON.stringify'd and persisted.
  @export: (model)->
    state = {
      agentProperties: {},
      agents: [],
      patchProperties: {},
      patches: [],
      linkProperties: {},
      links: []
    }

    for breedSet in (ABM.agentBreeds || [model.agents])
      breed = breedSet.name
      [props, vals] = @_processSet(breedSet, breed)
      state.agentProperties[breed] = props
      state.agents = state.agents.concat(vals)

    for linkSet in (ABM.linkBreeds || [model.links])
      breed = linkSet.name
      [props, vals] = @_processSet(linkSet, breed)
      state.linkProperties[breed] = props
      state.links = state.links.concat(vals)

    @_processPatches(model, state)

    return state

  @_applyValues: (obj, properties, values, setBreed=null)->
    for prop,i in properties
      if prop == "breed"
        if setBreed? and obj.changeBreed?
          obj.changeBreed setBreed
        continue

      obj[prop] = values[i] if values[i]?

  @_applyPatchRegion: (region, properties, model)->
    startX = region[0][0]
    startY = region[0][1]
    endX   = region[1][0]
    endY   = region[1][1]
    values = region[2]

    for y in [startY..endY] by -1
      for x in [(model.world.minX)..(model.world.maxX)] by 1
        if y == startY and x < startX
          continue
        else if y == endY and x > endX
          continue
        else
          # apply the values directly to the existing patches
          existingPatch = model.patches.patchXY(x, y)
          if existingPatch?
            @_applyValues existingPatch, properties, values
          else
            console.log "No patch at (" + x + ", " + y + ")"

  @_processSet: (objSet, breed)->
    return [[],[]] unless objSet? and objSet.length > 0
    props = ["breed"]
    vals = []

    for obj in objSet
      objVals = @_processObj(obj, props, breed)
      vals.push(objVals)

    return [props, vals]

  @_processObj: (obj, props, breed, skip=[])->
    objVals = [breed]
    for own prop of obj
      continue if prop == "breed"
      if @skipProperties.indexOf(prop) == -1 and skip.indexOf(prop) == -1 and prop[0] != '_'
        if props.indexOf(prop) == -1
          props.push(prop)

        objVals[props.indexOf(prop)] = obj[prop]
    return objVals

  @_processPatches: (model, state)->
    startPatch = prevPatch = currentPatch = null
    props = ['breed']
    for y in [(model.world.maxY)..(model.world.minY)] by -1
      for x in [(model.world.minX)..(model.world.maxX)] by 1
        currentPatch = model.patches.patchXY x, y
        if startPatch?
          if @_unequal(startPatch, currentPatch)
            state.patches.push([[startPatch.x, startPatch.y],[prevPatch.x, prevPatch.y],@_processObj(startPatch, props, startPatch.breed.name, ['x','y'])])
            startPatch = currentPatch
        else
          startPatch = currentPatch
        prevPatch = currentPatch
    state.patches.push([[startPatch.x, startPatch.y],[prevPatch.x, prevPatch.y],@_processObj(startPatch, props, startPatch.breed.name, ['x','y'])])
    state.patchProperties = props

  @_unequal: (obj1, obj2)->
    obj1State = @_processObj(obj1, [], obj1.breed.name, ['x','y'])
    obj2State = @_processObj(obj2, [], obj2.breed.name, ['x','y'])
    return !(JSON.stringify(obj1State) == JSON.stringify(obj2State))

window.ImportExport = ImportExport