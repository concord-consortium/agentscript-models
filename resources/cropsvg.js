/*global phantom*/
/*jshint quotmark: false*/

'use strict';

var page = require('webpage').create();
var system = require('system');
var fs = require('fs');
var indir;

if (system.args.length === 1) {
    console.log('Usage: slimerjs cropsvg.js <folder>');
    phantom.exit();
}

indir = system.args[1];

page.open('about:blank', function (status) {
    if (status !== 'success') {
        console.error("Failed to load browser page!;");
        phantom.exit();
    }

    var filePaths = fs.list(indir);

    if (!filePaths) {
        console.error("Couldn't find any files in \"" + indir + "\".");
    }

    var svgFilePaths = filePaths.filter(function(path) { return path.match('\.svg$'); });

    if (svgFilePaths.length === 0) {
        console.error("Couldn't find any svg files to convert");
    }

    try {
        fs.removeTree(indir+'/out');
    } catch (e) {}

    try {
        fs.removeTree(indir+'/problems');
    } catch (e) {}

    fs.makeDirectory(indir+'/out');
    fs.makeDirectory(indir+'/problems');

    svgFilePaths.forEach(function(svgFilePath) {
        var originalSvgString = fs.read(indir + '/' + svgFilePath);
        var croppedSvgInfo = page.evaluate(cropSvg, originalSvgString);

        if (parseInt(croppedSvgInfo.width, 10) >= 1) {
            fs.write(indir+'/out/'+svgFilePath, croppedSvgInfo.string, 'w');
            console.log('cropped: ' + svgFilePath);
        } else {
            fs.write(indir+'/problems/'+svgFilePath, originalSvgString, 'w');
            fs.write(indir+'/problems/'+svgFilePath+'.bad.txt', croppedSvgInfo.string, 'w');
            console.error('failed to crop: ' + svgFilePath);
        }
    });

    phantom.exit();
});


page.onConsoleMessage = function(msg, lineNum, sourceId) {
    console.log(msg);
};


// This part runs in page context

// TODO: this *almost* works. (in fact It works for some svg files now.)
// If I run it in Chrome dev console it returns valid svg for 
// fracking_water.svg. But in PhantomJS it sets width and height to zero.
function cropSvg(svgString) {
    var svg, bbox, g, nodes;
    var xmlSerializer = new XMLSerializer();

    document.body.innerHTML = svgString;
    svg = document.querySelector('svg');

    bbox = svg.getBBox();
    g = document.createElementNS("http://www.w3.org/2000/svg", 'g');
    nodes = Array.prototype.slice.call(svg.childNodes, 0);
    nodes.forEach(function(node) {
        g.appendChild(node);
    });
    svg.appendChild(g);
    g.setAttribute('transform', 'translate(' + (-bbox.x) + ' ' + (-bbox.y) + ')');
    svg.setAttribute('width', bbox.width);
    svg.setAttribute('height', bbox.height);
    svg.removeAttribute('viewBox');
    return {
        width: svg.getAttribute('width'),
        string: xmlSerializer.serializeToString(svg)
    };
}
