/*jshint indent: false, quotmark: false */
/*global window, iframePhone */

(function() {
  "use strict";

  window.setupLabCommunication = function(model) {
    var phone = iframePhone.getIFrameEndpoint();

    // Register Scripting API functions.
    function registerModelFunc(name) {
      phone.addListener(name, function() {
        model[name].apply(model, arguments);
        model.draw();
      });
      phone.post('registerScriptingAPIFunc', name);
    }

    function registerCustomFunc(name, func) {
      phone.addListener(name, func);
      phone.post('registerScriptingAPIFunc', name);
    }

    registerCustomFunc('play', function() {
      model.start();
      // Notify iframe model that we received 'play' message and reacted appropriately.
      phone.post('play.iframe-model');
    });
    registerCustomFunc('stop', function() {
      model.stop();
      // Notify iframe model that we received 'stop' message and reacted appropriately.
      phone.post('stop.iframe-model');
    });
    registerModelFunc('createCO2');
    registerModelFunc('createVapor');
    registerModelFunc('addCO2');
    registerModelFunc('subtractCO2')
    registerModelFunc('addCloud');
    registerModelFunc('subtractCloud');
    registerModelFunc('erupt');
    registerModelFunc('addSunraySpotlight');
    registerModelFunc('addCO2Spotlight');
    registerModelFunc('removeSpotlight');
    registerModelFunc('hide90');
    registerModelFunc('showAll');

    // Properties.
    phone.addListener('set', function (content) {
      var spotlight = null;
      switch(content.name) {
        case 'albedo':
          model.setAlbedo(content.value);
          break;
        case 'sunBrightness':
          model.setSunBrightness(content.value);
          break;
        case 'animRate':
          model.anim.setRate(content.value, false);
          break;
        case 'showGases':
          model.showGases(content.value);
          break;
        case 'showRays':
          model.showRays(content.value);
          break;
        case 'showHeat':
          model.showHeat(content.value);
          break;
        case 'keyLabels':
          model.restrictKeyLabelsTo = content.value;
          break;
        case 'includeWaterVapor':
          model.setIncludeWaterVapor(content.value);
          break;
        case 'oceanAbsorbtionChangable':
          model.setOceanAbsorbtionChangable(content.value);
          break;
        case 'useFixedTemperature':
          model.setUseFixedTemperature(content.value);
          break;
        case 'fixedTemperature':
          model.setFixedTemperature(content.value);
          break;
        case 'oceanTemperature':
          model.oceanTemperature = content.value;
          break;
        case 'nCO2Emission':
          model.nCO2Emission = content.value;
          break;
        case 'vaporPerDegreeModifier':
          model.vaporPerDegreeModifier = content.value;
          break;
      }
    });

    var getOutputs = (function(argument) {
      var _initialTemperature = model.getTemperature();
      return function getOutputs() {
        return {
          year: model.getFractionalYear(),
          temperatureChange: model.getTemperature() - _initialTemperature,
          co2Concentration: model.getCO2Count(),
          // Spotlight may be automatically deactivated when an observed agent leaves the model.
          // Notify Lab model about that using output.
          spotlightActive: !!climateModel.spotlightAgent
        };
      };
    }());

    // Set initial output values.
    phone.post('outputs', getOutputs());

    model.stepCallback = function() {
      // We could also write:
      // phone.post('outputs', { ... });
      // phone.post('tick');
      // However Lab supports outputs in 'tick' handler too, so we can send only one message.
      phone.post('tick', {
        outputs: getOutputs()
      });
    };

    phone.initialize();
  };
}());
