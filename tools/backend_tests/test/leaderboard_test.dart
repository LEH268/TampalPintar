import 'package:test/test.dart';
import '../lib/helpers.dart';

void main() {
  late TestEnv env;
  late TestActor a, b;
  setUpAll(() async {
    env = await TestEnv.load();
    a = await env.createCitizen(displayName: 'LB Alpha');
    b = await env.createCitizen(displayName: 'LB Beta');
    // Alpha: +100 +50 -30 => lifetime 150, balance 120. Beta: +120.
    await env.admin.from('points_ledger').insert([
      {'profile_id': a.id, 'amount': 100, 'reason': 'test'},
      {'profile_id': a.id, 'amount': 50, 'reason': 'test'},
      {'profile_id': a.id, 'amount': -30, 'reason': 'test spend'},
      {'profile_id': b.id, 'amount': 120, 'reason': 'test'},
    ]);
  });
  tearDownAll(() async => env.dispose());

  test('top reporters ranked by lifetime earned; spending ignored', () async {
    final rows = await a.client.rpc('top_reporters') as List;
    final alpha = rows.firstWhere((r) => r['display_name'] == 'LB Alpha');
    final beta = rows.firstWhere((r) => r['display_name'] == 'LB Beta');
    expect(alpha['lifetime_points'], 150); // the -30 spend did not reduce it
    expect(beta['lifetime_points'], 120);
    expect(rows.indexOf(alpha), lessThan(rows.indexOf(beta)));
  });

  test('department avg = mean open seconds; roles without fixes = null',
      () async {
    // two fixed reports for jkr_selangor: open 100 s and 300 s => avg 200 s
    final base = DateTime.utc(2026, 1, 1);
    for (final openSecs in [100, 300]) {
      await env.admin.from('reports').insert({
        'reporter': a.id,
        'lat': env.randomTestLat(),
        'lng': 100.98,
        'source': 'photo',
        'status': 'fixed',
        'assigned': true,
        'authority_role': 'jkr_selangor',
        'risk_score': 40,
        'reported_at': base.toIso8601String(),
        'fixed_at': base.add(Duration(seconds: openSecs)).toIso8601String(),
      });
    }
    final rows = await a.client.rpc('department_response') as List;
    expect(rows, hasLength(4));
    final sel = rows.firstWhere((r) => r['role'] == 'jkr_selangor');
    // avg includes only jkr_selangor fixed rows created in THIS test run when
    // the DB is otherwise clean (pre-seed). If seed data exists, assert
    // fix_count >= 2 and skip the exact average.
    if (sel['fix_count'] == 2) {
      expect((sel['avg_open_seconds'] as num).toDouble(), closeTo(200.0, 0.5));
    } else {
      expect(sel['fix_count'], greaterThanOrEqualTo(2));
    }
    for (final r in rows.where((r) => r['fix_count'] == 0)) {
      expect(r['avg_open_seconds'], isNull); // "no data yet" shape
    }
  });
}
