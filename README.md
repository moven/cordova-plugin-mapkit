MapKit plugin for iOS and Android
=================================

Uses *Apple Maps* on iOS and *Google Maps v2* on Android

Currently only works/tested on Android. iOS is currently outdated and DOES NOT WORK.

You can install this plugin with [plugman](https://npmjs.org/package/plugman)

Sample code
-----------

    var app = {
        showMap: function() {
            var pins = [[49.28115, -123.10450], [49.27503, -123.12138], [49.28286, -123.11891]];
            var error = function() {
              console.log('error');
            };
            var success = function() {
              mapKit.addMapPins(pins, function() { 
                                          console.log('adMapPins success');  
                                      },
                                      function() { console.log('error'); });
            };
            mapKit.showMap(success, error);
        },
        hideMap: function() {
            var success = function() {
              console.log('Map hidden');
            };
            var error = function() {
              console.log('error');
            };
            mapKit.hideMap(success, error);
        },
        clearMapPins: function() {
            var success = function() {
              console.log('Map Pins cleared!');
            };
            var error = function() {
              console.log('error');
            };
            mapKit.clearMapPins(success, error);
        }
    }

Configuration
-------------

Edit the options in MapKit.js to suit your needs

    this.options = {
      height: 460, // height of the map (width is always full size for now)
      diameter: 1000,   // unused for now
      atBottom: true,   // bottom or top of the webview
      lat: 49.281468,   // initial camera position latitude
      lon: -123.104446  // initial camera position latitude
    };

Missing features
----------------

Info bubbles: really easy to add simple bubbles, more complicated to add customized info bubbles
