class ImportExport
  @skipProperties: ["id", "p", "n", "n4", "agents"]
  @import: (model, state)->
    # TODO

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

  @_processSet: (objSet, breed)->
    return [[],[]] unless objSet? and objSet.length > 0
    props = ["breed"]
    vals = []

    for obj in objSet
      objVals = [breed]
      for own prop of obj
        continue if prop == "breed"
        if @skipProperties.indexOf(prop) == -1 and prop[0] != '_'
          if props.indexOf(prop) == -1
            props.push(prop)

          objVals[props.indexOf(prop)] = obj[prop]
      vals.push(objVals)

    return [props, vals]

window.ImportExport = ImportExport