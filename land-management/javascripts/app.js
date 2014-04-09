(function(/*! Brunch !*/) {
  'use strict';

  var globals = typeof window !== 'undefined' ? window : global;
  if (typeof globals.require === 'function') return;

  var modules = {};
  var cache = {};

  var has = function(object, name) {
    return ({}).hasOwnProperty.call(object, name);
  };

  var expand = function(root, name) {
    var results = [], parts, part;
    if (/^\.\.?(\/|$)/.test(name)) {
      parts = [root, name].join('/').split('/');
    } else {
      parts = name.split('/');
    }
    for (var i = 0, length = parts.length; i < length; i++) {
      part = parts[i];
      if (part === '..') {
        results.pop();
      } else if (part !== '.' && part !== '') {
        results.push(part);
      }
    }
    return results.join('/');
  };

  var dirname = function(path) {
    return path.split('/').slice(0, -1).join('/');
  };

  var localRequire = function(path) {
    return function(name) {
      var dir = dirname(path);
      var absolute = expand(dir, name);
      return globals.require(absolute, path);
    };
  };

  var initModule = function(name, definition) {
    var module = {id: name, exports: {}};
    cache[name] = module;
    definition(module.exports, localRequire(name), module);
    return module.exports;
  };

  var require = function(name, loaderPath) {
    var path = expand(name, '.');
    if (loaderPath == null) loaderPath = '/';

    if (has(cache, path)) return cache[path].exports;
    if (has(modules, path)) return initModule(path, modules[path]);

    var dirIndex = expand(path, './index');
    if (has(cache, dirIndex)) return cache[dirIndex].exports;
    if (has(modules, dirIndex)) return initModule(dirIndex, modules[dirIndex]);

    throw new Error('Cannot find module "' + name + '" from '+ '"' + loaderPath + '"');
  };

  var define = function(bundle, fn) {
    if (typeof bundle === 'object') {
      for (var key in bundle) {
        if (has(bundle, key)) {
          modules[key] = bundle[key];
        }
      }
    } else {
      modules[bundle] = fn;
    }
  };

  var list = function() {
    var result = [];
    for (var item in modules) {
      if (has(modules, item)) {
        result.push(item);
      }
    }
    return result;
  };

  globals.require = require;
  globals.require.define = define;
  globals.require.register = define;
  globals.require.list = list;
  globals.require.brunch = true;
})();
require.register("src/controls", function(exports, require, module) {
var $precipitationSlider, $precipitationSliderDiv, $slopeSlidersDiv, $zone1Slider, $zone2Slider, enableZoneSliders, erosionGraph, reset, setupGraphs, updatePrecipitationBarchart, zone1Planting, zone2Planting;

$precipitationSlider = $("#precipitation-slider");

$precipitationSliderDiv = $("#user-precipitation");

$zone1Slider = $("#zone-1-slider");

$zone2Slider = $("#zone-2-slider");

$slopeSlidersDiv = $("#slope-sliders");

erosionGraph = null;

zone1Planting = "";

zone2Planting = "";

enableZoneSliders = function(enable) {
  $zone1Slider.slider(enable ? "enable" : "disable");
  $zone2Slider.slider(enable ? "enable" : "disable");
  if (enable) {
    return $slopeSlidersDiv.removeClass("disabled");
  } else {
    return $slopeSlidersDiv.addClass("disabled");
  }
};

updatePrecipitationBarchart = function(data) {
  return $(".inner-bar").each(function(i) {
    var $this, height, margin, normalized, precip;
    $this = $(this);
    precip = data[i];
    normalized = precip / 500;
    height = 55 * normalized;
    margin = 55 - height;
    $this.stop(true);
    $this.animate({
      height: height,
      marginTop: margin,
      alt: height
    });
    return $this.parent().attr({
      title: precip
    });
  });
};

$(function() {
  $("button").button();
  $("#playback").buttonset();
  $(".icon-pause").hide();
  $(".chosen-select").chosen({
    disable_search: true,
    width: 158
  });
  $precipitationSlider.slider({
    min: 0,
    max: 500,
    step: 1,
    value: 166
  });
  $zone1Slider.slider({
    min: -5,
    max: 5,
    step: 1,
    value: 0
  });
  $zone2Slider.slider({
    min: -5,
    max: 5,
    step: 1,
    value: 0
  });
  enableZoneSliders(false);
  return $precipitationSlider.slider("disable");
});

window.initControls = function() {
  $('#date-string').text(model.dateString);
  setupGraphs();
  return updatePrecipitationBarchart(model.getCurrentClimateData());
};

reset = function() {
  model.stop();
  $(".icon-pause").hide();
  $(".icon-play").show();
  model.reset();
  if (erosionGraph != null) {
    return erosionGraph.reset();
  }
};

$('#play-pause-button').click(function() {
  if (model.anim.animStop) {
    model.start();
    $(".icon-pause").show();
    return $(".icon-play").hide();
  } else {
    model.stop();
    $(".icon-pause").hide();
    return $(".icon-play").show();
  }
});

$('#reset-button').click(reset);

$("#terrain-options").change(function(evt, ui) {
  var selection;
  selection = ui.selected;
  model.setLandType(selection);
  reset();
  return enableZoneSliders(selection === "Sliders");
});

$("#zone1-planting-options").change(function(evt, ui) {
  var selection;
  selection = ui.selected;
  model.setZoneManagement(0, selection);
  if (!(~selection.indexOf("wheat") && ~zone1Planting.indexOf("wheat"))) {
    reset();
  }
  return zone1Planting = selection;
});

$("#zone2-planting-options").change(function(evt, ui) {
  var selection;
  selection = ui.selected;
  model.setZoneManagement(1, selection);
  if (!(~selection.indexOf("wheat") && ~zone2Planting.indexOf("wheat"))) {
    reset();
  }
  return zone2Planting = selection;
});

$precipitationSlider.on('slide', function(event, ui) {
  model.setUserPrecipitation(ui.value);
  updatePrecipitationBarchart(model.getCurrentClimateData());
  return $("#precipitation-value").text(model.precipitation);
});

$("#climate-options").change(function(evt, ui) {
  var enable, selection;
  selection = ui.selected;
  model.setClimate(selection);
  enable = selection === "user";
  $precipitationSlider.slider(enable ? "enable" : "disable");
  if (enable) {
    $precipitationSliderDiv.removeClass("disabled");
  } else {
    $precipitationSliderDiv.addClass("disabled");
  }
  updatePrecipitationBarchart(model.getCurrentClimateData());
  return $("#precipitation-value").text(model.precipitation);
});

$zone1Slider.on('slide', function(event, ui) {
  model.zone1Slope = ui.value;
  return reset();
});

$zone2Slider.on('slide', function(event, ui) {
  model.zone2Slope = ui.value;
  return reset();
});

$('input.property').click(function() {
  var $this, checked, property;
  $this = $(this);
  property = $this.attr('id');
  checked = $this.is(':checked');
  model[property] = checked;
  return true;
});

setupGraphs = function() {
  if ($('#erosion-graph').length) {
    return erosionGraph = LabGrapher('#erosion-graph', {
      title: "Erosion Rates",
      xlabel: "Time (year)",
      ylabel: "Monthly Erosion",
      xmax: 2020,
      xmin: 2013,
      ymax: 100,
      ymin: 0,
      xTickCount: 4,
      yTickCount: 5,
      xFormatter: "d",
      dataSampleStart: 2013,
      sampleInterval: 1 / 60,
      realTime: true,
      fontScaleRelativeToParent: true,
      dataColors: [[160, 0, 0], [44, 160, 0], [44, 0, 160], [0, 0, 0], [255, 127, 0], [255, 0, 255]]
    });
  }
};

$(document).on(LandManagementModel.STEP_INTERVAL_ELAPSED, function() {
  $('#date-string').text(model.dateString);
  if (erosionGraph) {
    erosionGraph.addSamples([0, 0, 0, 0, model.zone1ErosionCount, model.zone2ErosionCount]);
  }
  return model.resetErosionCounts();
});

$(document).on(LandManagementModel.STEP_INTERVAL_ELAPSED, function() {
  $(".inner-bar").removeClass("current-month");
  $($(".inner-bar")[model.month]).addClass("current-month");
  return $("#precipitation-value").text(model.precipitation);
});
});

;require.register("src/erosion-engine", function(exports, require, module) {
var DARK_LAND_COLOR, ErosionEngine, GOOD_SOIL_COLOR, LAND, LIGHT_LAND_COLOR, MAGENTA, ORANGE, POOR_SOIL_COLOR, SKY, SKY_COLOR, TERRACE_COLOR;

SKY_COLOR = [131, 216, 240];

LIGHT_LAND_COLOR = [135, 79, 49];

DARK_LAND_COLOR = [105, 49, 19];

TERRACE_COLOR = [60, 60, 60];

GOOD_SOIL_COLOR = [88, 41, 10];

POOR_SOIL_COLOR = [193, 114, 7];

MAGENTA = [255, 0, 255];

ORANGE = [255, 127, 0];

SKY = "sky";

LAND = "land";

ErosionEngine = (function() {
  var climate, climateData, erosionProbability, maxSlope, u, userPrecipitation;

  function ErosionEngine() {}

  u = ABM.util;

  climateData = {
    temperate: {
      precipitation: [22, 26, 43, 73, 108, 115, 89, 93, 95, 58, 36, 27]
    },
    tropical: {
      precipitation: [200, 290, 380, 360, 280, 120, 80, 40, 30, 30, 70, 100]
    },
    arid: {
      precipitation: [11.4, 13.2, 23.5, 8.8, 14.8, 34.1, 133.1, 120.2, 47, 7.8, 7.7, 6.8]
    }
  };

  climate = climateData.temperate;

  userPrecipitation = 166;

  ErosionEngine.prototype.precipitation = 0;

  erosionProbability = 30;

  maxSlope = 2;

  ErosionEngine.prototype.showErosion = true;

  ErosionEngine.prototype.zone1ErosionCount = 0;

  ErosionEngine.prototype.zone2ErosionCount = 0;

  ErosionEngine.prototype.showSoilQuality = false;

  ErosionEngine.prototype.setSoilDepths = function() {
    var lastDepth, p, x, y, zone, _i, _ref, _ref1, _results;
    this.surfaceLand = [];
    _results = [];
    for (x = _i = _ref = this.patches.minX, _ref1 = this.patches.maxX; _ref <= _ref1 ? _i <= _ref1 : _i >= _ref1; x = _ref <= _ref1 ? ++_i : --_i) {
      lastDepth = -1;
      _results.push((function() {
        var _j, _ref2, _ref3, _results1;
        _results1 = [];
        for (y = _j = _ref2 = this.patches.maxY, _ref3 = this.patches.minY; _ref2 <= _ref3 ? _j <= _ref3 : _j >= _ref3; y = _ref2 <= _ref3 ? ++_j : --_j) {
          if (lastDepth >= this.MAX_INTERESTING_SOIL_DEPTH) {
            break;
          }
          p = this.patches.patch(x, y);
          if (p.type === SKY) {
            continue;
          }
          p.depth = ++lastDepth;
          p.isTopsoil = true;
          p.color = this.showErosion && p.eroded ? p.zone === 1 ? ORANGE : MAGENTA : p.isTerrace ? TERRACE_COLOR : !this.showSoilQuality ? LIGHT_LAND_COLOR : (zone = p.x <= 0 ? 0 : 1, p.quality < this.soilQuality[zone] ? p.quality += 0.001 : void 0, p.quality > this.soilQuality[zone] ? p.quality -= 0.001 : void 0, p.quality < 0.5 ? POOR_SOIL_COLOR : p.quality > 1.5 ? GOOD_SOIL_COLOR : LIGHT_LAND_COLOR);
          if (p.depth === 0) {
            _results1.push(this.surfaceLand.push(p));
          } else {
            _results1.push(void 0);
          }
        }
        return _results1;
      }).call(this));
    }
    return _results;
  };

  ErosionEngine.prototype.erode = function() {
    var a, direction, i, localErosionProbability, localSlope, n, p, probabilityOfErosion, slopeContribution, target, totalVegetationSize, vegetation, vegetationStoppingPower, vegetiationContribution, _i, _j, _k, _l, _len, _len1, _len2, _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6, _results;
    _ref = this.surfaceLand;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      p = _ref[_i];
      p.skyCount = 0;
      _ref1 = p.n;
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        n = _ref1[_j];
        if ((n != null ? n.type : void 0) === SKY) {
          p.skyCount++;
        }
      }
      if (p.y === this.patches.maxY) {
        p.skyCount += 3;
      }
    }
    this.surfaceLand.sort(function(a, b) {
      if (a.skyCount <= b.skyCount) {
        return 1;
      } else {
        return -1;
      }
    });
    _results = [];
    for (i = _k = 0, _ref2 = this.surfaceLand.length / 2; _k < _ref2; i = _k += 1) {
      p = this.surfaceLand[i];
      localSlope = this.getLocalSlope(p.x, p.y);
      slopeContribution = 0.35 * Math.abs(localSlope / 2);
      vegetation = this.getLocalVegetation(p.x, p.y);
      totalVegetationSize = 0;
      for (_l = 0, _len2 = vegetation.length; _l < _len2; _l++) {
        a = vegetation[_l];
        totalVegetationSize += (a.isBody ? a.size / 3 : a.isRoot ? a.size * 2 / 3 : a.size);
      }
      vegetationStoppingPower = Math.min(totalVegetationSize / 5, 0.99);
      vegetiationContribution = 0.65 * (1 - vegetationStoppingPower);
      localErosionProbability = erosionProbability / p.stability;
      probabilityOfErosion = localErosionProbability * (this.precipitation / 400) * (slopeContribution + vegetiationContribution);
      if (u.randomFloat(100) > probabilityOfErosion) {
        continue;
      }
      direction = p.direction || (direction = 1 - (u.randomInt(2) * 2));
      if (p.x === this.patches.minX && direction === -1 || p.x === this.patches.maxX && direction === 1) {
        target = null;
      } else if (((_ref3 = p.n[1 + direction]) != null ? _ref3.type : void 0) === SKY) {
        target = p.n[1 + direction];
      } else if (((_ref4 = p.n[1 - direction]) != null ? _ref4.type : void 0) === SKY) {
        target = p.n[1 - direction];
        direction = direction * -1;
      } else if (((_ref5 = p.n[3.5 + (direction / 2)]) != null ? _ref5.type : void 0) === SKY) {
        target = p.n[3.5 + (direction / 2)];
      } else if (((_ref6 = p.n[3.5 - (direction / 2)]) != null ? _ref6.type : void 0) === SKY) {
        target = p.n[3.5 - (direction / 2)];
        direction = direction * -1;
      } else {
        p.direction = 0;
        continue;
      }
      if (p.x < 0) {
        this.zone1ErosionCount++;
      } else {
        this.zone2ErosionCount++;
      }
      p.type = SKY;
      p.color = SKY_COLOR;
      p.eroded = false;
      if (target != null) {
        while (target.n[1].type === SKY) {
          target = target.n[1];
        }
        target.type = LAND;
        target.direction = direction;
        target.eroded = true;
        target.zone = p.zone;
        target.stability = p.stability;
        target.isTerrace = p.isTerrace;
        _results.push(target.quality = p.quality);
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  };

  ErosionEngine.prototype.getBoxAroundPoint = function(x, y, xStep, yStep) {
    var bottom, leftEdge, rightEdge, top;
    xStep = 3;
    yStep = 5;
    leftEdge = Math.max(x - xStep, this.patches.minX);
    rightEdge = Math.min(x + xStep, this.patches.maxX);
    top = Math.min(y + yStep, this.patches.maxY);
    bottom = Math.max(y - yStep, this.patches.minY);
    return [leftEdge, rightEdge, top, bottom];
  };

  ErosionEngine.prototype.getLocalSlope = function(x, y) {
    var bottom, leftEdge, leftHeight, rightEdge, rightHeight, slope, top, _ref;
    _ref = this.getBoxAroundPoint(x, y, 3, 5), leftEdge = _ref[0], rightEdge = _ref[1], top = _ref[2], bottom = _ref[3];
    leftHeight = bottom;
    rightHeight = bottom;
    while (leftHeight < top && this.patches.patch(leftEdge, leftHeight).type === LAND) {
      leftHeight++;
    }
    while (rightHeight < top && this.patches.patch(rightEdge, rightHeight).type === LAND) {
      rightHeight++;
    }
    return slope = (rightHeight - leftHeight) / (rightEdge - leftEdge);
  };

  ErosionEngine.prototype.getLocalVegetation = function(x, y) {
    var bottom, leftEdge, rightEdge, top, vegetation, _i, _j, _ref;
    _ref = this.getBoxAroundPoint(x, y, 5, 5), leftEdge = _ref[0], rightEdge = _ref[1], top = _ref[2], bottom = _ref[3];
    vegetation = [];
    for (x = _i = leftEdge; leftEdge <= rightEdge ? _i <= rightEdge : _i >= rightEdge; x = leftEdge <= rightEdge ? ++_i : --_i) {
      for (y = _j = bottom; bottom <= top ? _j <= top : _j >= top; y = bottom <= top ? ++_j : --_j) {
        vegetation.push.apply(vegetation, this.patches.patch(x, y).agents);
      }
    }
    return vegetation;
  };

  ErosionEngine.prototype.resetErosionCounts = function() {
    this.zone1ErosionCount = 0;
    return this.zone2ErosionCount = 0;
  };

  ErosionEngine.prototype.setClimate = function(c) {
    climate = c !== "user" ? climateData[c] : null;
    return this.updatePrecipitation();
  };

  ErosionEngine.prototype.setUserPrecipitation = function(p) {
    userPrecipitation = p;
    if (climate == null) {
      return this.precipitation = userPrecipitation;
    }
  };

  ErosionEngine.prototype.updatePrecipitation = function() {
    if (climate) {
      return this.precipitation = climate.precipitation[this.month];
    } else {
      return this.precipitation = userPrecipitation;
    }
  };

  ErosionEngine.prototype.getCurrentClimateData = function() {
    var i;
    if (climate) {
      return climate.precipitation;
    } else {
      return (function() {
        var _i, _results;
        _results = [];
        for (i = _i = 0; _i < 12; i = ++_i) {
          _results.push(userPrecipitation);
        }
        return _results;
      })();
    }
  };

  return ErosionEngine;

})();

window.ErosionEngine = ErosionEngine;
});

;require.register("src/land-generator", function(exports, require, module) {
var DARK_LAND_COLOR, LAND, LIGHT_LAND_COLOR, LandGenerator, SKY, SKY_COLOR, TERRACE_COLOR;

SKY_COLOR = [131, 216, 240];

LIGHT_LAND_COLOR = [135, 79, 49];

DARK_LAND_COLOR = [105, 49, 19];

TERRACE_COLOR = [60, 60, 60];

SKY = "sky";

LAND = "land";

LandGenerator = (function() {
  var amplitude, type, u;

  function LandGenerator() {}

  u = ABM.util;

  type = "Plain";

  amplitude = -4;

  LandGenerator.prototype.zone1Slope = 0;

  LandGenerator.prototype.zone2Slope = 0;

  LandGenerator.prototype.setupLand = function() {
    var p, _i, _len, _ref;
    this.skyPatches = [];
    this.landPatches = [];
    _ref = this.patches;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      p = _ref[_i];
      p.zone = p.x <= 0 ? 1 : 2;
      p.isTopsoil = false;
      if (p.y > this.landShapeFunction(p.x)) {
        p.color = SKY_COLOR;
        p.type = SKY;
        p.depth = -1;
        this.skyPatches.push(p);
      } else {
        p.color = DARK_LAND_COLOR;
        p.type = LAND;
        p.depth = this.MAX_INTERESTING_SOIL_DEPTH;
        p.eroded = false;
        p.erosionDirection = 0;
        p.stability = 1;
        p.quality = 1;
        this.landPatches.push(p);
        if (type === "Terraced" && p.x < 0 && ((p.x % Math.floor(this.patches.minX / 5) === 0 && p.y > this.landShapeFunction(p.x - 1)) || ((p.x - 1) % Math.floor(this.patches.minX / 5) === 0 && p.y > this.landShapeFunction(p.x - 2)))) {
          p.isTerrace = true;
          p.color = TERRACE_COLOR;
          p.stability = 100;
        }
      }
    }
    return this.setSoilDepths();
  };

  LandGenerator.prototype.setLandType = function(t) {
    type = t;
    switch (type) {
      case "Nearly Flat":
        return amplitude = -0.00001;
      case "Plain":
        return amplitude = -4;
      case "Rolling":
        return amplitude = -10;
      case "Hilly":
        return amplitude = -20;
      default:
        return amplitude = 0;
    }
  };

  LandGenerator.prototype.landShapeFunction = function(x) {
    var midHeight, modelHeight, slope, step, val;
    if (type === "Terraced") {
      modelHeight = this.patches.maxY - this.patches.minY;
      if (x < 0) {
        step = Math.floor((x + 1) / (this.patches.minX / 5));
        return this.patches.minY + modelHeight * (0.6 - (0.1 * step));
      } else {
        return -25 * Math.sin(u.degToRad(x - 20)) - 1;
      }
    } else if (type === "Sliders") {
      slope = x < 0 ? this.zone1Slope : this.zone2Slope;
      slope /= 10;
      midHeight = this.zone1Slope > 3 && this.zone2Slope < -3 ? 6 : this.zone1Slope > 2 || this.zone2Slope < -2 ? 0 : this.zone1Slope < -3 && this.zone2Slope > 3 ? -22 : this.zone1Slope < -2 || this.zone2Slope > 2 ? -15 : -12;
      val = x * slope + midHeight;
      return Math.min(this.patches.maxY, Math.max(this.patches.minY, val));
    } else {
      return amplitude * Math.sin(u.degToRad(x - 10));
    }
  };

  return LandGenerator;

})();

window.LandGenerator = LandGenerator;
});

;require.register("src/land-management-model", function(exports, require, module) {
var LandManagementModel, mixOf,
  __slice = [].slice,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

mixOf = function() {
  var Mixed, base, method, mixin, mixins, name, _i, _ref;
  base = arguments[0], mixins = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
  Mixed = (function(_super) {
    __extends(Mixed, _super);

    function Mixed() {
      return Mixed.__super__.constructor.apply(this, arguments);
    }

    return Mixed;

  })(base);
  for (_i = mixins.length - 1; _i >= 0; _i += -1) {
    mixin = mixins[_i];
    _ref = mixin.prototype;
    for (name in _ref) {
      method = _ref[name];
      Mixed.prototype[name] = method;
    }
  }
  return Mixed;
};

LandManagementModel = (function(_super) {
  __extends(LandManagementModel, _super);

  function LandManagementModel() {
    return LandManagementModel.__super__.constructor.apply(this, arguments);
  }

  LandManagementModel.prototype.dateString = 'Jan 2013';

  LandManagementModel.prototype.initialYear = 2013;

  LandManagementModel.prototype.year = 2013;

  LandManagementModel.prototype.month = 0;

  LandManagementModel.prototype.monthLength = 100;

  LandManagementModel.prototype.monthStrings = "Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec".split(" ");

  LandManagementModel.prototype.MAX_INTERESTING_SOIL_DEPTH = 3;

  LandManagementModel.prototype.setup = function() {
    this.setFastPatches();
    this.anim.setRate(100, true);
    this.yearTick = 0;
    this.setCacheAgentsHere();
    this.setupLand();
    this.setupPlants();
    return this.draw();
  };

  LandManagementModel.prototype.reset = function() {
    LandManagementModel.__super__.reset.apply(this, arguments);
    this.setup();
    this.updateDate();
    this.notifyListeners(LandManagementModel.STEP_INTERVAL_ELAPSED);
    this.notifyListeners(LandManagementModel.MONTH_INTERVAL_ELAPSED);
    return this.anim.draw();
  };

  LandManagementModel.prototype.step = function() {
    if ((this.anim.ticks % 20) === 1) {
      this.updateDate();
      this.notifyListeners(LandManagementModel.STEP_INTERVAL_ELAPSED);
    }
    if ((this.anim.ticks % this.monthLength) === 1) {
      this.updatePrecipitation();
      this.calculateSoilQuality();
      this.notifyListeners(LandManagementModel.MONTH_INTERVAL_ELAPSED);
    }
    this.erode();
    this.setSoilDepths();
    this.manageZones();
    this.runPlants();
    if ((this.anim.ticks % 50) === 1) {
      return this.settlePlants();
    }
  };

  LandManagementModel.prototype.updateDate = function() {
    var monthsPassed;
    monthsPassed = Math.floor(this.anim.ticks / this.monthLength);
    this.year = this.initialYear + Math.floor(monthsPassed / 12);
    this.month = monthsPassed % 12;
    return this.dateString = this.monthStrings[this.month] + " " + this.year;
  };

  LandManagementModel.STEP_INTERVAL_ELAPSED = 'step-interval-elapsed';

  LandManagementModel.MONTH_INTERVAL_ELAPSED = 'month-interval-elapsed';

  LandManagementModel.prototype.notifyListeners = function(type) {
    return $(document).trigger(type);
  };

  return LandManagementModel;

})(mixOf(ABM.Model, LandGenerator, ErosionEngine, PlantEngine));

window.LandManagementModel = LandManagementModel;
});

;require.register("src/main", function(exports, require, module) {
require('src/erosion-engine');

require('src/plant-engine');

require('src/land-generator');

require('src/land-management-model');

require('src/controls');
});

;require.register("src/plant-engine", function(exports, require, module) {
var PlantEngine;

PlantEngine = (function() {
  var NORTH, intensive, managementPlan, u;

  function PlantEngine() {}

  u = ABM.util;

  NORTH = Math.PI / 2;

  managementPlan = ["bare", "bare"];

  intensive = [false, false];

  PlantEngine.prototype.setupPlants = function() {
    this.agentBreeds("grass trees wheat");
    this.trees.setDefaultShape("arrow");
    this.trees.setDefaultColor([0, 255, 0]);
    this.addImage("tree1", "tree-1-sprite", 39, 70);
    this.addImage("tree2", "tree-2-sprite", 29, 80);
    this.addImage("tree3", "tree-3-sprite", 39, 80);
    this.addImage("grass1", "grass-1-sprite", 39, 80);
    this.addImage("grass2", "grass-1-sprite", 39, 80);
    return this.addImage("wheat1", "wheat-1-sprite", 39, 80);
  };

  PlantEngine.prototype.addImage = function(name, id, width, height, scale) {
    var image;
    image = document.getElementById(id);
    ABM.shapes.add(name, false, (function(_this) {
      return function(ctx) {
        ctx.scale(-0.1, 0.1);
        ctx.translate(width, height);
        ctx.rotate(Math.PI);
        return ctx.drawImage(image, 0, 0);
      };
    })(this));
    ABM.shapes.add("" + name + "-body", false, (function(_this) {
      return function(ctx) {
        ctx.scale(-0.1, 0.1);
        ctx.translate(width, height);
        ctx.rotate(Math.PI);
        return ctx.drawImage(image, 0, -height, width * 2, height * 2, 0, -height, width * 2, height * 2);
      };
    })(this));
    return ABM.shapes.add("" + name + "-root", false, (function(_this) {
      return function(ctx) {
        ctx.scale(-0.1, 0.1);
        ctx.translate(width, height);
        ctx.rotate(Math.PI);
        return ctx.drawImage(image, 0, height, width * 2, height * 2, 0, height, width * 2, height * 2);
      };
    })(this));
  };


  /*
    Defines the planting system of the two zones. Zone is defined
    by index, 0 or 1.
   */

  PlantEngine.prototype.setZoneManagement = function(zone, type) {
    var types;
    types = type.split("-");
    managementPlan[zone] = types[0];
    return intensive[zone] = types[1] === "intensive";
  };

  PlantEngine.prototype.manageZones = function() {
    if (managementPlan.join() === "bare,bare") {
      return;
    }
    this.yearTick = this.anim.ticks % (12 * this.monthLength);
    if (this.yearTick === 1) {
      return this.plantPlants();
    }
  };

  PlantEngine.prototype.plantPlants = function() {
    var i, inRows, patch, plantType, quantity, x, xModifier, zone, zoneWidth, _i, _len, _ref, _results;
    zoneWidth = this.patches.maxX;
    _ref = [0, 1];
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      zone = _ref[_i];
      plantType = managementPlan[zone];
      if (plantType === "bare") {
        continue;
      }
      if (this.anim.ticks > (12 * this.monthLength) && !this.plantData[plantType].annual) {
        continue;
      }
      quantity = this.plantData[plantType].quantity;
      inRows = this.plantData[plantType].inRows;
      xModifier = zone * 2 - 1;
      _results.push((function() {
        var _j, _results1;
        _results1 = [];
        for (i = _j = 0; 0 <= quantity ? _j < quantity : _j > quantity; i = 0 <= quantity ? ++_j : --_j) {
          x = inRows ? Math.floor((i + 1) * zoneWidth / (quantity + 1)) : u.randomInt(zoneWidth);
          x *= xModifier;
          patch = this.surfaceLand[zoneWidth + x];
          _results1.push(this.plantSeed(plantType, patch));
        }
        return _results1;
      }).call(this));
    }
    return _results;
  };

  PlantEngine.prototype.plantSeed = function(type, patch) {
    var data;
    data = this.plantData[type];
    return patch.sprout(1, this[type], function(a) {
      var p, v;
      a.size = 0;
      a.type = type;
      a.shape = u.oneOf(data.shapes);
      a.isSeed = true;
      a.dying = false;
      a.germinationDate = u.randomInt2(data.minGermination, data.maxGermination);
      v = data.periodVariation;
      a.growthPeriods = (function() {
        var _i, _len, _ref, _results;
        _ref = data.growthPeriods;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          p = _ref[_i];
          _results.push(p + (p * u.randomFloat2(-v, v)));
        }
        return _results;
      })();
      a.growthRates = data.growthRates;
      a.period = 0;
      return a.periodAge = 0;
    });
  };

  PlantEngine.prototype.runPlants = function() {
    var a, growthRate, kill, killList, patch, poorWater, xModifier, zone, _i, _j, _len, _len1, _ref, _results;
    killList = [];
    _ref = this.agents;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      a = _ref[_i];
      poorWater = this.precipitation < this.plantData[a.type].minimumPrecipitation || this.precipitation > this.plantData[a.type].maximumPrecipitation;
      if (a.isSeed) {
        if (this.yearTick === a.germinationDate) {
          if (poorWater && this.plantData[a.type].annual) {
            if (u.randomFloat(1) < 0.5) {
              killList.push(a);
              continue;
            }
          } else if (poorWater && !this.plantData[a.type].annual) {
            if (u.randomFloat(1) < 0.15) {
              killList.push(a);
            } else {
              a.germinationDate += 40;
            }
            continue;
          }
          a.isSeed = false;
        }
      } else {
        a.periodAge++;
        if (a.periodAge > a.growthPeriods[a.period]) {
          a.period++;
          a.periodAge = 0;
          switch (a.period) {
            case 3:
              if (!a.isRoot) {
                this.splitRoots(a);
              }
              break;
            case 4:
              if (!this.plantData[a.type].annual && !a.isRoot) {
                xModifier = a.x <= 0 ? -1 : 1;
                patch = this.surfaceLand[this.patches.maxX + (u.randomInt(this.patches.maxX) * xModifier)];
                this.plantSeed(a.type, patch);
              }
              break;
            case 5:
              kill = false;
              if (!a.isRoot) {
                kill = true;
              } else {
                if (a.type = "wheat") {
                  zone = a.x <= 0 ? 0 : 1;
                  if (!intensive[zone] && u.randomFloat(1) < 0.2) {
                    kill = true;
                  }
                  if (intensive[zone] && u.randomFloat(1) < 0.85) {
                    kill = true;
                  }
                } else if (u.randomFloat(1) < 0.5) {
                  kill = true;
                }
              }
              if (kill) {
                killList.push(a);
                continue;
              }
              a.period = 0;
          }
        }
        growthRate = a.growthRates[a.period] * this.topsoilRateFactor(a);
        if (poorWater) {
          growthRate -= 0.001;
        }
        a.size += growthRate;
        if (a.size <= 0) {
          killList.push(a);
        }
      }
    }
    _results = [];
    for (_j = 0, _len1 = killList.length; _j < _len1; _j++) {
      a = killList[_j];
      _results.push(a.die());
    }
    return _results;
  };

  PlantEngine.prototype.topsoilRateFactor = function(agent) {
    if (agent.p.isTopsoil) {
      return (this.MAX_INTERESTING_SOIL_DEPTH + 1 - agent.p.depth) / (this.MAX_INTERESTING_SOIL_DEPTH + 1);
    } else {
      return 0.05;
    }
  };

  PlantEngine.prototype.splitRoots = function(plant) {
    plant.p.sprout(1, this[plant.type], (function(_this) {
      return function(root) {
        root.size = plant.size;
        root.type = plant.type;
        root.shape = plant.shape + "-root";
        root.isSeed = false;
        root.isRoot = true;
        root.growthPeriods = plant.growthPeriods;
        root.growthRates = _this.plantData[plant.type].rootGrowthRates;
        root.period = plant.period;
        return root.periodAge = 0;
      };
    })(this));
    plant.isBody = true;
    return plant.shape = plant.shape + "-body";
  };

  PlantEngine.prototype.settlePlants = function() {
    var a, surfacePatch, zoneWidth, _i, _len, _ref, _results;
    zoneWidth = this.patches.maxX;
    _ref = this.agents;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      a = _ref[_i];
      surfacePatch = this.surfaceLand[zoneWidth + a.x];
      if (surfacePatch.y < (a.y - 1)) {
        _results.push(a.setXY(a.x, a.y - 0.2));
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  };

  PlantEngine.prototype.soilQuality = [1, 1];

  PlantEngine.prototype.calculateSoilQuality = function() {
    var quality, zone, _i, _results;
    _results = [];
    for (zone = _i = 0; _i <= 1; zone = ++_i) {
      quality = this.soilQuality[zone];
      if (managementPlan[zone] === "wheat") {
        if (intensive[zone]) {
          quality -= 0.02;
        } else {
          quality += 0.02;
        }
        quality = Math.max(Math.min(quality, 2), 0);
      }
      _results.push(this.soilQuality[zone] = quality);
    }
    return _results;
  };

  PlantEngine.prototype.plantData = {
    trees: {
      quantity: 19,
      inRows: false,
      annual: false,
      minGermination: 100,
      maxGermination: 1200,
      growthPeriods: [100, 1800, 4800, 1300, 1200],
      growthRates: [0.0014, 0.0018, 0.0001, -0.001, -0.001],
      rootGrowthRates: [0, -0.0005, 0, -0.0005, -0.0005],
      periodVariation: 0.22,
      minimumPrecipitation: 14,
      maximumPrecipitation: 450,
      shapes: ["tree1", "tree2", "tree3"]
    },
    grass: {
      quantity: 33,
      inRows: false,
      annual: false,
      minGermination: 1,
      maxGermination: 800,
      growthPeriods: [120, 210, 1400, 150, 100],
      growthRates: [0.002, 0.004, 0.0001, -0.005, -0.002],
      rootGrowthRates: [0, -0.001, 0, -0.001, -0.001],
      periodVariation: 0.15,
      minimumPrecipitation: 14,
      maximumPrecipitation: 450,
      shapes: ["grass1", "grass2"]
    },
    wheat: {
      quantity: 19,
      inRows: true,
      annual: true,
      minGermination: 60,
      maxGermination: 90,
      growthPeriods: [120, 210, 350, 100, 100],
      growthRates: [0.003, 0.005, 0.0001, -0.002, -0.005],
      rootGrowthRates: [0, 0, 0, -0.001, -0.001],
      periodVariation: 0.04,
      minimumPrecipitation: 14,
      maximumPrecipitation: 450,
      shapes: ["wheat1"]
    }
  };

  return PlantEngine;

})();

window.PlantEngine = PlantEngine;
});

;
//# sourceMappingURL=app.js.map