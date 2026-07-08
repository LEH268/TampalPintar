import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/pothole.dart';
import 'map_html.dart';

/// Renders the shared 3D map inside an Android WebView (PRD §4's
/// JsMapWebView pattern) and keeps its pins in sync with [pins] via a JS
/// bridge: Dart -> JS through `updatePins(...)`, JS -> Dart through the
/// `FlutterBridge` channel on marker tap.
class JsMapWebView extends StatefulWidget {
  const JsMapWebView({super.key, required this.apiKey, required this.pins, required this.onPinTap});

  final String apiKey;
  final List<Pothole> pins;
  final void Function(String potholeId) onPinTap;

  @override
  State<JsMapWebView> createState() => _JsMapWebViewState();
}

class _JsMapWebViewState extends State<JsMapWebView> {
  late final WebViewController _controller;
  bool _pageLoaded = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (message) => widget.onPinTap(message.message),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            _pageLoaded = true;
            _pushPins();
          },
        ),
      )
      ..loadHtmlString(buildMapHtml(widget.apiKey));
  }

  @override
  void didUpdateWidget(covariant JsMapWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_pageLoaded && widget.pins != oldWidget.pins) _pushPins();
  }

  void _pushPins() {
    final payload = jsonEncode(
      widget.pins.map((p) => {'id': p.id, 'lat': p.lat, 'lng': p.lng}).toList(),
    );
    _controller.runJavaScript('updatePins($payload)');
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _controller);
}
