import 'package:supabase/supabase.dart';
import 'package:test/test.dart';
import '../lib/helpers.dart';

Future<String> seedReport(TestEnv env, String reporterId,
    {String? authorityRole,
    String status = 'active',
    int risk = 50,
    bool assigned = false}) async {
  final row = await env.admin
      .from('reports')
      .insert({
        'reporter': reporterId,
        'lat': env.randomTestLat(),
        'lng': 100.9,
        'source': 'photo',
        'status': status,
        'assigned': assigned,
        'risk_score': risk, // MUST be non-null: keeps analyze webhook silent
        if (authorityRole != null) 'authority_role': authorityRole,
        if (status == 'fixed')
          'fixed_at': DateTime.now().toUtc().toIso8601String(),
      })
      .select('id')
      .single();
  return row['id'] as String;
}

void main() {
  late TestEnv env;
  late TestActor citA, citB, jkrSel, council;
  setUpAll(() async {
    env = await TestEnv.load();
    citA = await env.createCitizen();
    citB = await env.createCitizen();
    jkrSel = await env.createRole('jkr_selangor');
    council = await env.createRole('local_council');
  });
  tearDownAll(() async => env.dispose());

  test('citizen sees all active, own fixed, not others fixed', () async {
    final active = await seedReport(env, citA.id, authorityRole: 'jkr_selangor');
    final ownFixed = await seedReport(env, citB.id, status: 'fixed');
    final othersFixed = await seedReport(env, citA.id, status: 'fixed');
    final seenByB = await citB.client.from('reports').select('id');
    final ids = [for (final r in seenByB) r['id']];
    expect(ids, contains(active));
    expect(ids, contains(ownFixed));
    expect(ids, isNot(contains(othersFixed)));
  });

  test('role sees exactly its authority rows', () async {
    final mine = await seedReport(env, citA.id, authorityRole: 'jkr_selangor');
    final theirs = await seedReport(env, citA.id, authorityRole: 'local_council');
    final unrouted = await seedReport(env, citA.id);
    final seen = await jkrSel.client.from('reports').select('id');
    final ids = [for (final r in seen) r['id']];
    expect(ids, contains(mine));
    expect(ids, isNot(contains(theirs)));
    expect(ids, isNot(contains(unrouted)));
  });

  test('role can assign own row, cross-role update is a no-op', () async {
    final mine = await seedReport(env, citA.id, authorityRole: 'jkr_selangor');
    await jkrSel.client
        .from('reports')
        .update({'assigned': true}).eq('id', mine);
    final row =
        await env.admin.from('reports').select('assigned').eq('id', mine).single();
    expect(row['assigned'], true);

    await council.client
        .from('reports')
        .update({'assigned': false}).eq('id', mine); // silently 0 rows
    final row2 =
        await env.admin.from('reports').select('assigned').eq('id', mine).single();
    expect(row2['assigned'], true);
  });

  test('citizen cannot INSERT reports directly', () async {
    Object? err;
    try {
      await citA.client.from('reports').insert({
        'reporter': citA.id,
        'lat': 2.2,
        'lng': 100.9,
        'source': 'photo'
      });
    } catch (e) {
      err = e;
    }
    expect(err, isNotNull);
  });

  test('ledger: own rows only; direct writes rejected; roles see none', () async {
    await env.admin.from('points_ledger').insert(
        {'profile_id': citA.id, 'amount': 10, 'reason': 'test seed'});
    final aRows = await citA.client.from('points_ledger').select();
    expect(aRows, isNotEmpty);
    final bRows = await citB.client.from('points_ledger').select();
    expect([for (final r in bRows) r['profile_id']], isNot(contains(citA.id)));
    final roleRows = await jkrSel.client.from('points_ledger').select();
    expect(roleRows, isEmpty);
    Object? err;
    try {
      await citA.client.from('points_ledger').insert(
          {'profile_id': citA.id, 'amount': 999, 'reason': 'forged'});
    } catch (e) {
      err = e;
    }
    expect(err, isNotNull);
  });

  test('redemptions: own rows only; roles see none; direct writes rejected',
      () async {
    final code = 'TP-RLST-${DateTime.now().millisecondsSinceEpoch}';
    final item = await env.admin
        .from('voucher_catalog')
        .upsert({
          'name': 'RLS TEST Voucher',
          'brand': 'TEST',
          'points_cost': 10,
          'value_rm': 1.0
        }, onConflict: 'name')
        .select('id')
        .single();
    addTearDown(() async {
      // cleanup so re-runs and Task 7 start clean, even if an assertion
      // above throws (addTearDown still runs); FK-safe order: redemptions
      // before voucher_catalog.
      await env.admin.from('redemptions').delete().eq('catalog_id', item['id']);
      await env.admin.from('voucher_catalog').delete().eq('id', item['id']);
    });
    await env.admin.from('redemptions').insert({
      'profile_id': citA.id,
      'catalog_id': item['id'],
      'code': code
    });
    final aRows = await citA.client.from('redemptions').select();
    expect([for (final r in aRows) r['code']], contains(code));
    final bRows = await citB.client.from('redemptions').select();
    expect([for (final r in bRows) r['code']], isNot(contains(code)));
    final roleRows = await jkrSel.client.from('redemptions').select();
    expect(roleRows, isEmpty);
    Object? err;
    try {
      await citB.client.from('redemptions').insert({
        'profile_id': citB.id,
        'catalog_id': item['id'],
        'code': 'TP-FORG-0001'
      });
    } catch (e) {
      err = e;
    }
    expect(err, isNotNull);
  });

  test('profiles: own row select+update only', () async {
    await citA.client
        .from('profiles')
        .update({'display_name': 'Renamed A'}).eq('id', citA.id);
    final self =
        await citA.client.from('profiles').select().eq('id', citA.id).single();
    expect(self['display_name'], 'Renamed A');
    final others =
        await citA.client.from('profiles').select().eq('id', citB.id);
    expect(others, isEmpty);
  });

  test('citizen cannot escalate role via profiles update', () async {
    Object? err;
    try {
      await citA.client
          .from('profiles')
          .update({'role': 'jkr_selangor'}).eq('id', citA.id);
    } catch (e) {
      err = e;
    }
    expect(err, isNotNull, reason: 'column-level UPDATE grant should reject role writes');
    expect(err, isA<PostgrestException>());
    expect((err as PostgrestException).code, '42501');
    final row =
        await env.admin.from('profiles').select('role').eq('id', citA.id).single();
    expect(row['role'], 'citizen');
  });

  test('citizen can still rename self after column-grant fix', () async {
    await citA.client
        .from('profiles')
        .update({'display_name': 'Renamed A Again'}).eq('id', citA.id);
    final self = await env.admin
        .from('profiles')
        .select('display_name')
        .eq('id', citA.id)
        .single();
    expect(self['display_name'], 'Renamed A Again');
  });

  test('government role cannot tamper with protected report columns',
      () async {
    final mine = await seedReport(env, citA.id, authorityRole: 'jkr_selangor');
    Object? err;
    try {
      await jkrSel.client
          .from('reports')
          .update({'risk_score': 1}).eq('id', mine);
    } catch (e) {
      err = e;
    }
    expect(err, isNotNull,
        reason: 'column-level UPDATE grant should reject risk_score writes');
    expect(err, isA<PostgrestException>());
    expect((err as PostgrestException).code, '42501');
    final row = await env.admin
        .from('reports')
        .select('risk_score')
        .eq('id', mine)
        .single();
    expect(row['risk_score'], 50);
  });

  test('government role can still assign a report in its authority',
      () async {
    final mine = await seedReport(env, citA.id, authorityRole: 'jkr_selangor');
    await jkrSel.client
        .from('reports')
        .update({'assigned': true}).eq('id', mine);
    final row = await env.admin
        .from('reports')
        .select('assigned')
        .eq('id', mine)
        .single();
    expect(row['assigned'], true);
  });
}
