/// Bootstrap HTML/JS for the shared 3D Selangor map, loaded into a WebView
/// on Android (see js_map_webview.dart). The Maps JS API loader snippet is
/// reused verbatim from docs/TampalPintar_Guide.md §4; the marker/click
/// wiring below follows Google's documented Map3DElement /
/// Marker3DInteractiveElement JS API (declarative gmp-marker-3d attributes
/// aren't used -- the interactive/clickable marker variant is
/// JS-constructed only, per Google's own marker codelab).
String buildMapHtml(String apiKey) => '''
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="initial-scale=1.0, width=device-width" />
    <style>html,body,#map-container,gmp-map-3d{height:100%;width:100%;margin:0;padding:0;}</style>
  </head>
  <body>
    <div id="map-container"></div>
    <script>
      (g => {
        var h,a,k,p="The Google Maps JavaScript API",c="google",l="importLibrary",q="__ib__",m=document,b=window;
        b=b[c]||(b[c]={});var d=b.maps||(b.maps={}),r=new Set,e=new URLSearchParams,u=()=>
          h||(h=new Promise(async (f,n)=>{await (a=m.createElement("script"));
          e.set("libraries",[...r]+"");for(k in g)e.set(k.replace(/[A-Z]/g,t=>"_"+t[0].toLowerCase()),g[k]);
          e.set("callback",c+".maps."+q);a.src=`https://maps.\${c}apis.com/maps/api/js?`+e;d[q]=f;
          a.onerror=()=>h=n(Error(p+" could not load."));a.nonce=m.querySelector("script[nonce]")?.nonce||"";
          m.head.append(a)}));d[l]?console.warn(p+" only loads once. Ignoring:",g):d[l]=(f,...n)=>r.add(f)&&u().then(()=>d[l](f,...n));
      })({key: "$apiKey", v: "weekly"});

      let map3d;
      let Marker3DInteractiveElement;
      const markers = {};
      const pendingPins = [];

      async function initMap() {
        const lib = await google.maps.importLibrary("maps3d");
        Marker3DInteractiveElement = lib.Marker3DInteractiveElement;
        map3d = new lib.Map3DElement({
          center: { lat: 3.1390, lng: 101.6869, altitude: 0 },
          range: 40000,
          tilt: 60,
          mode: 'HYBRID',
        });
        document.getElementById('map-container').append(map3d);
        if (pendingPins.length) updatePins(pendingPins.splice(0));
      }
      initMap();

      function updatePins(pins) {
        if (!map3d) { pendingPins.length = 0; pendingPins.push(...pins); return; }
        const seen = new Set();
        for (const p of pins) {
          seen.add(p.id);
          if (!markers[p.id]) {
            const marker = new Marker3DInteractiveElement({
              position: { lat: p.lat, lng: p.lng, altitude: 0 },
            });
            marker.addEventListener('gmp-click', () => {
              FlutterBridge.postMessage(p.id);
            });
            map3d.append(marker);
            markers[p.id] = marker;
          }
        }
        for (const id of Object.keys(markers)) {
          if (!seen.has(id)) {
            markers[id].remove();
            delete markers[id];
          }
        }
      }
    </script>
  </body>
</html>
''';
