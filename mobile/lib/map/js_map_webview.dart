import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/pothole.dart';
import 'map_html.dart';

class JsMapWebView extends StatefulWidget {
  const JsMapWebView({super.key, required this.apiKey, required this.pins, required this.onPinTap});

  final String apiKey;
  final List<Pothole> pins;
  final void Function(String potholeId) onPinTap;

  @override
  State<JsMapWebView> createState() => _JsMapWebViewState();
}

class _JsMapWebViewState extends State<JsMapWebView> {
  // Use a nullable controller to guarantee it is NEVER initialized on Web
  WebViewController? _controller;
  bool _pageLoaded = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    
    // Completely bypass WebView initialization if running on Chrome
    if (kIsWeb) {
      return;
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (message) => widget.onPinTap(message.message),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _pageLoaded = true);
              _pushPins();
            }
          },
          onWebResourceError: (error) {
            if (mounted) {
              setState(() => _loadError = error.description);
            }
          },
        ),
      )
      ..loadHtmlString(buildMapHtml(widget.apiKey));
  }

  @override
  void didUpdateWidget(covariant JsMapWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!kIsWeb && _pageLoaded && widget.pins != oldWidget.pins) {
      _pushPins();
    }
  }

  void _pushPins() {
    if (kIsWeb || _controller == null) return;
    final payload = jsonEncode(
      widget.pins.map((p) => {'id': p.id, 'lat': p.lat, 'lng': p.lng}).toList(),
    );
    _controller!.runJavaScript('updatePins($payload)');
  }

  void _retry() {
    if (kIsWeb || _controller == null) return;
    setState(() {
      _loadError = null;
      _pageLoaded = false;
    });
    _controller!.loadHtmlString(buildMapHtml(widget.apiKey));
  }

  @override
  Widget build(BuildContext context) {
    // Graceful fallback UI when running the Mobile app on Chrome
    if (kIsWeb) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.public_off_rounded, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Map WebView is for Android/iOS only.',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'You are running the "mobile" project on Chrome. To test map features, run the "web" project instead.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        if (_controller != null) WebViewWidget(controller: _controller!),
        if (!_pageLoaded && _loadError == null)
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(strokeWidth: 2.5),
                  SizedBox(height: 12),
                  Text('Loading map...', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ),
        if (_loadError != null)
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_off_rounded, size: 40, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text(
                      'Failed to load the map',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _loadError!,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}