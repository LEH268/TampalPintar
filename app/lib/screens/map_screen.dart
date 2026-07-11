import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../config.dart';
import '../driving/driving_controller.dart';
import '../services/dashcam_service.dart';
import '../services/position_resolver.dart';
import '../services/profile_service.dart';
import '../services/report_service.dart';
import 'pin_details_sheet.dart';

/// How long to wait for the map page's "ready" (or "error") bridge message
/// before treating the load as failed. The bootstrap script returns HTTP 200
/// even with a revoked key, so "no error received" is not proof of success --
/// a timeout is the only backstop.
const _kMapLoadTimeout = Duration(seconds: 10);

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final WebViewController _web;
  final _reports = ReportService(Supabase.instance.client);
  final _dashcam = DashcamService(Supabase.instance.client);
  final _profile = ProfileService(Supabase.instance.client);
  Timer? _pinTimer;
  Timer? _dashcamTimer;
  Timer? _loadTimeoutTimer;
  bool _mapReady = false;
  bool _mapFailed = false;
  String? _mapErrorMessage;
  bool? _dashcamConnected; // null = no dashcam configured
  String? _dashcamId;
  bool _driving = false;

  @override
  void initState() {
    super.initState();
    DrivingController.isRunning().then((v) {
      if (mounted) setState(() => _driving = v);
    });
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('PinTap', onMessageReceived: (msg) {
        final m = jsonDecode(msg.message) as Map<String, dynamic>;
        if (m['type'] == 'ready') {
          _loadTimeoutTimer?.cancel();
          _mapReady = true;
          if (mounted) setState(() => _mapFailed = false);
          _pushPins();
        } else if (m['type'] == 'pinTap') {
          if (!mounted) return;
          showPinDetails(context, m['id'] as String);
        } else if (m['type'] == 'error') {
          _loadTimeoutTimer?.cancel();
          if (mounted) {
            setState(() {
              _mapFailed = true;
              _mapErrorMessage = m['message'] as String?;
            });
          }
        }
      })
      ..loadFlutterAsset('assets/map/map.html');
    _startLoadTimeout();
    _pinTimer =
        Timer.periodic(kPinRefetchInterval, (_) => _pushPins());
    _initDashcam();
    _pushPins();
  }

  void _startLoadTimeout() {
    _loadTimeoutTimer?.cancel();
    _loadTimeoutTimer = Timer(_kMapLoadTimeout, () {
      if (!_mapReady && mounted) {
        setState(() {
          _mapFailed = true;
          _mapErrorMessage = 'Map took too long to load.';
        });
      }
    });
  }

  void _retryMap() {
    if (!mounted) return;
    setState(() {
      _mapFailed = false;
      _mapErrorMessage = null;
      _mapReady = false;
    });
    _web.loadFlutterAsset('assets/map/map.html');
    _startLoadTimeout();
  }

  Future<void> _initDashcam() async {
    Map<String, dynamic> p;
    try {
      p = await _profile.fetchMine();
    } catch (_) {
      return;
    }
    if (!mounted) return;
    _dashcamId = p['dashcam_id'] as String?;
    if (_dashcamId == null) return;
    Future<void> poll() async {
      try {
        final ok = await _dashcam.isConnected(_dashcamId!);
        if (mounted) setState(() => _dashcamConnected = ok);
      } catch (_) {
        if (mounted) setState(() => _dashcamConnected = false);
      }
    }

    await poll();
    _dashcamTimer = Timer.periodic(kDashcamPollInterval, (_) => poll());
  }

  Future<void> _pushPins() async {
    if (!_mapReady) return;
    final pins = await _reports.fetchActivePins();
    if (!mounted) return;
    final payload = jsonEncode([for (final p in pins) p.toJson()]);
    await _web.runJavaScript('setPins(${jsonEncode(payload)})');
  }

  Future<void> _reportByPhoto() async {
    final shot =
        await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 80);
    if (shot == null) return;
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content:
                  Text('Location permission is required to report a pothole.')));
        }
        return;
      }
      final pos = await PositionResolver().resolve();
      if (pos == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Could not get a GPS fix. Please try again.')));
        }
        return;
      }
      await _reports.submitPhotoReport(
          jpegBytes: await shot.readAsBytes(),
          lat: pos.latitude,
          lng: pos.longitude);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pothole reported — pin added!')));
      }
      await _pushPins();
    } on DuplicateReportException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Already in the system: an active report exists within 10 m.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not report the pothole. Please try again.')));
      }
    }
  }

  Future<void> _toggleDriving() async {
    if (_driving) {
      await DrivingController.stop();
      if (mounted) setState(() => _driving = false);
      return;
    }
    if (!await DrivingController.requestPermissions()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Microphone + location permissions are required.')));
      }
      return;
    }
    await DrivingController.start();
    if (mounted) setState(() => _driving = true);
  }

  @override
  void dispose() {
    _pinTimer?.cancel();
    _dashcamTimer?.cancel();
    _loadTimeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          WebViewWidget(controller: _web),
          if (_mapFailed)
            Positioned.fill(
              child: Container(
                color: Colors.black87,
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.redAccent, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        _mapErrorMessage ?? 'Map failed to load.',
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                          onPressed: _retryMap, child: const Text('Retry')),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            top: 8,
            right: 8,
            child: Chip(
              avatar: Icon(Icons.videocam,
                  size: 18,
                  color: _dashcamConnected == true ? Colors.green : Colors.red),
              label: Text(_dashcamId == null
                  ? 'No dashcam'
                  : _dashcamConnected == true
                      ? 'Dashcam Connected'
                      : 'Dashcam Not Connected'),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'driving',
                  backgroundColor: _driving ? Colors.red : null,
                  onPressed: _toggleDriving,
                  icon: Icon(_driving ? Icons.stop : Icons.drive_eta),
                  label: Text(_driving ? 'Stop Driving' : 'Start Driving'),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'photo',
                  onPressed: _reportByPhoto,
                  child: const Icon(Icons.camera_alt),
                ),
              ],
            ),
          ),
        ],
      );
}
