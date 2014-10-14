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
var $precipitationSlider, $precipitationSliderDiv, $slopeSlidersDiv, $zone1Slider, $zone2Slider, BLUE, DARK_BLUE, DARK_GREEN, DARK_MAGENTA, DARK_ORANGE, GREEN, MAGENTA, ORANGE, autoscaleBoth, enableZoneSliders, erosionGraph, reset, setupGraphs, topsoilCountGraph, updatePrecipitationBarchart, zone1Planting, zone2Planting;

MAGENTA = [255, 50, 185];

DARK_MAGENTA = [255, 0, 130];

ORANGE = [255, 195, 50];

DARK_ORANGE = [255, 148, 0];

GREEN = [161, 255, 0];

DARK_GREEN = [131, 208, 0];

BLUE = [0, 139, 255];

DARK_BLUE = [0, 114, 208];

$precipitationSlider = $("#precipitation-slider");

$precipitationSliderDiv = $("#user-precipitation");

$zone1Slider = $("#zone-1-slider");

$zone2Slider = $("#zone-2-slider");

$slopeSlidersDiv = $("#slope-sliders");

erosionGraph = null;

topsoilCountGraph = null;

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
  $precipitationSlider.slider({
    min: 0,
    max: 500,
    step: 1,
    value: 166
  });
  $zone1Slider.slider({
    min: -3,
    max: 3,
    step: 0.5,
    value: 0
  });
  $zone2Slider.slider({
    min: -3,
    max: 3,
    step: 0.5,
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
    erosionGraph.reset();
  }
  if (topsoilCountGraph != null) {
    return topsoilCountGraph.reset();
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
  selection = $(this).val();
  model.setLandType(selection);
  reset();
  return enableZoneSliders(selection === "Sliders");
});

$("#zone1-planting-options").change(function() {
  var selection;
  selection = $(this).val();
  model.setZoneManagement(0, selection);
  return zone1Planting = selection;
});

$("#zone2-planting-options").change(function() {
  var selection;
  selection = $(this).val();
  model.setZoneManagement(1, selection);
  return zone2Planting = selection;
});

$precipitationSlider.on('slide', function(event, ui) {
  model.setUserPrecipitation(ui.value);
  updatePrecipitationBarchart(model.getCurrentClimateData());
  return $("#precipitation-value").text(model.precipitation);
});

$("#climate-options").change(function() {
  var enable, selection;
  selection = $(this).val();
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

autoscaleBoth = (function() {
  var autoscaling;
  autoscaling = false;
  return function() {
    if (!autoscaling) {
      autoscaling = true;
      if (erosionGraph != null) {
        erosionGraph.autoscale();
      }
      if (topsoilCountGraph != null) {
        topsoilCountGraph.autoscale();
      }
      return autoscaling = false;
    }
  };
})();

setupGraphs = function() {
  var appendKeyToGraph, drawKey;
  drawKey = function(canvas, labelInfo) {
    var ctx, label, y, _i, _len, _results;
    y = 0.5 * (canvas.height - 20 * (labelInfo.length - 1));
    ctx = canvas.getContext('2d');
    ctx.fillStyle = 'black';
    ctx.font = '12px "Helvetica Neue", Helvetica, sans-serif';
    ctx.lineWidth = 2;
    _results = [];
    for (_i = 0, _len = labelInfo.length; _i < _len; _i++) {
      label = labelInfo[_i];
      ctx.strokeStyle = "rgb(" + (label.color.join(',')) + ")";
      ctx.beginPath();
      ctx.moveTo(10, y);
      ctx.lineTo(60, y);
      ctx.stroke();
      ctx.fillText(label.label, 70, y + 3);
      _results.push(y += 20);
    }
    return _results;
  };
  appendKeyToGraph = function(graphId, top, labelInfo, keyId) {
    var $graph;
    if (keyId == null) {
      keyId = null;
    }
    $graph = $("#" + graphId);
    keyId || (keyId = "" + graphId + "-key");
    $graph.append('<a href="#" class="show-key">show key</a>');
    return $graph.find('.show-key').click(function() {
      var $key, canvas;
      if (!($("#" + keyId).length > 0)) {
        $key = $("<div id=\"" + keyId + "\" class=\"key\"><a class=\"icon-remove-sign icon-large\"></a><canvas></canvas></div>").appendTo($(document.body)).draggable();
        canvas = $key.find('canvas')[0];
        $key.height(18 * (labelInfo.length + 1));
        canvas.height = $key.outerHeight();
        canvas.width = $key.outerWidth();
        drawKey($key.find('canvas')[0], labelInfo);
      }
      $key = $("#" + keyId);
      return $key.css({
        left: '430px',
        top: "" + top + "px"
      }).show().on('click', 'a', function() {
        return $(this).parent().hide();
      });
    });
  };
  if ($('#erosion-graph').length) {
    erosionGraph = LabGrapher('#erosion-graph', {
      title: "Erosion Rates",
      xlabel: "Time (year)",
      ylabel: "Monthly Erosion",
      xmax: new Date().getFullYear() + 7,
      xmin: new Date().getFullYear(),
      ymax: 100,
      ymin: 0,
      xTickCount: 4,
      yTickCount: 5,
      xFormatter: "d",
      dataSampleStart: new Date().getFullYear(),
      sampleInterval: 1 / 60,
      realTime: true,
      fontScaleRelativeToParent: true,
      onAutoscale: autoscaleBoth,
      dataColors: [DARK_BLUE, DARK_GREEN]
    });
    appendKeyToGraph('erosion-graph', 10, [
      {
        color: DARK_BLUE,
        label: "Zone 1"
      }, {
        color: DARK_GREEN,
        label: "Zone 2"
      }
    ], "zone-key");
  }
  if ($('#topsoil-count-graph').length) {
    topsoilCountGraph = LabGrapher('#topsoil-count-graph', {
      title: "Amount of Topsoil in Zone",
      xlabel: "Time (year)",
      ylabel: "Amount of Topsoil",
      xmax: new Date().getFullYear() + 7,
      xmin: new Date().getFullYear(),
      ymax: 1000,
      ymin: 0,
      xTickCount: 4,
      yTickCount: 5,
      xFormatter: "d",
      dataSampleStart: new Date().getFullYear(),
      sampleInterval: 1 / 60,
      realTime: true,
      fontScaleRelativeToParent: true,
      onAutoscale: autoscaleBoth,
      dataColors: [DARK_BLUE, DARK_GREEN]
    });
    return appendKeyToGraph('topsoil-count-graph', 10, [
      {
        color: DARK_BLUE,
        label: "Zone 1"
      }, {
        color: DARK_GREEN,
        label: "Zone 2"
      }
    ], "zone-key");
  }
};

(function() {
  var makeSmoothed, zone1Smoothed, zone2Smoothed;
  makeSmoothed = function() {
    var alpha, s;
    s = null;
    alpha = 0.3;
    return function(x) {
      if (s === null) {
        return s = x;
      } else {
        return s = alpha * x + (1 - alpha) * s;
      }
    };
  };
  zone1Smoothed = makeSmoothed();
  zone2Smoothed = makeSmoothed();
  return $(document).on(LandManagementModel.STEP_INTERVAL_ELAPSED, function() {
    var topsoilInZone;
    $('#date-string').text(model.dateString);
    if (erosionGraph) {
      erosionGraph.addSamples([zone1Smoothed(model.zone1ErosionCount), zone2Smoothed(model.zone2ErosionCount)]);
    }
    model.resetErosionCounts();
    if (topsoilCountGraph) {
      topsoilInZone = model.topsoilInZones();
      return topsoilCountGraph.addSamples([topsoilInZone[1], topsoilInZone[2]]);
    }
  });
})();

$(document).on(LandManagementModel.STEP_INTERVAL_ELAPSED, function() {
  $(".inner-bar").removeClass("current-month");
  $($(".inner-bar")[model.month]).addClass("current-month");
  return $("#precipitation-value").text(model.precipitation);
});
});

;require.register("src/erosion-engine", function(exports, require, module) {
var BASE_LAND_COLOR, ErosionEngine, LAND, MAGENTA, MEDIUM_SOIL_COLOR, ORANGE, POOR_SOIL_COLOR, SKY, SKY_BTM_COLOR, SKY_COLOR_CHANGE, SKY_TOP_COLOR, TERRACE_COLOR, TOP_LAND_COLOR;

SKY_TOP_COLOR = [41, 129, 187];

SKY_BTM_COLOR = [188, 230, 251];

SKY_COLOR_CHANGE = [SKY_BTM_COLOR[0] - SKY_TOP_COLOR[0], SKY_BTM_COLOR[1] - SKY_TOP_COLOR[1], SKY_BTM_COLOR[2] - SKY_TOP_COLOR[2]];

TOP_LAND_COLOR = [60, 51, 47];

BASE_LAND_COLOR = [211, 109, 62];

TERRACE_COLOR = [87, 94, 97];

MEDIUM_SOIL_COLOR = [135, 79, 49];

POOR_SOIL_COLOR = [193, 114, 7];

MAGENTA = [164, 105, 189];

ORANGE = [216, 72, 40];

SKY = "sky";

LAND = "land";

ErosionEngine = (function() {
  var climate, climateData, maxSlope, u, userPrecipitation;

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

  ErosionEngine.prototype.minErosionProbability = 0.1;

  ErosionEngine.prototype.fullyProtectiveVegetationLevel = 1;

  maxSlope = 2;

  ErosionEngine.prototype.showErosion = true;

  ErosionEngine.prototype.zone1ErosionCount = 0;

  ErosionEngine.prototype.zone2ErosionCount = 0;

  ErosionEngine.prototype.showSoilQuality = false;

  ErosionEngine.prototype._lastKnownSurface = [];

  ErosionEngine.prototype.findSurfaceLandPatches = function(reset) {
    var p, x, y, _i, _ref, _ref1, _ref2;
    if (reset == null) {
      reset = false;
    }
    for (x = _i = _ref = this.patches.minX, _ref1 = this.patches.maxX; _ref <= _ref1 ? _i <= _ref1 : _i >= _ref1; x = _ref <= _ref1 ? ++_i : --_i) {
      p = null;
      if (!reset && ((p = this._lastKnownSurface[x - this.patches.minX]) != null)) {
        while (p.type === SKY && (p.n[1] != null)) {
          p = p.n[1];
        }
        while (p.type === LAND && ((_ref2 = p.n[6]) != null ? _ref2.type : void 0) === LAND) {
          p = p.n[6];
        }
      } else {
        y = this.patches.maxY;
        while ((p = this.patches.patchXY(x, y)).type !== LAND && y > this.patches.minY) {
          y--;
        }
      }
      this._lastKnownSurface[x - this.patches.minX] = p;
    }
    return this._lastKnownSurface;
  };

  ErosionEngine.prototype.updateSurfacePatches = function(reset) {
    var i, newColor, p, surfacePatch, x, y, zone, _i, _j, _len, _ref, _ref1, _ref2;
    if (reset == null) {
      reset = false;
    }
    this.surfaceLand = this.findSurfaceLandPatches(reset);
    _ref = this.surfaceLand;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      surfacePatch = _ref[_i];
      _ref1 = [surfacePatch.x, surfacePatch.y], x = _ref1[0], y = _ref1[1];
      for (i = _j = 0, _ref2 = this.INITIAL_TOPSOIL_DEPTH; 0 <= _ref2 ? _j < _ref2 : _j > _ref2; i = 0 <= _ref2 ? ++_j : --_j) {
        p = this.patches.patch(x, y - i);
        newColor = p.isTerrace ? TERRACE_COLOR : p.isTopsoil ? this.showErosion && p.eroded ? p.zone === 1 ? ORANGE : MAGENTA : this.showSoilQuality ? (zone = p.x <= 0 ? 0 : 1, p.quality < this.soilQuality[zone] ? p.quality += 0.001 : void 0, p.quality > this.soilQuality[zone] ? p.quality -= 0.001 : void 0, p.quality < 0.5 ? POOR_SOIL_COLOR : p.quality > 1.5 ? TOP_LAND_COLOR : MEDIUM_SOIL_COLOR) : TOP_LAND_COLOR : void 0;
        if (newColor != null) {
          p.color = newColor;
        }
      }
    }
    return null;
  };

  ErosionEngine.prototype.adjustEdges = function() {
    this.adjustEdge(0, 1);
    return this.adjustEdge(this.surfaceLand.length - 1, -1);
  };

  ErosionEngine.prototype.adjustEdge = function(iLim, direction) {
    var SURFACE_WIDTH, currentY, data, desiredY, i, x, y, _i, _j, _ref, _ref1;
    SURFACE_WIDTH = 10;
    currentY = this.surfaceLand[iLim].y;
    data = (function() {
      var _i, _ref, _ref1, _results;
      _results = [];
      for (i = _i = _ref = iLim + direction, _ref1 = iLim + SURFACE_WIDTH * direction; _ref <= _ref1 ? _i <= _ref1 : _i >= _ref1; i = _ref <= _ref1 ? ++_i : --_i) {
        _results.push([i, this.surfaceLand[i].y]);
      }
      return _results;
    }).call(this);
    desiredY = Math.round(ss.linear_regression().data(data).line()(iLim));
    x = this.surfaceLand[iLim].x;
    if (currentY < desiredY) {
      for (y = _i = _ref = currentY + 1; _ref <= desiredY ? _i <= desiredY : _i >= desiredY; y = _ref <= desiredY ? ++_i : --_i) {
        this.convertSkyToLand(this.patches.patch(x, y));
      }
    } else if (currentY > desiredY) {
      for (y = _j = _ref1 = desiredY + 1; _ref1 <= currentY ? _j <= currentY : _j >= currentY; y = _ref1 <= currentY ? ++_j : --_j) {
        this.convertLandToSky(this.patches.patch(x, y));
      }
    }
    return null;
  };

  ErosionEngine.prototype.convertSkyToLand = function(p) {
    var p1, topsoil, x, xMax, xMin, y, ySurface, zones, _i, _j, _ref;
    xMin = Math.max(0, p.x - 5);
    xMax = Math.min(this.patches.maxX - 1, p.x + 5);
    zones = [0, 0];
    topsoil = [0, 0];
    for (x = _i = xMin; xMin <= xMax ? _i <= xMax : _i >= xMax; x = xMin <= xMax ? ++_i : --_i) {
      ySurface = this.surfaceLand[x - this.patches.minX].y;
      for (y = _j = _ref = ySurface - 2; _ref <= ySurface ? _j <= ySurface : _j >= ySurface; y = _ref <= ySurface ? ++_j : --_j) {
        p1 = this.patches.patch(x, y);
        if (p1.type !== LAND) {
          continue;
        }
        ++zones[p1.zone];
        ++topsoil[p1.isTopsoil + 0];
      }
    }
    p.zone = zones[0] > zones[1] ? 0 : 1;
    p.isTopsoil = topsoil[1] > topsoil[0];
    p.type = LAND;
    p.eroded = true;
    p.isTerrace = false;
    p.stability = 1;
    p.quality = 1;
    return p.color = p.isTopsoil ? TOP_LAND_COLOR : BASE_LAND_COLOR;
  };

  ErosionEngine.prototype.convertLandToSky = function(p) {
    p.type = SKY;
    p.color = this._calculateSkyColor(p.y);
    return this.removeLandProperties(p);
  };

  ErosionEngine.prototype.erode = function() {
    var a, expectedHeightToLeft, expectedHeightToRight, i, lastIndex, localSlope, p, precipitationContribution, probabilityOfErosion, signOf, slopeContribution, target, totalVegetationSize, vegetation, vegetationContribution, _i, _j, _len, _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6;
    signOf = function(x) {
      if (x === 0) {
        return 1;
      } else {
        return Math.round(x / Math.abs(x));
      }
    };
    this.adjustEdges();
    for (i = _i = 1, _ref = this.surfaceLand.length - 1; 1 <= _ref ? _i < _ref : _i > _ref; i = 1 <= _ref ? ++_i : --_i) {
      p = this.surfaceLand[i];
      localSlope = this.getLocalSlope(p.x, p.y);
      slopeContribution = Math.min(1, 2 * Math.abs(localSlope));
      vegetation = this.getLocalVegetation(p.x);
      totalVegetationSize = 0;
      for (_j = 0, _len = vegetation.length; _j < _len; _j++) {
        a = vegetation[_j];
        totalVegetationSize += (a.isBody ? a.size / 3 : a.isRoot ? a.size * 2 / 3 : a.size);
      }
      vegetationContribution = this.minErosionProbability + 0.8 * (1 - Math.min(1, totalVegetationSize / Math.max(this.fullyProtectiveVegetationLevel, 0.01)));
      precipitationContribution = this.precipitation / 500;
      probabilityOfErosion = 0.1 * slopeContribution * vegetationContribution * precipitationContribution * p.stability;
      if (u.randomFloat(1) > probabilityOfErosion) {
        continue;
      }
      p.direction = signOf(-localSlope);
      if (p.x === this.patches.minX && p.direction === -1) {
        expectedHeightToLeft = 2 * this.surfaceLand[1].y - this.surfaceLand[3].y;
        if (expectedHeightToLeft >= p.y) {
          continue;
        }
        target = null;
      } else if (p.x === this.patches.maxX && p.direction === 1) {
        lastIndex = this.surfaceLand.length - 1;
        expectedHeightToRight = 2 * this.surfaceLand[lastIndex - 1].y - this.surfaceLand[lastIndex - 3].y;
        if (expectedHeightToRight >= p.y) {
          continue;
        }
        target = null;
      } else if (((_ref1 = p.n[1 + p.direction]) != null ? _ref1.type : void 0) === SKY) {
        target = p.n[1 + p.direction];
      } else if (((_ref2 = p.n[1 - p.direction]) != null ? _ref2.type : void 0) === SKY) {
        target = p.n[1 - p.direction];
      } else if (((_ref3 = p.n[3.5 + (p.direction / 2)]) != null ? _ref3.type : void 0) === SKY) {
        target = p.n[3.5 + (p.direction / 2)];
      } else if (((_ref4 = p.n[3.5 - (p.direction / 2)]) != null ? _ref4.type : void 0) === SKY) {
        target = p.n[3.5 - (p.direction / 2)];
      } else {
        p.direction = 0;
        continue;
      }
      if (p.x <= 0) {
        this.zone1ErosionCount++;
      } else {
        this.zone2ErosionCount++;
      }
      if (target != null) {
        while (((_ref5 = target.n[1]) != null ? _ref5.type : void 0) === SKY) {
          target = target.n[1];
        }
        this.swapSkyAndLand(target, p);
        target.eroded = true;
      }
      this.convertLandToSky(p);
      if (((_ref6 = p.n[6]) != null ? _ref6.type : void 0) === LAND) {
        this.swapSkyAndLand(p, p.n[6]);
      }
    }
    return null;
  };

  ErosionEngine.prototype.swapSkyAndLand = function(sky, land) {
    var property, _i, _len, _ref, _ref1;
    _ref = this.landPropertyNames.concat(['type', 'color']);
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      property = _ref[_i];
      _ref1 = [sky[property], land[property]], land[property] = _ref1[0], sky[property] = _ref1[1];
    }
    return null;
  };

  ErosionEngine.prototype.removeLandProperties = function(p) {
    var property, _i, _len, _ref;
    _ref = this.landPropertyNames;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      property = _ref[_i];
      p[property] = null;
    }
    return null;
  };

  ErosionEngine.prototype.getBoxAroundPoint = function(x, y, xStep, yStep) {
    var bottom, leftEdge, rightEdge, top;
    xStep = 3;
    yStep = 5;
    if (x - xStep < this.patches.minX) {
      leftEdge = this.patches.minX;
      rightEdge = leftEdge + 2 * xStep;
    } else if (x + xStep > this.patches.maxX) {
      rightEdge = this.patches.maxX;
      leftEdge = rightEdge - 2 * xStep;
    } else {
      leftEdge = x - xStep;
      rightEdge = x + xStep;
    }
    top = Math.min(y + yStep, this.patches.maxY);
    bottom = Math.max(y - yStep, this.patches.minY);
    return [leftEdge, rightEdge, top, bottom];
  };

  ErosionEngine.prototype.getLocalSlope = function(x, y) {
    var bottom, leftEdge, leftHeight, rightEdge, rightHeight, slope, top, _ref;
    _ref = this.getBoxAroundPoint(x, y, 3, 5), leftEdge = _ref[0], rightEdge = _ref[1], top = _ref[2], bottom = _ref[3];
    leftHeight = bottom;
    rightHeight = bottom;
    while (leftHeight < top && this.patches.patchXY(leftEdge, leftHeight).type === LAND) {
      leftHeight++;
    }
    while (rightHeight < top && this.patches.patchXY(rightEdge, rightHeight).type === LAND) {
      rightHeight++;
    }
    return slope = (rightHeight - leftHeight) / (rightEdge - leftEdge);
  };

  ErosionEngine.prototype.getLocalVegetation = (function() {
    var SEARCH_HALF_WIDTH, lastIndex, lastX, sortedAgents;
    SEARCH_HALF_WIDTH = 5;
    lastX = null;
    sortedAgents = null;
    lastIndex = null;
    return function(x) {
      var a, i, length, vegetation;
      if ((lastX == null) || x < lastX) {
        sortedAgents = ((function() {
          var _i, _len, _ref, _results;
          _ref = this.agents;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            a = _ref[_i];
            _results.push(a);
          }
          return _results;
        }).call(this)).sort(function(a, b) {
          return a.x - b.x;
        });
        lastIndex = 0;
      }
      lastX = x;
      length = sortedAgents.length;
      while (lastIndex < length && sortedAgents[lastIndex].x < x - SEARCH_HALF_WIDTH) {
        lastIndex++;
      }
      if (lastIndex === length) {
        return [];
      }
      vegetation = [];
      i = lastIndex;
      while (i < length && sortedAgents[i].x < x + SEARCH_HALF_WIDTH) {
        vegetation.push(sortedAgents[i]);
        i++;
      }
      return vegetation;
    };
  })();

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

  ErosionEngine.prototype.topsoilInZones = function() {
    var count, p, ret, _i, _len, _ref;
    ret = [];
    ret[1] = 0;
    ret[2] = 0;
    count = 0;
    _ref = this.patches;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      p = _ref[_i];
      if (p.isTopsoil) {
        count++;
        if (p.x < 0) {
          ret[1]++;
        } else {
          ret[2]++;
        }
      }
    }
    return ret;
  };

  ErosionEngine.prototype._calculateSkyColor = function(y) {
    var pct, result;
    pct = 1 - (y - this.patches.minY) / (this.patches.maxY - this.patches.minY);
    return result = [pct * SKY_COLOR_CHANGE[0] + SKY_TOP_COLOR[0], pct * SKY_COLOR_CHANGE[1] + SKY_TOP_COLOR[1], pct * SKY_COLOR_CHANGE[2] + SKY_TOP_COLOR[2]];
  };

  return ErosionEngine;

})();

window.ErosionEngine = ErosionEngine;
});

;require.register("src/land-generator", function(exports, require, module) {
var BASE_LAND_COLOR, LAND, LandGenerator, SKY, SKY_BTM_COLOR, SKY_COLOR_CHANGE, SKY_TOP_COLOR, TERRACE_COLOR, TOP_LAND_COLOR;

SKY_TOP_COLOR = [41, 129, 187];

SKY_BTM_COLOR = [188, 230, 251];

SKY_COLOR_CHANGE = [SKY_BTM_COLOR[0] - SKY_TOP_COLOR[0], SKY_BTM_COLOR[1] - SKY_TOP_COLOR[1], SKY_BTM_COLOR[2] - SKY_TOP_COLOR[2]];

TOP_LAND_COLOR = [60, 51, 47];

BASE_LAND_COLOR = [211, 109, 62];

TERRACE_COLOR = [87, 94, 97];

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

  LandGenerator.prototype.landPropertyNames = ['direction', 'eroded', 'zone', 'stability', 'quality', 'isTopsoil', 'isTerrace'];

  LandGenerator.prototype.setupLand = function() {
    var p, property, x, y, _i, _j, _k, _len, _ref, _ref1, _ref2, _ref3, _ref4;
    for (x = _i = _ref = this.patches.minX, _ref1 = this.patches.maxX; _ref <= _ref1 ? _i <= _ref1 : _i >= _ref1; x = _ref <= _ref1 ? ++_i : --_i) {
      for (y = _j = _ref2 = this.patches.minY, _ref3 = this.patches.maxY; _ref2 <= _ref3 ? _j <= _ref3 : _j >= _ref3; y = _ref2 <= _ref3 ? ++_j : --_j) {
        p = this.patches.patch(x, y);
        p.zone = p.x <= 0 ? 1 : 2;
        if (p.y > this.landShapeFunction(p.x)) {
          p.color = this._calculateSkyColor(p.y);
          p.type = SKY;
          _ref4 = this.landPropertyNames;
          for (_k = 0, _len = _ref4.length; _k < _len; _k++) {
            property = _ref4[_k];
            p[property] = null;
          }
        } else {
          p.isTopsoil = p.y > this.landShapeFunction(p.x) - this.INITIAL_TOPSOIL_DEPTH;
          p.stability = p.isTopsoil ? 1 : 0.2;
          p.color = BASE_LAND_COLOR;
          p.type = LAND;
          p.eroded = false;
          p.direction = 0;
          p.quality = 1;
          if (type === "Terraced" && p.x < 0 && ((p.x % Math.floor(this.patches.minX / 5) === 0 && p.y > this.landShapeFunction(p.x - 1)) || ((p.x - 1) % Math.floor(this.patches.minX / 5) === 0 && p.y > this.landShapeFunction(p.x - 2)))) {
            p.isTerrace = true;
            p.color = TERRACE_COLOR;
            p.stability = 0.01;
          } else {
            p.isTerrace = false;
          }
        }
      }
    }
    return this.updateSurfacePatches(true);
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

  LandGenerator.prototype._calculateSkyColor = function(y) {
    var pct, result;
    pct = 1 - (y - this.patches.minY) / (this.patches.maxY - this.patches.minY);
    return result = [pct * SKY_COLOR_CHANGE[0] + SKY_TOP_COLOR[0], pct * SKY_COLOR_CHANGE[1] + SKY_TOP_COLOR[1], pct * SKY_COLOR_CHANGE[2] + SKY_TOP_COLOR[2]];
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

  LandManagementModel.prototype.dateString = 'Jan ' + (new Date().getFullYear());

  LandManagementModel.prototype.initialYear = new Date().getFullYear();

  LandManagementModel.prototype.year = new Date().getFullYear();

  LandManagementModel.prototype.month = 0;

  LandManagementModel.prototype.monthLength = 100;

  LandManagementModel.prototype.monthStrings = "Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec".split(" ");

  LandManagementModel.prototype.INITIAL_TOPSOIL_DEPTH = 4;

  LandManagementModel.prototype.setup = function() {
    this.setFastPatches();
    this.anim.setRate(100, true);
    this.anim.setDrawRate(30);
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
    this.updateSurfacePatches();
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

  LandManagementModel.prototype.yearTick = function() {
    return this.anim.ticks % (12 * this.monthLength);
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
    this.addImage("tree1", "tree-1-sprite", 50, 106);
    this.addImage("tree2", "tree-2-sprite", 53, 97);
    this.addImage("tree3", "tree-3-sprite", 56, 95);
    this.addImage("grass1", "grass-1-sprite", 15, 45);
    this.addImage("grass2", "grass-2-sprite", 11, 45);
    this.addImage("wheat1", "wheat-1-sprite", 16, 84);
    this.addImage("wheat2", "wheat-2-sprite", 16, 84);
    return this.soilQuality = [1, 1];
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
    var plantType, previousPlantType, types;
    previousPlantType = managementPlan[zone];
    types = type.split("-");
    plantType = types[0];
    managementPlan[zone] = types[0];
    intensive[zone] = types[1] === "intensive";
    if (this.yearTick !== 0) {
      if (previousPlantType === "bare") {
        return this.plantPlantsInZone(zone);
      }
    }
  };

  PlantEngine.prototype.manageZones = function() {
    if (managementPlan.join() === "bare,bare") {
      return;
    }
    if (this.yearTick() === 1) {
      this.killOffUnwantedPerennials();
      return this.plantPlants();
    }
  };

  PlantEngine.prototype.killOffUnwantedPerennials = function() {
    var a, killList, zone, _i, _j, _len, _len1, _ref, _ref1, _ref2, _results;
    killList = [];
    _ref = this.agents;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      a = _ref[_i];
      zone = ((_ref1 = a.p) != null ? _ref1.x : void 0) <= 0 ? 0 : 1;
      if (!a.isRoot && !((_ref2 = this.plantData[a.type]) != null ? _ref2.annual : void 0) && a.type !== managementPlan[zone]) {
        killList.push(a);
      }
    }
    _results = [];
    for (_j = 0, _len1 = killList.length; _j < _len1; _j++) {
      a = killList[_j];
      _results.push(a.die());
    }
    return _results;
  };

  PlantEngine.prototype.isPrecipitationOptimalFor = function(type) {
    var plantData, _ref;
    plantData = this.plantData[type];
    return (plantData.minimumPrecipitation <= (_ref = this.precipitation) && _ref <= plantData.maximumPrecipitation);
  };

  PlantEngine.prototype.isPrecipitationTooLowFor = function(type) {
    var ret;
    ret = this.precipitation < this.plantData[type].minimumPrecipitation;
    return ret;
  };

  PlantEngine.prototype.plantPopulationInZone = function(zone) {
    return this.agents.reduce(((function(_this) {
      return function(x, a) {
        if (_this.isAgentAPlantInZone(a, zone)) {
          return x + 1;
        } else {
          return x;
        }
      };
    })(this)), 0);
  };

  PlantEngine.prototype.adjustPlantPopulationInZone = function(zone) {
    var a, actualPopulation, killList, plantType, populationIfOptimalPrecipitation, _i, _j, _len, _len1, _ref, _ref1, _results;
    killList = [];
    plantType = managementPlan[zone];
    if (!((_ref = this.plantData[plantType]) != null ? _ref.isAffectedByPoorWaterAfterPlanting : void 0)) {
      return;
    }
    actualPopulation = this.plantPopulationInZone(zone);
    populationIfOptimalPrecipitation = this.plantData[plantType].quantity;
    if (this.isPrecipitationOptimalFor(managementPlan[zone])) {
      if (actualPopulation < populationIfOptimalPrecipitation) {
        this.plantPlantsInZone(zone);
      }
    } else {
      if (actualPopulation === populationIfOptimalPrecipitation) {
        _ref1 = this.agents;
        for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
          a = _ref1[_i];
          if (this.isAgentAPlantInZone(a, zone) && u.randomFloat(1) < this.plantData[plantType].mortalityInPoorWater) {
            killList.push(a);
          }
        }
      }
    }
    _results = [];
    for (_j = 0, _len1 = killList.length; _j < _len1; _j++) {
      a = killList[_j];
      if (!a.isBody) {
        this.splitRoots(a);
      }
      _results.push(a.die());
    }
    return _results;
  };

  PlantEngine.prototype.isAgentAPlantInZone = function(a, zone) {
    if (zone === 0) {
      return a.x <= 0 && !a.isRoot;
    } else {
      return a.x > 0 && !a.isRoot;
    }
  };

  PlantEngine.prototype.plantPlantsInZone = function(zone) {
    var actualPopulation, desiredPopulation, i, inRows, plantAt, plantType, sign, zoneWidth, _i, _j, _results, _results1;
    zoneWidth = this.patches.maxX;
    plantType = managementPlan[zone];
    if (plantType === "bare") {
      return;
    }
    if (this.yearTick() > this.plantData[plantType].maxGermination) {
      return;
    }
    desiredPopulation = this.plantData[plantType].quantity;
    actualPopulation = this.plantPopulationInZone(zone);
    sign = zone * 2 - 1;
    inRows = this.plantData[plantType].inRows;
    plantAt = (function(_this) {
      return function(x) {
        var patch;
        patch = _this.surfaceLand[zoneWidth + x];
        return _this.plantSeed(plantType, patch);
      };
    })(this);
    if (inRows && actualPopulation === 0) {
      _results = [];
      for (i = _i = 0; 0 <= desiredPopulation ? _i < desiredPopulation : _i > desiredPopulation; i = 0 <= desiredPopulation ? ++_i : --_i) {
        _results.push(plantAt(sign * Math.floor((i + 1) * zoneWidth / (desiredPopulation + 1))));
      }
      return _results;
    } else if (!inRows) {
      _results1 = [];
      for (i = _j = actualPopulation; actualPopulation <= desiredPopulation ? _j < desiredPopulation : _j > desiredPopulation; i = actualPopulation <= desiredPopulation ? ++_j : --_j) {
        _results1.push(plantAt(sign * u.randomInt(zoneWidth)));
      }
      return _results1;
    }
  };

  PlantEngine.prototype.plantPlants = function() {
    var zone, _i, _len, _ref;
    _ref = [0, 1];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      zone = _ref[_i];
      this.plantPlantsInZone(zone);
    }
    return null;
  };

  PlantEngine.prototype.plantSeed = function(type, patch) {
    var data;
    data = this.plantData[type];
    return patch.sprout(1, this[type], (function(_this) {
      return function(a) {
        var p, v;
        a.size = data.initialSize;
        a.type = type;
        a.shape = u.oneOf(data.shapes);
        a.isSeed = true;
        a.dying = false;
        a.germinationDate = u.randomInt2(Math.max(_this.yearTick() + 1, data.minGermination), data.maxGermination);
        v = data.periodVariation;
        a.growthPeriods = (function() {
          var _i, _len, _ref, _results;
          _ref = data.growthPeriods;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            p = _ref[_i];
            _results.push(p * u.randomFloat2(1 - v, 1 + v));
          }
          return _results;
        })();
        a.growthRates = data.growthRates;
        a.period = 0;
        a.periodAge = 0;
        return a.isBrowned = false;
      };
    })(this));
  };

  PlantEngine.prototype.runPlants = function() {
    var a, growthRate, kill, killList, patch, poorWater, xModifier, zone, _i, _j, _k, _len, _len1, _len2, _ref, _ref1, _results;
    killList = [];
    _ref = [0, 1];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      zone = _ref[_i];
      this.adjustPlantPopulationInZone(zone);
    }
    _ref1 = this.agents;
    for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
      a = _ref1[_j];
      poorWater = !this.isPrecipitationOptimalFor(a.type);
      if (this.plantData[a.type].hasBrownVariant && !a.isSeed) {
        if (this.isPrecipitationTooLowFor(a.type)) {
          if (!a.isBrowned) {
            a.shape = "brown" + a.shape;
            a.isBrowned = true;
          }
        } else if (a.isBrowned) {
          a.shape = a.shape.match(/brown(.*)/)[1];
          a.isBrowned = false;
        }
      }
      if (a.isSeed) {
        if (this.yearTick() === a.germinationDate) {
          if (poorWater) {
            if (u.randomFloat(1) < this.plantData[a.type].mortalityInPoorWater) {
              killList.push(a);
            } else if (!this.plantData[a.type].annual) {
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
              if (!(a.isRoot || a.growthPeriods[a.period] === Infinity)) {
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
                if (a.type === "wheat") {
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
          growthRate *= 0.85;
        }
        a.size *= growthRate + 1;
        if (a.size <= 0) {
          killList.push(a);
        }
      }
    }
    _results = [];
    for (_k = 0, _len2 = killList.length; _k < _len2; _k++) {
      a = killList[_k];
      _results.push(a.die());
    }
    return _results;
  };

  PlantEngine.prototype.topsoilRateFactor = function(agent) {
    var topsoilDepth, x, y, _ref;
    _ref = [agent.p.x, agent.p.y], x = _ref[0], y = _ref[1];
    topsoilDepth = 0;
    while (this.patches.patch(x, y - topsoilDepth).isTopsoil) {
      topsoilDepth++;
    }
    return 0.3 * Math.min(topsoilDepth, this.INITIAL_TOPSOIL_DEPTH) / this.INITIAL_TOPSOIL_DEPTH + 0.7;
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
        root.periodAge = 0;
        return root.isBrowned = plant.isBrowned;
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
        }
      } else if (managementPlan[zone] === "bare") {
        quality -= 0.03;
      } else {
        quality += 0.01;
      }
      quality = Math.max(Math.min(quality, 2), 0);
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
      initialSize: 0.4,
      growthPeriods: [100, 1800, 4800, 1300, 1200],
      growthRates: [0.00042, 0.00116, 0.00003, -0.00018, -0.00019],
      rootGrowthRates: [0, -0.0005, 0, -0.0005, -0.0005],
      periodVariation: 0.22,
      minimumPrecipitation: 14,
      maximumPrecipitation: 450,
      isAffectedByPoorWaterAfterPlanting: false,
      mortalityInPoorWater: 0.15,
      shapes: ["tree1", "tree2", "tree3"]
    },
    grass: {
      quantity: 33,
      inRows: false,
      annual: false,
      initialSize: 0.2,
      minGermination: 1,
      maxGermination: 800,
      rootGrowthRates: [0, -0.001, 0, -0.001, -0.001],
      growthPeriods: [120, 210, 1400, Infinity, Infinity],
      growthRates: [0.0043, 0.0053, 0.0003, 0, 0],
      periodVariation: 0.15,
      minimumPrecipitation: 14,
      maximumPrecipitation: 450,
      isAffectedByPoorWaterAfterPlanting: true,
      mortalityInPoorWater: 0.15,
      shapes: ["grass1", "grass2"],
      hasBrownVariant: false
    },
    wheat: {
      quantity: 19,
      inRows: true,
      annual: true,
      initialSize: 0.2,
      minGermination: 60,
      maxGermination: 90,
      growthPeriods: [120, 210, 350, 100, 100],
      growthRates: [0.0049, 0.0061, 0.0008, 0.0003, -0.0027],
      rootGrowthRates: [0, 0, 0, -0.001, -0.001],
      periodVariation: 0.04,
      minimumPrecipitation: 14,
      maximumPrecipitation: 450,
      isAffectedByPoorWaterAfterPlanting: false,
      mortalityInPoorWater: 0.5,
      shapes: ["wheat1", "wheat2"]
    }
  };

  return PlantEngine;

})();

window.PlantEngine = PlantEngine;
});

;
//# sourceMappingURL=app.js.map