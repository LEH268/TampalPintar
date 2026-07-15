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
import '../theme.dart';
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
          _mapErrorMessage = 'Peta mengambil masa terlalu lama untuk dimuatkan.';
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
              content: Text(
                  'Kebenaran lokasi diperlukan untuk melaporkan lubang jalan.')));
        }
        return;
      }
      final pos = await PositionResolver().resolve();
      if (pos == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content:
                  Text('Kedudukan GPS tidak dapat diperoleh. Sila cuba lagi.')));
        }
        return;
      }
      await _reports.submitPhotoReport(
          jpegBytes: await shot.readAsBytes(),
          lat: pos.latitude,
          lng: pos.longitude);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Lubang jalan dilaporkan — pin ditambah!')));
      }
      await _pushPins();
    } on DuplicateReportException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Sudah ada dalam sistem: laporan aktif wujud dalam lingkungan 10 m.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Lubang jalan tidak dapat dilaporkan. Sila cuba lagi.')));
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
            content: Text('Kebenaran mikrofon + lokasi diperlukan.')));
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

  Widget _dashcamPill(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color dot;
    final String label;
    if (_dashcamId == null) {
      dot = scheme.onSurfaceVariant;
      label = 'Tiada dashcam';
    } else if (_dashcamConnected == true) {
      dot = successColor(context);
      label = 'Dashcam disambungkan';
    } else {
      dot = scheme.error;
      label = 'Dashcam luar talian';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.videocam_outlined,
              size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        WebViewWidget(controller: _web),
        if (_mapFailed)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.55),
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: scheme.errorContainer,
                          child: Icon(Icons.wifi_tethering_error_rounded,
                              color: scheme.onErrorContainer, size: 28),
                        ),
                        const SizedBox(height: 14),
                        Text('Peta tidak tersedia',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 6),
                        Text(
                          _mapErrorMessage ?? 'Peta gagal dimuatkan.',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                            onPressed: _retryMap,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Cuba Lagi')),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        Positioned(top: 12, right: 12, child: _dashcamPill(context)),
        Positioned(
          bottom: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FloatingActionButton.extended(
                heroTag: 'driving',
                backgroundColor: _driving ? scheme.error : null,
                foregroundColor: _driving ? scheme.onError : null,
                onPressed: _toggleDriving,
                icon: Icon(
                    _driving ? Icons.stop_rounded : Icons.drive_eta_rounded),
                label: Text(_driving ? 'Berhenti Memandu' : 'Mula Memandu'),
              ),
              const SizedBox(height: 12),
              FloatingActionButton(
                heroTag: 'photo',
                tooltip: 'Laporkan lubang jalan melalui foto',
                backgroundColor: scheme.secondaryContainer,
                foregroundColor: scheme.onSecondaryContainer,
                onPressed: _reportByPhoto,
                child: const Icon(Icons.camera_alt_outlined),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
