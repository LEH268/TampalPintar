import 'package:supabase_flutter/supabase_flutter.dart';

class GovService {
  GovService(this._client);
  final SupabaseClient _client;

  Future<Map<String, dynamic>> myProfile() async => await _client
      .from('profiles')
      .select()
      .eq('id', _client.auth.currentUser!.id)
      .single();

  /// RLS already limits rows to this role's authority — just filter active.
  Future<List<Map<String, dynamic>>> fetchMyActivePins() async {
    final rows = await _client
        .from('reports')
        .select('id, lat, lng')
        .eq('status', 'active');
    return [...rows];
  }

  Future<Map<String, dynamic>> fetchDetails(String id) async =>
      await _client.from('reports').select().eq('id', id).single();

  String publicUrl(String path) =>
      _client.storage.from('media').getPublicUrl(path);

  Future<void> assign(String id) async =>
      await _client.from('reports').update({'assigned': true}).eq('id', id);

  Future<void> markFixed(String id) async =>
      await _client.rpc('mark_fixed', params: {'p_report_id': id});
}
