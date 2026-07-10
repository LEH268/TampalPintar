import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../map/js_map_webview.dart';
import '../models/pothole.dart';
import '../supabase_config.dart';
import 'pothole_detail_sheet.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _supabase = Supabase.instance.client;
  List<Pothole> _potholes = [];
  RealtimeChannel? _channel;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadPotholes();
    _channel = _supabase
        .channel('potholes-changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'potholes',
          callback: (_) => _loadPotholes(),
        )
        .subscribe();
  }

  @override
  void dispose() {
    final channel = _channel;
    if (channel != null) _supabase.removeChannel(channel);
    super.dispose();
  }

  Future<void> _loadPotholes() async {
    final rows = await _supabase.from('potholes').select();
    if (!mounted) return;
    setState(() => _potholes = rows.map(Pothole.fromJson).toList());
  }

  // Fixed rows stay in _potholes (Realtime needs to still see them to
  // deliver the fix-transition event at all -- see migration 0009) but are
  // filtered out of what's actually drawn on the map.
  List<Pothole> get _activePins => _potholes.where((p) => p.status != 'fixed').toList();

  Pothole? _findPothole(String id) {
    for (final p in _potholes) {
      if (p.id == id) return p;
    }
    return null;
  }

  void _onPinTap(String id) {
    final pothole = _findPothole(id);
    if (pothole == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => PotholeDetailSheet(pothole: pothole),
    );
  }

  Future<void> _report() async {
    setState(() => _submitting = true);
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1600,
      );
      if (image == null) return;

      final position = await _getPosition();
      if (position == null) return;

      final bytes = await image.readAsBytes();
      await _supabase.functions.invoke(
        'report-pothole',
        body: {
          'photoBase64': base64Encode(bytes),
          'lat': position.latitude,
          'lng': position.longitude,
        },
      );
      await _loadPotholes();
      _showMessage('Report submitted! The new pin should appear on the map.', isError: false);
    } on FunctionException catch (e) {
      if (e.status == 409) {
        _showMessage('A recent report already exists nearby, so this spot was not submitted again.', isError: true);
      } else {
        _showMessage('Report failed (${e.status}). Please try again.', isError: true);
      }
    } catch (e) {
      _showMessage('Report failed. Please check your connection and try again.', isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<Position?> _getPosition() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      _showMessage('Location permission is required to report a pothole.');
      return null;
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  void _showMessage(String text, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepOrange.shade700,
        foregroundColor: Colors.white,
        title: const Text('TampalPintar', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(onPressed: () => _supabase.auth.signOut(), icon: const Icon(Icons.logout)),
        ],
      ),
      body: SafeArea(child: JsMapWebView(apiKey: mapsApiKey, pins: _activePins, onPinTap: _onPinTap)),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.deepOrange.shade700,
        foregroundColor: Colors.white,
        onPressed: _submitting ? null : _report,
        icon: _submitting
            ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.camera_alt),
        label: Text(_submitting ? 'Submitting...' : 'Report'),
      ),
    );
  }
}
