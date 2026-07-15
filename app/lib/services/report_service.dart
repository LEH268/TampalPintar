import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/draft.dart';
import '../models/report.dart';

class DuplicateReportException implements Exception {
  @override
  String toString() => 'Laporan aktif sudah wujud dalam lingkungan 10 meter.';
}

class ReportService {
  ReportService(this._client);
  final SupabaseClient _client;

  Future<List<PinSummary>> fetchActivePins() async {
    final rows = await _client
        .from('reports')
        .select('id, lat, lng')
        .eq('status', 'active');
    return [
      for (final r in rows)
        PinSummary(r['id'], (r['lat'] as num).toDouble(),
            (r['lng'] as num).toDouble())
    ];
  }

  Future<ReportDetails> fetchDetails(String id) async {
    final row = await _client.from('reports').select().eq('id', id).single();
    return ReportDetails(row);
  }

  String publicUrl(String path) =>
      _client.storage.from('media').getPublicUrl(path);

  Future<String> _submit(Map<String, dynamic> params) async {
    try {
      return await _client.rpc('submit_report', params: params) as String;
    } on PostgrestException catch (e) {
      if (e.message.contains('duplicate_within_10m')) {
        throw DuplicateReportException();
      }
      rethrow;
    }
  }

  Future<String> submitDraft(Draft d) => _submit({
        'p_lat': d.lat,
        'p_lng': d.lng,
        'p_source': 'voice',
        'p_speed_kmh': d.speedKmh,
        'p_captured_at': d.capturedAt.toUtc().toIso8601String(),
        'p_media_paths': d.mediaPaths,
        'p_immediate_index': d.immediateIndex,
        'p_vehicle_type': d.vehicleType,
        'p_lane_position': d.lanePosition,
        'p_impact_severity': d.impactSeverity,
      });

  Future<String> submitPhotoReport(
      {required List<int> jpegBytes,
      required double lat,
      required double lng}) async {
    final uid = _client.auth.currentUser!.id;
    final id = const Uuid().v4();
    final path = 'reports/$uid/$id/f0.jpg';
    await _client.storage.from('media').uploadBinary(
        path, Uint8List.fromList(jpegBytes),
        fileOptions: const FileOptions(contentType: 'image/jpeg'));
    return _submit({
      'p_lat': lat,
      'p_lng': lng,
      'p_source': 'photo',
      'p_media_paths': [path],
      'p_immediate_index': 0,
    });
  }
}
