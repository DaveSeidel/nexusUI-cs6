nexusUI-cs6
===========

Extension to the nexusUI JavaScript library to support the Csound6 app for Android.

Requires the nexusUI and jQuery JavaScript libraries (see <http://www.nexusosc.com/nexusTutorials/>).

See SrutiDroneAndroid-nexusUI.csd for an example (still under construction). Upload the CSD file, the file nexusUI-cs6.js and the nexusUI and jQuery libraries all to the same directory on your Android device, and then open SrutiDroneAndroid-nexusUI.csd in the Csound6 app.

See nexusui-test.html for an example that runs in the browser for testing purposes (without Csound).

## Usage

1. Load the jQuery, nexusUI, and nexusUI-cs6 libraries.
2. In your implementation of the nexusUI startup function (`nx.onload()`), initialize the cs6 object.
3. Give each nexusUI a unique ID, and use those IDs in your Csound code as the names of the corresponding channels.

For example, the button widget that you identify as "button1"

    <canvas nx="button" id="button1"></canvas>

corresponds to a Csound channel called "button1"

    kbut1 = chnget("button1")

### Setup & initialization

    <head>
      <script src="jquery-2.1.1.js"></script>
      <script src="nexusUI.js"></script>
      <script src="nexusUI-cs6.js"></script>
      <script>

        nx.onload = function() {
          cs6.init();
        };

      </script>
    </head>

### Markup

    <body>
      <canvas nx="slider" id="slider1"></canvas>
    </body>

### Csound

    kamp chnget "slider1"
    ; or
    kamp = chnget("slider")

## Reference

Supported NexusUI objects, and what they emit:


* toggle: 1 (press) or 0 (release)
* button: 1 (fires once on press)
* dial: float 0-1
* slider: float 0-1
* number: float (positive/negative)
* select: index of selection (0-based)

For definitive documentation on nexusUI, see <http://www.nexusosc.com/api/>.