import 'package:supabase/supabase.dart';
import 'package:test/test.dart';
import '../lib/helpers.dart';

void main() {
  late TestEnv env;
  late TestActor cit;
  setUpAll(() async {
    env = await TestEnv.load();
    cit = await env.createCitizen();
  });
  tearDownAll(() async => env.dispose());

  Future<String> submit(double lat, double lng,
          {Map<String, dynamic> extra = const {}}) async =>
      await cit.client.rpc('submit_report', params: {
        'p_lat': lat,
        'p_lng': lng,
        'p_source': 'voice',
        ...extra,
      }) as String;

  test('accepts, then rejects a second report inside 10 m', () async {
    final lat = env.randomTestLat();
    const lng = 100.90;
    final id = await submit(lat, lng);
    expect(id, isNotEmpty);

    Object? err;
    try {
      await submit(lat, lng + offsetLngMeters(lat, 5)); // 5 m away
    } catch (e) {
      err = e;
    }
    expect(err, isA<PostgrestException>());
    expect((err as PostgrestException).message, contains('duplicate_within_10m'));
  });

  test('boundary: 9 m rejected, 11 m accepted', () async {
    final lat = env.randomTestLat();
    const lng = 100.91;
    await submit(lat, lng);
    Object? err;
    try {
      await submit(lat, lng + offsetLngMeters(lat, 9));
    } catch (e) {
      err = e;
    }
    expect(err, isNotNull);
    final ok = await submit(lat, lng + offsetLngMeters(lat, 11));
    expect(ok, isNotEmpty);
  });

  test('fixed reports do not block re-reporting', () async {
    final lat = env.randomTestLat();
    const lng = 100.92;
    final id = await submit(lat, lng);
    await env.admin.from('reports').update({
      'status': 'fixed',
      'fixed_at': DateTime.now().toUtc().toIso8601String()
    }).eq('id', id);
    final again = await submit(lat, lng); // same spot, old one fixed
    expect(again, isNotEmpty);
  });

  test('answers + media round-trip; absent stays NULL', () async {
    final lat = env.randomTestLat();
    final id = await submit(lat, 100.93, extra: {
      'p_speed_kmh': 72.5,
      'p_captured_at': DateTime.utc(2026, 7, 9, 1, 2, 3).toIso8601String(),
      'p_media_paths': ['reports/${cit.id}/d1/f0.jpg', 'reports/${cit.id}/d1/f1.jpg'],
      'p_immediate_index': 1,
      'p_vehicle_type': 'motorcycle',
      'p_lane_position': 'single_lane',
      'p_impact_severity': 'swerve',
    });
    final row = await env.admin.from('reports').select().eq('id', id).single();
    expect(row['speed_kmh'], 72.5);
    expect(row['media_paths'], hasLength(2));
    expect(row['immediate_index'], 1);
    expect(row['vehicle_type'], 'motorcycle');
    expect(row['lane_position'], 'single_lane');
    expect(row['impact_severity'], 'swerve');
    expect(row['source'], 'voice');
    expect(row['status'], 'active');

    final bare = await submit(env.randomTestLat(), 100.94);
    final bareRow =
        await env.admin.from('reports').select().eq('id', bare).single();
    expect(bareRow['vehicle_type'], isNull);
    expect(bareRow['lane_position'], isNull);
    expect(bareRow['impact_severity'], isNull);
  });

  test('invalid enum value is rejected', () async {
    Object? err;
    try {
      await cit.client.rpc('submit_report', params: {
        'p_lat': env.randomTestLat(),
        'p_lng': 100.95,
        'p_source': 'voice',
        'p_vehicle_type': 'tank',
      });
    } catch (e) {
      err = e;
    }
    expect(err, isNotNull);
  });

  test('government role cannot submit', () async {
    final role = await env.createRole('highway');
    Object? err;
    try {
      await role.client.rpc('submit_report', params: {
        'p_lat': env.randomTestLat(),
        'p_lng': 100.96,
        'p_source': 'photo'
      });
    } catch (e) {
      err = e;
    }
    expect(err, isNotNull);
  });
}
