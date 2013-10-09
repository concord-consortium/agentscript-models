class ImportExport
  @skipProperties: ["id", "p", "n", "n4", "agents"]
  @import: (model, state)->
    for items in [["patchProperties","patches"],["agentProperties","agents"],["linkProperties","links"]]
      props = state[items[0]]
      objs = state[items[1]]

      unless items[1] == "patches"
        for own breed of props
          model[breed].clear()

      for obj in objs
        breed = obj[0]
        if items[1] == "patches"
          # apply the values directly to the existing patches
          pxIdx = props[breed].indexOf('x')
          pyIdx = props[breed].indexOf('y')
          if pxIdx? and pyIdx?
            existingPatch = model[breed].patch(obj[pxIdx], obj[pyIdx])
            if existingPatch?
              @_applyValues existingPatch, props[breed], obj
            else
              console.log "No patch at (" + obj[pxIdx] + ", " + obj[pyIdx] + ")"
          else
            console.log "Missing x or y coordinate for patch!"
        else
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

    for patchSet in (ABM.patchBreeds || [model.patches])
      breed = patchSet.name
      [props, vals] = @_processSet(patchSet, breed)
      state.patchProperties[breed] = props
      state.patches = state.patches.concat(vals)

    for linkSet in (ABM.linkBreeds || [model.links])
      breed = linkSet.name
      [props, vals] = @_processSet(linkSet, breed)
      state.linkProperties[breed] = props
      state.links = state.links.concat(vals)

    return state

  @_applyValues: (obj, properties, values)->
    for prop,i in properties
      continue if prop == "breed"
      obj[prop] = values[i]

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

window.ImportExport = ImportExport