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
var AirPollutionControls;

AirPollutionControls = (function() {
  function AirPollutionControls() {}

  AirPollutionControls.prototype.setupCompleted = false;

  AirPollutionControls.prototype.setup = function() {
    if (this.setupCompleted) {
      return $("#controls").show();
    } else {
      this.setupGraph();
      this.setupPlayback();
      this.setupSliders();
      $("#controls").show();
      return this.setupCompleted = true;
    }
  };

  AirPollutionControls.prototype.pollutionGraph = null;

  AirPollutionControls.prototype.setupGraph = function() {
    var appendKeyToGraph, defaultOptions, drawKey, labelInfo;
    if ($("#output-graphs").length === 0) {
      return;
    }
    appendKeyToGraph = function(graphId, top, labelInfo) {
      var $graph;
      $graph = $("#" + graphId);
      $graph.append('<a href="#" class="show-key">show key</a>');
      return $graph.find('.show-key').click(function() {
        var $key, canvas;
        if (!($("#" + graphId + "-key").length > 0)) {
          $key = $("<div id=\"" + graphId + "-key\" class=\"key\"><a class=\"icon-remove-sign icon-large\"></a><canvas></canvas></div>").appendTo($(document.body)).draggable();
          canvas = $key.find('canvas')[0];
          $key.height(18 * (labelInfo.length + 1));
          canvas.height = $key.outerHeight();
          canvas.width = $key.outerWidth();
          drawKey($key.find('canvas')[0], labelInfo);
        }
        $key = $("#" + graphId + "-key");
        return $key.css({
          left: '370px',
          top: "" + top + "px"
        }).show().on('click', 'a', function() {
          return $(this).parent().hide();
        });
      });
    };
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
    ABM.model.graphSampleInterval = 10;
    defaultOptions = {
      title: "Primary (brown), Secondary (orange) Pollutants",
      xlabel: "Time (ticks)",
      ylabel: "AQI",
      xmax: 2100,
      xmin: 0,
      ymax: 300,
      ymin: 0,
      xTickCount: 7,
      yTickCount: 10,
      xFormatter: "0f",
      yFormatter: "0f",
      sample: 10,
      realTime: true,
      fontScaleRelativeToParent: true,
      dataColors: [AirPollutionModel.pollutantColors.primary, AirPollutionModel.pollutantColors.secondary]
    };
    this.pollutionGraph = LabGrapher('#pollution-graph', defaultOptions);
    labelInfo = [
      {
        color: AirPollutionModel.pollutantColors.primary,
        label: "Primary Pollutants"
      }, {
        color: AirPollutionModel.pollutantColors.secondary,
        label: "Secondary Pollutants"
      }
    ];
    appendKeyToGraph('pollution-graph', 20, labelInfo);
    this.pollutionGraph.addSamples([[0], [0]]);
    $(".draggable-axis[x=24]").css("cursor", "default").attr("pointer-events", "none");
    $(".y text").css("cursor", "default");
    return $(document).on(AirPollutionModel.GRAPH_INTERVAL_ELAPSED, (function(_this) {
      return function() {
        var p, s;
        p = ABM.model.primaryAQI();
        s = ABM.model.secondaryAQI();
        _this.pollutionGraph.addSamples([[p], [s]]);
        $("#raw-primary").text(ABM.model.primary.length);
        $("#raw-secondary").text(ABM.model.secondary.length);
        $("#aqi-primary").text(p);
        return $("#aqi-secondary").text(s);
      };
    })(this));
  };

  AirPollutionControls.prototype.setupPlayback = function() {
    $(".icon-pause").hide();
    $(".icon-play").show();
    $("#controls").show();
    $("#play-pause-button").button().click((function(_this) {
      return function() {
        return _this.startStopModel();
      };
    })(this));
    $("#reset-button").button().click((function(_this) {
      return function() {
        return _this.resetModel();
      };
    })(this));
    return $("#playback").buttonset();
  };

  AirPollutionControls.prototype.setupSliders = function() {
    $("#wind-slider").slider({
      orientation: 'horizontal',
      min: -100,
      max: 100,
      step: 10,
      value: ABM.model.windSpeed,
      slide: function(evt, ui) {
        var opacity;
        ABM.model.setWindSpeed(ui.value);
        if (ui.value > 0) {
          opacity = 0.5 - (ui.value / 60);
          return $("#lower-air-temperature").stop().animate({
            opacity: opacity
          });
        } else {
          return $("#lower-air-temperature").stop().animate({
            opacity: 1
          });
        }
      }
    });
    $("#cars-slider").slider({
      orientation: 'horizontal',
      min: 0,
      max: 10,
      step: 1,
      value: ABM.model.getNumCars(),
      slide: function(evt, ui) {
        return ABM.model.setNumCars(ui.value);
      }
    });
    $("#sunlight-slider").slider({
      orientation: 'horizontal',
      min: 0,
      max: 10,
      step: 1,
      value: ABM.model.sunlightAmount,
      slide: function(evt, ui) {
        return ABM.model.setSunlight(ui.value);
      },
      change: function(evt, ui) {
        return ABM.model.setSunlight(ui.value);
      }
    });
    $("#rain-slider").slider({
      orientation: 'horizontal',
      min: 0,
      max: 6,
      step: 1,
      value: ABM.model.rainRate,
      slide: function(evt, ui) {
        return ABM.model.setRainRate(ui.value);
      },
      change: function(evt, ui) {
        return ABM.model.setRainRate(ui.value);
      }
    });
    $("#cars-pollution-slider").slider({
      orientation: 'horizontal',
      min: 0,
      max: 100,
      step: 5,
      value: ABM.model.carPollutionRate,
      slide: function(evt, ui) {
        return ABM.model.carPollutionRate = ui.value;
      }
    });
    $("#cars-pollution-control-slider").slider({
      orientation: 'horizontal',
      min: 0,
      max: 100,
      step: 5,
      value: 100 - ABM.model.carPollutionRate,
      slide: function(evt, ui) {
        return ABM.model.carPollutionRate = 100 - ui.value;
      }
    });
    $("#cars-electric-slider").slider({
      orientation: 'horizontal',
      min: 0,
      max: 100,
      step: 10,
      value: ABM.model.electricCarPercentage,
      slide: function(evt, ui) {
        return ABM.model.electricCarPercentage = ui.value;
      }
    });
    $("#factories-slider").slider({
      orientation: 'horizontal',
      min: 0,
      max: 5,
      step: 1,
      value: ABM.model.getNumFactories(),
      slide: function(evt, ui) {
        return ABM.model.setNumFactories(ui.value);
      }
    });
    $("#factories-pollution-slider").slider({
      orientation: 'horizontal',
      min: 0,
      max: 100,
      step: 5,
      value: ABM.model.factoryPollutionRate,
      slide: function(evt, ui) {
        return ABM.model.factoryPollutionRate = ui.value;
      }
    });
    $("#factories-pollution-control-slider").slider({
      orientation: 'horizontal',
      min: 0,
      max: 100,
      step: 5,
      value: 100 - ABM.model.factoryPollutionRate,
      slide: function(evt, ui) {
        return ABM.model.factoryPollutionRate = 100 - ui.value;
      }
    });
    return $("#temperature-slider").slider({
      orientation: 'horizontal',
      min: 0,
      max: 100,
      step: 10,
      value: ABM.model.temperature,
      slide: function(evt, ui) {
        return ABM.model.temperature = ui.value;
      }
    });
  };

  AirPollutionControls.prototype.startStopModel = function() {
    if (!this.startModel()) {
      return this.stopModel();
    }
  };

  AirPollutionControls.prototype.stopModel = function() {
    if (ABM.model.anim.animStop) {
      return false;
    } else {
      ABM.model.stop();
      $(".icon-pause").hide();
      $(".icon-play").show();
      return true;
    }
  };

  AirPollutionControls.prototype.startModel = function() {
    if (ABM.model.anim.animStop) {
      ABM.model.start();
      $(".icon-pause").show();
      $(".icon-play").hide();
      return true;
    } else {
      return false;
    }
  };

  AirPollutionControls.prototype.resetModel = function() {
    this.stopModel();
    $(".icon-pause").hide();
    $(".icon-play").show();
    this.pollutionGraph.reset();
    this.pollutionGraph.addSamples([[0], [0], [0], [0]]);
    return setTimeout(function() {
      return ABM.model.reset();
    }, 10);
  };

  return AirPollutionControls;

})();

window.AirPollutionControls = AirPollutionControls;
});

;require.register("src/main", function(exports, require, module) {
require('src/model');

require('src/controls');
});

;require.register("src/model", function(exports, require, module) {
var AirPollutionModel,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

AirPollutionModel = (function(_super) {
  __extends(AirPollutionModel, _super);

  AirPollutionModel.GRAPH_INTERVAL_ELAPSED = 'graph-interval-lapsed';

  AirPollutionModel.pollutantColors = {
    primary: [102, 73, 53],
    secondary: [244, 121, 33]
  };

  AirPollutionModel.prototype.LEFT = ABM.util.degToRad(180);

  AirPollutionModel.prototype.RIGHT = 0;

  AirPollutionModel.prototype.UP = ABM.util.degToRad(90);

  AirPollutionModel.prototype.DOWN = ABM.util.degToRad(270);

  AirPollutionModel.prototype.PI2 = Math.PI * 2;

  AirPollutionModel.prototype.FACTORY_POLLUTION_SPAWN_OFFSETS = [
    {
      x: 133,
      y: 3
    }, {
      x: 122,
      y: -5
    }, {
      x: 106,
      y: -15
    }, {
      x: 93,
      y: -19
    }
  ];

  AirPollutionModel.prototype.FACTORY_SPAWN_POS = [
    {
      x: 160,
      y: 160,
      size: 1
    }, {
      x: 100,
      y: 100,
      size: 0.5
    }, {
      x: 240,
      y: 120,
      size: 0.8
    }, {
      x: 320,
      y: 120,
      size: 0.5
    }, {
      x: 90,
      y: 110,
      size: 0.3
    }
  ];

  AirPollutionModel.prototype.CAR_SPAWN = null;

  AirPollutionModel.prototype.includeSunlight = true;

  AirPollutionModel.prototype.includeInversionLayer = false;

  AirPollutionModel.prototype.mountainsX = 410;

  AirPollutionModel.prototype.oceanX = 120;

  AirPollutionModel.prototype.landY = 85;

  AirPollutionModel.prototype.inversionY = 190;

  AirPollutionModel.prototype.rainMax = 350;

  AirPollutionModel.prototype.graphSampleInterval = 10;

  AirPollutionModel.prototype.windSpeed = 0;

  AirPollutionModel.prototype.maxNumCars = 10;

  AirPollutionModel.prototype.maxNumFactories = 5;

  AirPollutionModel.prototype.factoryDensity = 5;

  AirPollutionModel.prototype.carPollutionRate = 60;

  AirPollutionModel.prototype.electricCarPercentage = 25;

  AirPollutionModel.prototype.factoryPollutionRate = 100;

  AirPollutionModel.prototype.raining = false;

  AirPollutionModel.prototype.temperature = 50;

  AirPollutionModel.prototype.inversionStrength = 0;

  AirPollutionModel.prototype.sunlightAmount = 6;

  AirPollutionModel.prototype.rainRate = 3;

  AirPollutionModel.prototype.nextRainEnd = 0;

  function AirPollutionModel() {
    AirPollutionModel.__super__.constructor.apply(this, arguments);
    this.setNumFactories(0);
    this.setRootVars();
  }

  AirPollutionModel.prototype.setup = function() {
    var factoryImg;
    this.anim.setRate(50, false);
    this.setFastPatches();
    this.patches.usePixels(true);
    this.setTextParams({
      name: "drawing"
    }, "10px sans-serif");
    this.setLabelParams({
      name: "drawing"
    }, [255, 255, 255], [0, -20]);
    this.patches.importColors("img/air-pollution-bg-mask.png", (function(_this) {
      return function() {
        return _this.setupCars();
      };
    })(this));
    this.patches.importDrawing("img/air-pollution-bg.png");
    this.setCacheAgentsHere();
    ['sedan-left-side', 'sedan-right-side', 'sedan-front-quarter', 'sedan-rear-quarter', 'sedan-front', 'sedan-rear'].forEach(function(shapeName) {
      var flip, img;
      img = document.getElementById(shapeName.replace(/-.*-side/, '-side'));
      flip = (shapeName.indexOf('-right-side') > 0) || (shapeName.indexOf('-front-quarter') > 0);
      return ABM.shapes.add(shapeName, false, function(ctx) {
        ctx.scale((flip ? -1 : 1), -1);
        ctx.translate(0, -img.height);
        if (flip) {
          ctx.translate(-img.width, 0);
        }
        return ctx.drawImage(img, 0, 0);
      });
    });
    factoryImg = document.getElementById('factory-sprite');
    ABM.shapes.add("factory", false, (function(_this) {
      return function(ctx) {
        ctx.scale(-1, 1);
        ctx.rotate(_this.LEFT);
        return ctx.drawImage(factoryImg, 0, 0);
      };
    })(this));
    ABM.shapes.add("pollutant", false, (function(_this) {
      return function(ctx) {
        ctx.arc(-0.5, -0.5, 0.5, 0, _this.PI2, false);
        ctx.arc(0.5, -0.5, 0.5, 0, _this.PI2, false);
        ctx.arc(0, 0.5, 0.5, 0, _this.PI2, false);
        return ctx.fill();
      };
    })(this));
    this.agentBreeds("wind cars factories primary secondary rain sunlight");
    this.setupFactories();
    this.setupWind();
    this.setupPollution();
    this.setupRain();
    if (this.includeSunlight) {
      this.setupSunlight();
    }
    this.nextRainEnd = 0;
    this.raining = false;
    this.draw();
    return this.refreshPatches = false;
  };

  AirPollutionModel.prototype.reset = function() {
    AirPollutionModel.__super__.reset.apply(this, arguments);
    this.setup();
    return this.anim.draw();
  };

  AirPollutionModel.prototype.step = function() {
    this.moveWind();
    this.moveCars();
    this.movePollution();
    this.pollute();
    if (this.includeSunlight) {
      this.moveAndEmitSunlight();
    }
    this.moveRain();
    this.checkForRain();
    if (this.anim.ticks % this.graphSampleInterval === 0) {
      this.notifyGraphs();
    }
  };

  AirPollutionModel.prototype.setupWind = function() {
    this.wind.setDefaultSize(5);
    this.wind.setDefaultColor([0, 0, 255, 0.2]);
    this.wind.setDefaultShape("arrow");
    this.wind.setDefaultHidden(true);
    this.wind.setDefaultHeading(0);
    return this.wind.create(30, (function(_this) {
      return function(w) {
        var row, x, y;
        row = Math.floor((_this.wind.length - 1) / 5);
        x = ((_this.wind.length - 1) % 5) * 90 + (row * 30);
        y = row * 30 + 10;
        return w.moveTo(_this.patches.patchXY(x, y));
      };
    })(this));
  };

  AirPollutionModel.prototype.setupCars = function() {
    var i, p, tracks, _i;
    this.cars.setDefaultSize(1);
    tracks = [];
    p = ABM.patches.patchXY(ABM.patches.maxX, ABM.patches.maxY);
    for (i = _i = 0; _i <= 1; i = ++_i) {
      while (!(p.color[0] === 255 && p.color[1] === 0)) {
        p = p.n[1];
        if (p.y < 1) {
          break;
        }
      }
      tracks[i] = this.followTrack(p);
      p = p.n[1];
    }
    tracks[1].reverse();
    this.tracks = tracks.map(function(track, i) {
      var headingLeft, yMax, yMin, _ref;
      headingLeft = i === 0;
      _ref = [track[0].y, track[track.length - 1].y].sort(function(a, b) {
        return a - b;
      }), yMin = _ref[0], yMax = _ref[1];
      return track.map(function(p) {
        var dist, distsq;
        dist = (p.y - yMin) / (yMax - yMin);
        distsq = dist * dist;
        return {
          patch: p,
          dwellTime: 1 + Math.ceil(5 * distsq),
          scale: 1 - 0.9 * distsq,
          shapeSuffix: p.color[1] > 100 ? headingLeft ? 'rear-quarter' : 'front-quarter' : p.color[2] > 100 ? headingLeft ? 'rear' : 'front' : headingLeft ? 'left-side' : 'right-side'
        };
      });
    });
    this.cars.create(1, (function(_this) {
      return function(car) {
        car.track = _this.tracks[0];
        return car.moveTo(car.track[0].patch);
      };
    })(this));
    return this.cars.create(1, (function(_this) {
      return function(car) {
        car.track = _this.tracks[1];
        return car.moveTo(car.track[0].patch);
      };
    })(this));
  };

  AirPollutionModel.prototype.followTrack = function(p) {
    var i, indexOfReddest, neighbors, patches, reds, reversed, track;
    track = [];
    reversed = false;
    while (p.color[0] > 50) {
      track.push(p);
      neighbors = reversed ? [4, 7, 6, 5] : [3, 5, 6, 7];
      patches = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = neighbors.length; _i < _len; _i++) {
          i = neighbors[_i];
          _results.push(p.n[i]);
        }
        return _results;
      })();
      reds = patches.map(function(p) {
        return p.color[0];
      });
      indexOfReddest = reds.indexOf(Math.max.apply(null, reds));
      p = patches[indexOfReddest];
      if (indexOfReddest === 3 && !reversed) {
        reversed = true;
      }
    }
    return track;
  };

  AirPollutionModel.prototype.setupFactories = function() {
    this.factories.setDefaultSize(1);
    this.factories.setDefaultHeading(this.LEFT);
    this.factories.setDefaultShape("factory");
    this.factories.setDefaultColor([0, 0, 0]);
    this.factories.setDefaultHidden(true);
    this.factories.create(this.maxNumFactories, (function(_this) {
      return function(f) {
        var pos;
        pos = _this.FACTORY_SPAWN_POS[_this.factories.length - 1];
        f.moveTo(_this.patches.patchXY(pos.x, pos.y));
        f.size = pos.size;
        return f.createTick = _this.anim.ticks || 0;
      };
    })(this));
    return this.setNumFactories(1);
  };

  AirPollutionModel.prototype.setupPollution = function() {
    this.primary.setDefaultSize(3);
    this.primary.setDefaultHeading(this.UP);
    this.primary.setDefaultShape("circle");
    this.primary.setDefaultColor(AirPollutionModel.pollutantColors.primary);
    this.primary.setDefaultHidden(false);
    this.secondary.setDefaultSize(3);
    this.secondary.setDefaultHeading(this.UP);
    this.secondary.setDefaultShape("circle");
    this.secondary.setDefaultColor(AirPollutionModel.pollutantColors.secondary);
    return this.secondary.setDefaultHidden(false);
  };

  AirPollutionModel.prototype.setupRain = function() {
    return this.rain.create(220, (function(_this) {
      return function(c) {
        var x, y;
        x = ABM.util.randomInt(_this.world.maxX - _this.world.minX) + _this.world.minX;
        y = ABM.util.randomInt(_this.rainMax - _this.world.minY) + _this.world.minY;
        c.moveTo(_this.patches.patchXY(x, y));
        c.heading = _this.DOWN;
        c.size = 2;
        c.shape = "circle";
        c.color = [0, 0, 128];
        return c.hidden = true;
      };
    })(this));
  };

  AirPollutionModel.prototype.setupSunlight = function() {
    this.sunlight.setDefaultSize(2);
    this.sunlight.setDefaultHeading(Math.PI * 7 / 4);
    this.sunlight.setDefaultShape("circle");
    this.sunlight.setDefaultColor([255, 255, 0]);
    return this.sunlight.setDefaultHidden(false);
  };

  AirPollutionModel.prototype.setWindSpeed = function(speed) {
    var r, w, _i, _j, _len, _len1, _ref, _ref1;
    this.windSpeed = speed;
    _ref = this.wind;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      w = _ref[_i];
      w.hidden = speed === 0;
      w.size = Math.abs(this._intSpeed(10)) + 5;
      w.heading = speed >= 0 ? 0 : this.LEFT;
    }
    _ref1 = this.rain;
    for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
      r = _ref1[_j];
      r.heading = this.DOWN + ABM.util.degToRad(this.windSpeed / 2);
    }
    if (speed <= 0) {
      this.inversionStrength = 0;
    } else {
      this.inversionStrength = speed * 4.5 / 100;
    }
    if (this.anim.animStop) {
      return this.draw();
    }
  };

  AirPollutionModel.prototype.setNumCars = function(n) {};

  AirPollutionModel.prototype.getNumVisible = function(xs) {
    return xs.filter(function(x) {
      return !x.hidden;
    }).length;
  };

  AirPollutionModel.prototype.getNumCars = function() {
    return this.getNumVisible(this.cars);
  };

  AirPollutionModel.prototype.setNumFactories = function(n) {
    var f, i, _i, _ref;
    for (i = _i = 0, _ref = this.factories.length; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
      f = this.factories[i];
      f.hidden = i >= n;
    }
    if (this.anim.animStop) {
      return this.draw();
    }
  };

  AirPollutionModel.prototype.getNumFactories = function() {
    return this.getNumVisible(this.factories);
  };

  AirPollutionModel.prototype.moveWind = function() {
    var speed, w, x, y, _i, _len, _ref, _results;
    speed = this._intSpeed(15);
    _ref = this.wind;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      w = _ref[_i];
      y = w.y;
      x = w.x + speed;
      if (x > this.mountainsX) {
        x = x - this.mountainsX;
      } else if (x < 0) {
        x = x + this.mountainsX;
      }
      _results.push(w.moveTo(this.patches.patchXY(x, y)));
    }
    return _results;
  };

  AirPollutionModel.prototype.moveCars = function() {
    var car, patchInfo, _i, _len, _ref;
    _ref = this.cars;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      car = _ref[_i];
      if (car.trackIndex == null) {
        car.trackIndex = 0;
      }
      if (car.ttlAtPatch == null) {
        car.ttlAtPatch = 1;
      }
      if (--car.ttlAtPatch !== 0) {
        continue;
      }
      if (++car.trackIndex === car.track.length) {
        car.trackIndex = 0;
      }
      patchInfo = car.track[car.trackIndex];
      car.moveTo(patchInfo.patch);
      car.ttlAtPatch = patchInfo.dwellTime;
      car.size = patchInfo.scale;
      car.shape = 'sedan-' + patchInfo.shapeSuffix;
    }
    return null;
  };

  AirPollutionModel.prototype.movePollution = function() {
    var a, pollutionToRemove, _i, _j, _k, _len, _len1, _len2, _ref, _ref1, _results;
    pollutionToRemove = [];
    _ref = this.primary;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      a = _ref[_i];
      if (this._movePollutionAgent(a)) {
        pollutionToRemove.push(a);
      }
    }
    _ref1 = this.secondary;
    for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
      a = _ref1[_j];
      if (this._movePollutionAgent(a)) {
        pollutionToRemove.push(a);
      }
    }
    _results = [];
    for (_k = 0, _len2 = pollutionToRemove.length; _k < _len2; _k++) {
      a = pollutionToRemove[_k];
      _results.push(a.die());
    }
    return _results;
  };

  AirPollutionModel.prototype._movePollutionAgent = function(a) {
    var distance, speed, trapProb, u, _ref, _ref1;
    u = ABM.util;
    a.heading += u.randomCentered(Math.PI / 9);
    if (a.heading > Math.PI) {
      a.heading -= 2 * Math.PI;
    }
    if (a.heading < -Math.PI) {
      a.heading += 2 * Math.PI;
    }
    if (this.includeInversionLayer) {
      if (((this.inversionY - 10) < (_ref = a.p.y) && _ref <= this.inversionY)) {
        if ((0 < (_ref1 = a.heading) && _ref1 < Math.PI)) {
          trapProb = this.inversionStrength - (this.inversionY - a.p.y) * (this.inversionStrength / 10);
          if (Math.random() < trapProb) {
            a.heading -= Math.PI;
          }
        }
      }
    }
    speed = (this.temperature + 1) / 250;
    a.forward(speed);
    if (this._shouldRemovePollution(a)) {
      return true;
    }
    distance = (this.windSpeed / 100) * (1 - a.p.color[0] / 255);
    a.setXY(a.x + distance, a.y);
    if (this._shouldRemovePollution(a)) {
      return true;
    }
    if (!this.includeInversionLayer) {
      a.setXY(a.x, a.y + Math.pow(2, (this.temperature - 130) / 20));
      this._resetHeading(a);
    }
    return false;
  };

  AirPollutionModel.prototype._resetHeading = function(a) {
    if (a.y <= 20) {
      return a.heading = u.randomFloat2(Math.PI / 4, Math.PI * 3 / 4);
    } else if (a.y >= 340) {
      return a.heading = u.randomFloat2(-Math.PI / 4, -Math.PI * 3 / 4);
    }
  };

  AirPollutionModel.prototype._shouldRemovePollution = function(a) {
    return a.x < this.world.minX + 1 || a.x > this.world.maxX - 1 || a.y < this.world.minY + 1 || a.y > this.world.maxX - 1;
  };

  AirPollutionModel.prototype._killPollutionOnPatch = function(p) {
    var a, _i, _len, _ref, _results;
    _ref = p.agentsHere();
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      a = _ref[_i];
      if ((a != null) && (a.breed === this.primary || a.breed === this.secondary)) {
        _results.push(a.die());
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  };

  AirPollutionModel.prototype.setRainRate = function(rainRate) {
    this.rainRate = rainRate;
    this.nextRainEnd = 0;
    return this.checkForRain(this.rainRate === 6);
  };

  AirPollutionModel.prototype.checkForRain = function(force) {
    if (force == null) {
      force = false;
    }
    if (this.anim.ticks > this.nextRainEnd || force) {
      this.nextRainStart = this.anim.ticks + u.randomInt(300) + 1800 - (this.rainRate * 300);
      if (force) {
        this.nextRainStart = this.anim.ticks + 10;
      }
      this.nextRainEnd = u.randomInt(130) + (30 * this.rainRate);
      this.nextRainEnd += this.raining ? this.anim.ticks : this.nextRainStart;
    }
    if (this.anim.ticks === this.nextRainStart) {
      this.startRain();
    }
    if (this.anim.ticks === this.nextRainEnd) {
      return this.stopRain();
    }
  };

  AirPollutionModel.prototype.moveRain = function() {
    var p, r, _i, _j, _len, _len1, _ref, _ref1, _results;
    if (this.raining) {
      _ref = this.rain;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        r = _ref[_i];
        if (r.hidden) {
          continue;
        }
        _ref1 = this.patches.patchRect(r.p, 3, 3, true);
        for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
          p = _ref1[_j];
          this._killPollutionOnPatch(p);
        }
        r.forward(2);
        if (r.y > this.rainMax) {
          _results.push(r.setXY(r.x, this.rainMax));
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    }
  };

  AirPollutionModel.prototype.startRain = function() {
    var r, _i, _len, _ref;
    if (this.raining) {
      return;
    }
    _ref = this.rain;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      r = _ref[_i];
      r.hidden = false;
    }
    this.raining = true;
    return this.nextRainStart = 0;
  };

  AirPollutionModel.prototype.stopRain = function() {
    var r, _i, _len, _ref;
    if (!this.raining) {
      return;
    }
    _ref = this.rain;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      r = _ref[_i];
      r.hidden = true;
    }
    this.raining = false;
    return this.nextRainEnd = 0;
  };

  AirPollutionModel.prototype._convertPollutionOnPatch = function(p) {
    var a, converted, newA, _i, _len, _ref;
    converted = false;
    _ref = p.agentsHere();
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      a = _ref[_i];
      if ((a != null) && a.breed === this.primary) {
        if (u.randomInt(4) === 0) {
          p.sprout(1, this.secondary, function(_a) {
            return _a.heading = Math.PI / 2;
          });
        } else {
          newA = a.changeBreed(this.secondary)[0];
          newA.heading = a.heading;
        }
        converted = true;
      }
    }
    return converted;
  };

  AirPollutionModel.prototype.setSunlight = function(amount) {
    return this.sunlightAmount = amount;
  };

  AirPollutionModel.prototype.moveAndEmitSunlight = function() {
    var converted, interval, p, s, toKill, _i, _j, _k, _len, _len1, _len2, _ref, _ref1, _results;
    interval = 21 - (this.sunlightAmount * 2);
    if (this.raining) {
      interval = 30;
    }
    if (this.anim.ticks % interval === 0) {
      this.sunlight.create(1, (function(_this) {
        return function(s) {
          var x, y, _ref;
          _ref = _this.randomLocationFromNWCorner(), x = _ref[0], y = _ref[1];
          return s.setXY(x, y);
        };
      })(this));
    }
    toKill = [];
    _ref = this.sunlight;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      s = _ref[_i];
      converted = false;
      _ref1 = this.patches.patchRect(s.p, 2, 2, true);
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        p = _ref1[_j];
        converted || (converted = this._convertPollutionOnPatch(p));
      }
      if (converted || s.x + 2 > this.world.maxX || s.x - 2 < this.world.minX || s.y - 2 < this.world.minY) {
        toKill.push(s);
      } else {
        s.forward(2);
      }
    }
    _results = [];
    for (_k = 0, _len2 = toKill.length; _k < _len2; _k++) {
      s = toKill[_k];
      _results.push(s.die());
    }
    return _results;
  };

  AirPollutionModel.prototype.randomLocationFromNWCorner = function() {
    var loc;
    loc = u.randomInt(this.world.width + this.world.height - this.landY);
    if (loc < this.world.width) {
      return [loc, this.world.maxY];
    } else {
      return [2, this.landY + loc - this.world.width];
    }
  };

  AirPollutionModel.prototype.pollute = function() {
    var c, f, _i, _j, _len, _len1, _ref, _ref1, _results;
    _ref = this.cars;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      c = _ref[_i];
      if ((c != null) && !c.hidden) {
        if (ABM.util.randomInt(3000) < this.carPollutionRate && ABM.util.randomInt(100) > this.electricCarPercentage) {
          this.primary.create(1, (function(_this) {
            return function(p) {
              var x;
              x = c.heading === 0 ? c.x - 37 : c.x + 37;
              return p.moveTo(_this.patches.patchXY(x, c.y - 10));
            };
          })(this));
        }
      }
    }
    _ref1 = this.factories;
    _results = [];
    for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
      f = _ref1[_j];
      if ((f != null) && !f.hidden) {
        if (ABM.util.randomInt(2500) < this.factoryPollutionRate) {
          _results.push(this.primary.create(1, (function(_this) {
            return function(p) {
              var offset;
              offset = _this.FACTORY_POLLUTION_SPAWN_OFFSETS[ABM.util.randomInt(_this.FACTORY_POLLUTION_SPAWN_OFFSETS.length)];
              return p.moveTo(_this.patches.patchXY(f.x + Math.round(offset.x * f.size), f.y + Math.round(offset.y * f.size)));
            };
          })(this)));
        } else {
          _results.push(void 0);
        }
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  };

  AirPollutionModel.prototype.notifyGraphs = function() {
    return $(document).trigger(AirPollutionModel.GRAPH_INTERVAL_ELAPSED);
  };

  AirPollutionModel.prototype.primaryAQI = function() {
    var p;
    p = this.primary.length;
    return p;
  };

  AirPollutionModel.prototype.secondaryAQI = function() {
    var p;
    p = this.secondary.length;
    return p;
  };

  AirPollutionModel.prototype._intSpeed = function(divisor) {
    var speed;
    speed = this.windSpeed / divisor;
    if (this.windSpeed < 0) {
      return Math.floor(speed);
    } else {
      return Math.ceil(speed);
    }
  };

  return AirPollutionModel;

})(ABM.Model);

window.AirPollutionModel = AirPollutionModel;
});

;
//# sourceMappingURL=app.js.map