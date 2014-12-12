/*jshint indent: false, quotmark: false */
/*global window, iframePhone */

(function() {
  "use strict";

  window.setupLabCommunication = function(model) {
    var phone = iframePhone.getIFrameEndpoint();

    phone.addListener('play', function() {
      model.start();
      // Notify iframe model that we received 'play' message and reacted appropriately.
      phone.post('play.iframe-model');
    });
    phone.post('registerScriptingAPIFunc', 'play');

    phone.addListener('stop', function() {
      model.stop();
      // Notify iframe model that we received 'stop' message and reacted appropriately.
      phone.post('stop.iframe-model');
    });
    phone.post('registerScriptingAPIFunc', 'stop');

    phone.addListener('addCO2', function() {
      model.addCO2();
    });
    phone.post('registerScriptingAPIFunc', 'addCO2');

    phone.addListener('removeCO2', function() {
      model.subtractCO2();
    });
    phone.post('registerScriptingAPIFunc', 'removeCO2');

    phone.addListener('addCloud', function() {
      model.addCloud();
    });
    phone.post('registerScriptingAPIFunc', 'addCloud');

    phone.addListener('removeCloud', function() {
      model.subtractCloud();
    });
    phone.post('registerScriptingAPIFunc', 'removeCloud');

    phone.addListener('erupt', function() {
      model.erupt();
    });
    phone.post('registerScriptingAPIFunc', 'erupt');

    phone.addListener('set', function (content) {
      if (content.name === 'albedo') {
        model.setAlbedo(content.value);
      } else if (content.name === 'sunBrightness') {
        model.setSunBrightness(content.value);
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

