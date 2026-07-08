import 'dart:convert';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

import '../models/pothole.dart';

@JS('initMap3D')
external void _initMap3D(JSString containerId);

@JS('updatePins')
external void _updatePins(JSString pinsJson);

@JS('setPinTapHandler')
external void _setPinTapHandler(JSFunction handler);

const _viewType = 'map-container';
const _containerId = 'map-container-el';
bool _viewFactoryRegistered = false;

// Free function, not a closure over widget state: the view factory can only
// be registered once per viewType, so it must not capture anything from a
// particular _JsMapWebState that could later be disposed. Same fixed
// container id every time -- see the class doc for the one-mount caveat
// this implies.
web.HTMLDivElement _createContainer(int viewId) {
  final element = web.document.createElement('div') as web.HTMLDivElement;
  element.id = _containerId;
  _initMap3D(_containerId.toJS);
  return element;
}

/// Mounts the 3D map (bootstrap + Map3DElement/marker logic lives as global
/// JS in web/index.html, see that file's comments) via HtmlElementView,
/// bridging pin data / tap events through dart:js_interop -- native
/// platform feature, no map package, mirroring the WebView bridge used on
/// Android (see mobile/lib/map/js_map_webview.dart in the other Flutter
/// project).
///
/// ponytail: the underlying map/container is created once per app process
/// (view factories can't be re-registered), so this assumes the dashboard
/// mounts once per session. Signing out and back in still works (the pin
/// tap handler is re-bound fresh each mount) but a second *concurrent*
/// JsMapWeb instance would collide on the same container id -- add a
/// per-instance id if a screen ever needs more than one map at once.
class JsMapWeb extends StatefulWidget {
  const JsMapWeb({super.key, required this.pins, required this.onPinTap});

  final List<Pothole> pins;
  final void Function(String potholeId) onPinTap;

  @override
  State<JsMapWeb> createState() => _JsMapWebState();
}

class _JsMapWebState extends State<JsMapWeb> {
  @override
  void initState() {
    super.initState();
    if (!_viewFactoryRegistered) {
      ui_web.platformViewRegistry.registerViewFactory(_viewType, _createContainer);
      _viewFactoryRegistered = true;
    }
    _bindPinTapHandler();
    _pushPins();
  }

  @override
  void didUpdateWidget(covariant JsMapWeb oldWidget) {
    super.didUpdateWidget(oldWidget);
    _bindPinTapHandler();
    if (widget.pins != oldWidget.pins) _pushPins();
  }

  void _bindPinTapHandler() {
    _setPinTapHandler(((JSString id) => widget.onPinTap(id.toDart)).toJS);
  }

  void _pushPins() {
    final payload = jsonEncode(
      widget.pins.map((p) => {'id': p.id, 'lat': p.lat, 'lng': p.lng}).toList(),
    );
    _updatePins(payload.toJS);
  }

  @override
  Widget build(BuildContext context) => const HtmlElementView(viewType: _viewType);
}
