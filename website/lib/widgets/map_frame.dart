import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class MapFrame extends StatefulWidget {
  const MapFrame({super.key, required this.onPinTap});
  final void Function(String reportId) onPinTap;
  @override
  State<MapFrame> createState() => MapFrameState();
}

class MapFrameState extends State<MapFrame> {
  static bool _factoryRegistered = false;
  static web.HTMLIFrameElement? _iframe;
  bool _ready = false;
  bool _failed = false;
  String? _errorMsg;
  List<Map<String, dynamic>> _pending = [];
  JSFunction? _listener;
  Timer? _readyTimeout;

  @override
  void initState() {
    super.initState();
    if (!_factoryRegistered) {
      ui_web.platformViewRegistry.registerViewFactory('gov-map-frame',
          (int viewId) {
        final el = web.HTMLIFrameElement()
          ..src = 'map.html'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%';
        _iframe = el;
        return el;
      });
      _factoryRegistered = true;
    }
    _listener = _onMessage.toJS;
    web.window.addEventListener('message', _listener);
    _startReadyTimeout();
  }

  void _startReadyTimeout() {
    _readyTimeout?.cancel();
    _readyTimeout = Timer(const Duration(seconds: 10), () {
      if (!_ready && mounted) {
        setState(() {
          _failed = true;
          _errorMsg = 'Map took too long to load.';
        });
      }
    });
  }

  void _onMessage(web.MessageEvent e) {
    final data = e.data;
    if (data == null || !data.isA<JSString>()) return; // Flutter posts objects too
    try {
      final m = jsonDecode((data as JSString).toDart) as Map<String, dynamic>;
      if (m['type'] == 'ready') {
        _readyTimeout?.cancel();
        _ready = true;
        if (_failed && mounted) setState(() => _failed = false);
        if (_pending.isNotEmpty) setPins(_pending);
      } else if (m['type'] == 'pinTap') {
        widget.onPinTap(m['id'] as String);
      } else if (m['type'] == 'error') {
        _readyTimeout?.cancel();
        if (mounted) {
          setState(() {
            _failed = true;
            _errorMsg = 'Map failed to load: ${m['message'] ?? 'unknown error'}';
          });
        }
      }
    } catch (_) {/* not one of ours */}
  }

  void setPins(List<Map<String, dynamic>> pins) {
    _pending = pins;
    final win = _iframe?.contentWindow;
    if (!_ready || win == null) return;
    win.postMessage(
        jsonEncode({'type': 'setPins', 'pins': pins}).toJS, '*'.toJS);
  }

  void _retry() {
    _ready = false;
    setState(() {
      _failed = false;
      _errorMsg = null;
    });
    _iframe?.src = 'map.html'; // reload the map page
    _startReadyTimeout();
  }

  @override
  void dispose() {
    _readyTimeout?.cancel();
    if (_listener != null) {
      web.window.removeEventListener('message', _listener);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          const Positioned.fill(
            child: HtmlElementView(viewType: 'gov-map-frame'),
          ),
          if (_failed)
            Positioned.fill(
              child: ColoredBox(
                color: const Color(0xFF0B0F14),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.map_outlined,
                          size: 48, color: Colors.white70),
                      const SizedBox(height: 12),
                      Text(_errorMsg ?? 'Map failed to load.',
                          style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 12),
                      FilledButton(
                          onPressed: _retry, child: const Text('Retry')),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
}
