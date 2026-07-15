import 'package:supabase/supabase.dart';
import 'package:test/test.dart';
import '../lib/helpers.dart';

void main() {
  late TestEnv env;
  late TestActor cit;
  late String itemId;
  setUpAll(() async {
    env = await TestEnv.load();
    cit = await env.createCitizen();
    final item = await env.admin
        .from('voucher_catalog')
        .upsert({
          'name': 'TEST Voucher RM5',
          'brand': 'TEST',
          'points_cost': 150,
          'value_rm': 5.0
        }, onConflict: 'name')
        .select('id')
        .single();
    itemId = item['id'] as String;
  });
  tearDownAll(() async {
    await env.admin.from('points_ledger').delete().eq('profile_id', cit.id);
    await env.admin.from('redemptions').delete().eq('catalog_id', itemId);
    await env.admin.from('voucher_catalog').delete().eq('id', itemId);
    await env.dispose();
  });

  Future<void> grant(int amount) => env.admin.from('points_ledger').insert(
      {'profile_id': cit.id, 'amount': amount, 'reason': 'test grant'});

  test('one point short fails, nothing written', () async {
    await grant(149);
    Object? err;
    try {
      await cit.client.rpc('redeem_voucher', params: {'p_catalog_id': itemId});
    } catch (e) {
      err = e;
    }
    expect(err.toString(), contains('insufficient_points'));
    final reds =
        await env.admin.from('redemptions').select().eq('profile_id', cit.id);
    expect(reds, isEmpty);
  });

  test('exact balance succeeds atomically; second redeem fails', () async {
    await grant(1); // 149 + 1 = 150 exactly
    final code = await cit.client
        .rpc('redeem_voucher', params: {'p_catalog_id': itemId}) as String;
    expect(RegExp(r'^TP-[A-F0-9]{4}-[A-F0-9]{4}$').hasMatch(code), isTrue);

    final reds =
        await env.admin.from('redemptions').select().eq('profile_id', cit.id);
    expect(reds, hasLength(1));
    expect(reds.first['code'], code);

    final ledger = await env.admin
        .from('points_ledger')
        .select()
        .eq('profile_id', cit.id)
        .eq('redemption_id', reds.first['id']);
    expect(ledger, hasLength(1));
    expect(ledger.first['amount'], -150);

    Object? err;
    try {
      await cit.client.rpc('redeem_voucher', params: {'p_catalog_id': itemId});
    } catch (e) {
      err = e;
    }
    expect(err.toString(), contains('insufficient_points')); // balance now 0
  });

  test('redemptions.code has a real UNIQUE constraint', () async {
    final existing = await env.admin
        .from('redemptions')
        .select('code')
        .eq('profile_id', cit.id)
        .single();
    final dupCode = existing['code'] as String;
    Object? err;
    try {
      await env.admin.from('redemptions').insert({
        'profile_id': cit.id,
        'catalog_id': itemId,
        'code': dupCode,
      });
    } catch (e) {
      err = e;
    }
    expect(err, isA<PostgrestException>());
    expect((err as PostgrestException).code, '23505'); // unique_violation
  });
}
