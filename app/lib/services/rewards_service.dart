import 'package:supabase_flutter/supabase_flutter.dart';

class RewardsService {
  RewardsService(this._client);
  final SupabaseClient _client;
  String get _uid => _client.auth.currentUser!.id;

  Future<int> balance() async {
    final rows = await _client
        .from('points_ledger')
        .select('amount')
        .eq('profile_id', _uid);
    var sum = 0;
    for (final r in rows) {
      sum += (r['amount'] as num).toInt();
    }
    return sum;
  }

  Future<List<Map<String, dynamic>>> catalog() async {
    final rows = await _client
        .from('voucher_catalog')
        .select()
        .order('points_cost', ascending: true);
    return [...rows];
  }

  Future<List<Map<String, dynamic>>> myVouchers() async {
    final reds = await _client
        .from('redemptions')
        .select()
        .eq('profile_id', _uid)
        .order('redeemed_at', ascending: false);
    final items = await catalog();
    final nameById = {for (final i in items) i['id']: i['name']};
    return [
      for (final r in reds)
        {...r, 'name': nameById[r['catalog_id']] ?? 'Voucher'}
    ];
  }

  Future<List<Map<String, dynamic>>> history() async {
    final rows = await _client
        .from('points_ledger')
        .select()
        .eq('profile_id', _uid)
        .order('created_at', ascending: false);
    return [...rows];
  }

  Future<String> redeem(String catalogId) async =>
      await _client.rpc('redeem_voucher', params: {'p_catalog_id': catalogId})
          as String;
}
