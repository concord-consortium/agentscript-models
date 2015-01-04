# Shutterbug.js

## Overview ##

Shutterbug has two parts: a browser JavaScript library for taking html snapshots, and a server side utility for turning those html snapshots into images. This repository consists of JavaScript library.

## Requirements & Dependencies

shutterbug.js requires [JQuery](http://jquery.com/) and expects JQuery to be found via window.jQuery.

## Basic usage

Include the following javascript in your pages:

     <script src='shutterbug.js' type='text/javascript'></script>

Elsewhere in your javascript, something like this:

    Shutterbug.snapshot({
      selector: '#sourceSelector',
      dstSelector: '#destinationSelector', // optional
      done: callbackFn, // optional
      fail: failCallbackFn, // optional
      always: alwaysCallbackFn, // optional
      server: '//your.domain.com/shutterbug', // optional, default: "//snapshot.concord.org/shutterbug"
      format: 'jpeg', // optional, default: 'png'
      quality: 0.85 // optional, default: 1
    });

This will replace the contents of `$("#destinationSelector")` with an image tag which will magically spring into existance. `callbackFn` is an optional callback function which will be invoked with the image source. You can use either of them. Note that all the options are passed using simple object literal.

There are also shortcuts available:

    Shutterbug.snapshot('#sourceSelector', otherOptions);
    Shutterbug.snapshot('#sourceSelector', callbackFn, otherOptions);
    Shutterbug.snapshot('#sourceSelector', '#destinationSelector', otherOptions);

## Iframe'able content

By itself `shutterbug.js` is useful for authors of iframe'able content. With `shutterbug.js` on the iframe'd page, the parent window can request an html snapshot even if the iframe'd page is on a different domain. To enable this functionality you need to add the following lines to your iframe'able page:

    <script src="shutterbug.js"></script>
    <script>Shutterbug.enable('body');</script>

## Advanced usage

### IFrame support

If the element being snapshot'd is an iframe then the iframe needs to handle a postMessage API.
Shutterbug will run something like the following JS to get the html of the iframe

    iframe.contentWindow.postMessage(JSON.stringify({
      type: 'htmlFragRequest',
      id: id
    }), "*");

It is passing a JSON message that specifies the 'type' of message and passes an id so the caller can match up the response.

The iframe should respond by posting back to the source window a message like:

    message.source.postMessage(JSON.stringfy({
      type:  'htmlFragResponse',
      value: {
        content: 'htmlContent'
        css: '<div><link rel='stylesheet'..><style>...</style></div>',
        width: width,
        height: height,
        base_url: 'url that resource urls in content and css are relative to'
        },
      id:    id  // id sent in in the 'htmlFragRequest'
    }), message.origin);

The `shutterbug.js` script actually adds a handler for this postMessage API when the `Shutterbug.enable` is called.
So if shutterbug is included in the iframe html as described in the Usage section above, then a parent page can snapshot the iframe.

You could also reimplement this API in the html of the iframe if you'd like. However the shutterbug implementation includes some useful things like finding and including all the css on the page, and 'serializing' canvas elements into images.

### Shutterbug JQuery custom events ###

Shutterbug emits a jQuery custom event called `shutterbug-saycheese` just prior to copying styles, elements, and canvas contents to the document fragment. This allows applications to do any preparation required before they are ready to be snapshotted.

In your application, you can register your event-handler like this:

      $(window).on('shutterbug-saycheese', function() {
        api.renderCanvas();
      });

After all elements are copied, emits a `shutterbug-asyouwere` event.

## Development

This library is built with [Brunch](http://brunch.io).

* Install (if you don't have them):
    * [Node.js](http://nodejs.org): `brew install node` on OS X
    * [Brunch](http://brunch.io): `npm install -g brunch`
    * [Bower](http://bower.io): `npm install -g bower`
    * Brunch plugins and Bower dependencies: `npm install & bower install`.
* Run:
    * `brunch watch --server` — watches the project with continuous rebuild. This will also launch HTTP server with [pushState](https://developer.mozilla.org/en-US/docs/Web/Guide/API/DOM/Manipulating_the_browser_history).
    * `brunch build -e dist` — builds dist files
* Learn:
    * `public/` dir is fully auto-generated and served by HTTP server.  Write your code in `app/` dir.
    * Place static files you want to be copied from `app/assets/` to `public/`.
    * [Brunch site](http://brunch.io)

* Demos:
    * Useful examples are available in `app/assets/demo`.
    * They use default Shutterbug server which is specified in `app/scripts/default-server.js`. When you develop server-side features, you might want to overwrite its value to local server, so all the examples will automatically use it.

## Changes ##

*  December 15, 2014 – v 0.5.4
    *  Basic snapshot method is used when S3 direct upload fails.

*  December 7, 2014 – v 0.5.3
    *  Bug fixes.

*  December 4, 2014 – v 0.5.0
    *  The first version after separation from the [server-side tool](https://github.com/concord-consortium/shutterbug).

## License ##

* [Simplified BSD](http://www.opensource.org/licenses/BSD-2-Clause),
* [MIT](http://www.opensource.org/licenses/MIT), or
* [Apache 2.0](http://www.opensource.org/licenses/Apache-2.0).

See [LICENSE.md](LICENSE.md) for more information.
