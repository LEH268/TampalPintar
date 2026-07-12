import 'dart:convert';
import 'package:http/http.dart' as http;
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

  Future<Map<String, dynamic>> analyzed(String reportId) async {
    final res = await http.post(
      Uri.parse('${env.functionsUrl}/analyze-report'),
      headers: {
        'Authorization': 'Bearer ${env.anonKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'report_id': reportId}),
    );
    expect(res.statusCode, 200, reason: res.body);
    return await env.admin.from('reports').select().eq('id', reportId).single();
  }

  // lng picked so ((round(lng*10000) % 4) + 4) % 4 hits each road type:
  // 100.9000 -> 1009000 % 4 = 0 -> highway_expressway
  // 100.9001 -> 1 -> federal_route
  // 100.9002 -> 2 -> state_route
  // 100.9003 -> 3 -> municipal_local
  Future<String> submit(double lng, double speed,
      {Map<String, dynamic> extra = const {}}) async {
    return await cit.client.rpc('submit_report', params: {
      'p_lat': env.randomTestLat(),
      'p_lng': lng,
      'p_source': 'voice',
      'p_speed_kmh': speed,
      ...extra,
    }) as String;
  }

  test('score written back; >=80 auto-assigns, 79 does not', () async {
    final hi = await analyzed(await submit(100.9000, 80));
    expect(hi['risk_score'], 80);
    expect(hi['assigned'], true);
    expect(hi['analyzed_at'], isNotNull);
    expect(hi['rationale'], startsWith('FAKE:'));

    final lo = await analyzed(await submit(100.9001, 79));
    expect(lo['risk_score'], 79);
    expect(lo['assigned'], false);
  });

  test('routing matrix: each lng bucket lands on its 1:1 role', () async {
    final cases = {
      100.9000: ['highway_expressway', 'highway', 'LITRAK'],
      100.9001: ['federal_route', 'jkr_malaysia', 'JKR Malaysia'],
      100.9002: ['state_route', 'jkr_selangor', 'JKR Selangor'],
      100.9003: [
        'municipal_local',
        'local_council',
        'Majlis Bandaraya Shah Alam (MBSA)'
      ],
    };
    for (final e in cases.entries) {
      final row = await analyzed(await submit(e.key, 30));
      expect(row['road_type'], e.value[0], reason: 'lng ${e.key}');
      expect(row['authority_role'], e.value[1]);
      expect(row['authority_name'], e.value[2]);
    }
  });

  test('8-factor breakdown with answers, 5-factor without', () async {
    final withAns = await analyzed(await submit(100.9002, 40, extra: {
      'p_vehicle_type': 'motorcycle',
      'p_lane_position': 'right_fast',
      'p_impact_severity': 'swerve',
    }));
    final names = [
      for (final f in (withAns['factor_breakdown'] as List)) f['name']
    ];
    expect(
        names,
        containsAll([
          'depth', 'speed', 'lighting', 'rainfall', 'traffic',
          'vehicle_type', 'lane_position', 'impact_severity'
        ]));

    final without = await analyzed(await submit(100.9003, 40));
    final names2 = [
      for (final f in (without['factor_breakdown'] as List)) f['name']
    ];
    expect(names2,
        containsAll(['depth', 'speed', 'lighting', 'rainfall', 'traffic']));
    expect(names2, isNot(contains('vehicle_type')));
  });
}
