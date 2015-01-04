var $ = jQuery;

module.exports = {
  cloneDomItem: function($elem, elemTag) {
    var $returnElm = $(elemTag);
    $returnElm.addClass($elem.attr('class'));
    $returnElm.attr('style', $elem.attr('style'));
    $returnElm.css('background', $elem.css('background'));
    $returnElm.attr('width', $elem.width());
    $returnElm.attr('height', $elem.height());
    return $returnElm;
  },

  generateFullHtmlFromFragment: function(fragment) {
    return "<!DOCTYPE html>" +
      "<html>" +
        "<head>" +
          "<base href='" + fragment.base_url + "'>" +
          "<meta content='text/html;charset=utf-8' http-equiv='Content-Type'>" +
          "<title>content from " + fragment.base_url + "</title>" +
          fragment.css +
        "</head>" +
        "<body>" +
          fragment.content +
        "</body>" +
      "</html>";
  },

  dataURLtoBlob: function(dataURL) {
    // Convert base64/URLEncoded data component to raw binary data held in a string.
    if (dataURL.split(',')[0].indexOf('base64') === -1) {
      throw new Error('expected base64 data');
    }
    var byteString = atob(dataURL.split(',')[1]);
    // Separate out the mime component.
    var mimeString = dataURL.split(',')[0].split(':')[1].split(';')[0];
    // Write the bytes of the string to a typed array.
    var ia = new Uint8Array(byteString.length);
    for (var i = 0; i < byteString.length; i++) {
      ia[i] = byteString.charCodeAt(i);
    }
    return new Blob([ia], {type: mimeString});
  }
};
