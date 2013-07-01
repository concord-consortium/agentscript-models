class LeakingFrackingControls extends FrackingControls
  pollutionGraph: null
  pollutionBaseline: 20
  setup: ->
    super
    @setupPollutionGraph()

  setupPollutionGraph: ->
    @pollutionGraph = Lab.grapher.Graph '#pollution-graph',
      title:  "Groundwater Pollution vs Time (years)"
      xlabel: "Time (years)"
      ylabel: "Methane"
      xmax:   40
      xmin:   0
      ymax:   500
      ymin:   0
      xTickCount: 4
      yTickCount: 5
      xFormatter: "3.3r"
      sample: 1
      realTime: true
      fontScaleRelativeToParent: true

    # start the graph at 0,20
    @pollutionGraph.addSamples [@pollutionBaseline]

    $(document).on FrackingModel.YEAR_ELAPSED, =>
      leaked = ABM.model.waterGas.length
      @pollutionGraph.addSamples [leaked + @pollutionBaseline]

window.LeakingFrackingControls = LeakingFrackingControls
$(document).trigger 'leaking-fracking-controls-loaded'
