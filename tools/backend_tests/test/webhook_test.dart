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

  test('submitted report is auto-scored without any direct invoke', () async {
    final id = await cit.client.rpc('submit_report', params: {
      'p_lat': env.randomTestLat(),
      'p_lng': 100.9001, // fake formula -> federal_route
      'p_source': 'voice',
      'p_speed_kmh': 85,
    }) as String;

    Map<String, dynamic>? row;
    for (var i = 0; i < 30; i++) {
      row = await env.admin.from('reports').select().eq('id', id).single();
      if (row['risk_score'] != null) break;
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    expect(row!['risk_score'], 85, reason: 'webhook should have scored it');
    expect(row['assigned'], true); // 85 >= 80
    expect(row['road_type'], 'federal_route');
  });

  test('service-role insert with risk_score set does NOT retrigger', () async {
    final inserted = await env.admin
        .from('reports')
        .insert({
          'reporter': cit.id,
          'lat': env.randomTestLat(),
          'lng': 100.9,
          'source': 'photo',
          'risk_score': 42,
          'rationale': 'pre-scored seed row',
        })
        .select('id, analyzed_at')
        .single();
    await Future<void>.delayed(const Duration(seconds: 5));
    final row = await env.admin
        .from('reports')
        .select()
        .eq('id', inserted['id'])
        .single();
    expect(row['risk_score'], 42);
    expect(row['analyzed_at'], isNull); // analyze never ran
  });
}
