import 'package:test/test.dart';
import '../lib/helpers.dart';

void main() {
  late TestEnv env;
  late TestActor cit, jkrMy, council;
  setUpAll(() async {
    env = await TestEnv.load();
    cit = await env.createCitizen();
    jkrMy = await env.createRole('jkr_malaysia');
    council = await env.createRole('local_council');
  });
  tearDownAll(() async => env.dispose());

  Future<String> seed({int? risk = 65, bool assigned = false}) async {
    final row = await env.admin
        .from('reports')
        .insert({
          'reporter': cit.id,
          'lat': env.randomTestLat(),
          'lng': 100.97,
          'source': 'voice',
          'authority_role': 'jkr_malaysia',
          'authority_name': 'JKR Malaysia',
          'assigned': assigned,
          'risk_score': risk ?? 100, // placeholder; nulled below for the 50-fallback case
        })
        .select('id')
        .single();
    if (risk == null) {
      await env.admin
          .from('reports')
          .update({'risk_score': null}).eq('id', row['id']);
    }
    return row['id'] as String;
  }

  Future<Object?> tryFix(TestActor actor, String id) async {
    try {
      await actor.client.rpc('mark_fixed', params: {'p_report_id': id});
      return null;
    } catch (e) {
      return e;
    }
  }

  test('rejects unassigned', () async {
    final id = await seed(assigned: false);
    final err = await tryFix(jkrMy, id);
    expect(err.toString(), contains('not_assigned'));
  });

  test('happy path: fixed_at set + exact-score ledger row, no double award',
      () async {
    final id = await seed(assigned: true);
    expect(await tryFix(jkrMy, id), isNull);
    final row = await env.admin.from('reports').select().eq('id', id).single();
    expect(row['status'], 'fixed');
    expect(row['fixed_at'], isNotNull);
    final ledger =
        await env.admin.from('points_ledger').select().eq('report_id', id);
    expect(ledger, hasLength(1));
    expect(ledger.first['amount'], 65);
    expect(ledger.first['profile_id'], cit.id);

    final again = await tryFix(jkrMy, id);
    expect(again.toString(), contains('already_fixed'));
    final ledger2 =
        await env.admin.from('points_ledger').select().eq('report_id', id);
    expect(ledger2, hasLength(1)); // still exactly one award
  });

  test('unscored report awards flat 50', () async {
    final id = await seed(risk: null, assigned: true);
    expect(await tryFix(jkrMy, id), isNull);
    final ledger =
        await env.admin.from('points_ledger').select().eq('report_id', id);
    expect(ledger.first['amount'], 50);
  });

  test('wrong role rejected', () async {
    final id = await seed(assigned: true);
    final err = await tryFix(council, id);
    expect(err.toString(), contains('not_your_report'));
  });

  test('citizen rejected', () async {
    final id = await seed(assigned: true);
    final err = await tryFix(cit, id);
    expect(err.toString(), contains('not_your_report'));
  });
}
