class LeakingFrackingControls extends FrackingControls
  pollutionGraph: null
  pollutionBaseline: 20
  pondPollutionBaseline: 10
  leakingSetupCompleted: false
  setup: ->
    super
    @setupPollutionGraph() unless @leakingSetupCompleted
    @leakingSetupCompleted = true

  setupPollutionGraph: ->
    @pollutionGraph = LabGrapher '#pollution-graph',
      title:  "Pollution: Methane (red), Wastewater (green) vs Time"
      xlabel: "Time (years)"
      ylabel: ""
      xmax:   40
      xmin:   0
      ymax:   60
      ymin:   0
      xTickCount: 4
      yTickCount: 0
      xFormatter: "3.3r"
      sample: 1
      realTime: true
      fontScaleRelativeToParent: true
      dataColors: [
        [160,   0,   0],
        [ 44, 160,   0],
        [ 44,   0, 160],
        [  0,   0,   0],
        [255, 127,   0],
        [255,   0, 255]]

    # start the graph at 0,20
    @pollutionGraph.addSamples [[@pollutionBaseline],[@pondPollutionBaseline]]

    $(document).on FrackingModel.YEAR_ELAPSED, =>
      leaked = ABM.model.waterGas.length
      pondLeaked = ABM.model.pondWater.length
      @pollutionGraph.addSamples [[leaked + @pollutionBaseline], [pondLeaked + @pondPollutionBaseline]]

window.LeakingFrackingControls = LeakingFrackingControls
$(document).trigger 'leaking-fracking-controls-loaded'
