/*jshint indent: false, quotmark: false */
/*global window, iframePhone */

(function() {
  "use strict";

  window.setupLabCommunication = function(model) {
    var phone = iframePhone.getIFrameEndpoint();

    // Register Scripting API functions.
    function registerModelFunc(name) {
      phone.addListener(name, function() {
        model[name]();
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
    registerModelFunc('addCO2');
    registerModelFunc('subtractCO2')
    registerModelFunc('addCloud');
    registerModelFunc('subtractCloud');
    registerModelFunc('erupt');
    registerModelFunc('addSunraySpotlight');
    registerModelFunc('addCO2Spotlight');
    registerModelFunc('removeSpotlight');

    // Properties.
    phone.addListener('set', function (content) {
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
        case 'hide90':
          if (content.value) {
            model.hide90();
          } else {
            model.showAll();
          }
          break;
      }
    });

    function getOutputs() {
      return {
        year: model.getFractionalYear(),
        temperatureChange: model.getTemperature(),
        co2Concentration: model.getCO2Count()
      };
    }

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
