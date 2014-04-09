var assert = require("assert");
var axisProcessDrag = require("../lib/axis").axisProcessDrag;

describe("axis", function () {
  // axisProcessDrag((dragstart, currentdrag, domain);
  // => newDomain
  it("axisProcessDrag: (20, 10, [0, 40]) => [0, 80]", function() {
    assert.deepEqual(axisProcessDrag(20, 10, [0, 40]), [0, 80]);
  });
  it("axisProcessDrag: (60, 50, [40, 80]) => [40, 120]", function() {
    assert.deepEqual(axisProcessDrag(60, 50, [40, 80]), [40, 120]);
  });
  it("axisProcessDrag: (10, 20, [0, 40]) => [0, 20]", function() {
    assert.deepEqual(axisProcessDrag(10, 20, [0, 40]), [0, 20]);
  });
  it("axisProcessDrag: (20, 10, [-40, 40]) => [-80, 80]", function() {
    assert.deepEqual(axisProcessDrag(20, 10, [-40, 40]), [-80, 80]);
  });
  it("axisProcessDrag: (-60, -50, [-80, -40]) => [-120, -40]", function() {
    assert.deepEqual(axisProcessDrag(-60, -50, [-80, -40]), [-120, -40]);
  });
  it("axisProcessDrag: (-0.4, -0.2, [-1.0, 0.4]) => [-2.0, 0.8]", function() {
    assert.deepEqual(axisProcessDrag(-0.4, -0.2, [-1.0, 0.4]), [-2.0, 0.8]);
  });
  it("axisProcessDrag: (-0.2, -0.4, [-1.0, 0.4]) => [-0.5, 0.2]", function() {
    assert.deepEqual(axisProcessDrag(-0.2, -0.4, [-1.0, 0.4]), [-0.5, 0.2]);
  });
});
