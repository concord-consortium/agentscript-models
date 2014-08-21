exports.config =
  files:
    javascripts:
      joinTo:
        'javascripts/app.js': /^app/
        'javascripts/vendor.js': /^(?!app)/
      order:
        after: ['bower_components/jquery.ui.touch-punch.min/index.js']

    stylesheets:
      joinTo: 'stylesheets/app.css'
