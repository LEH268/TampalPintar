import 'dart:typed_data';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';
import '../lib/helpers.dart';

void main() {
  late TestEnv env;
  late TestActor citA, citB;
  late SupabaseClient anon;
  final bytes = Uint8List.fromList(List.filled(64, 0xAB));
  final cam = 'STORCAM${DateTime.now().millisecondsSinceEpoch}';

  setUpAll(() async {
    env = await TestEnv.load();
    citA = await env.createCitizen();
    citB = await env.createCitizen();
    anon = SupabaseClient(env.url, env.anonKey);
  });
  tearDownAll(() async {
    final live = await env.admin.storage.from('media').list(
        path: 'live/$cam', searchOptions: const SearchOptions(limit: 100));
    if (live.isNotEmpty) {
      await env.admin.storage
          .from('media')
          .remove([for (final o in live) 'live/$cam/${o.name}']);
    }
    anon.dispose();
    await env.dispose();
  });

  Future<Object?> tryUpload(SupabaseClient c, String path) async {
    try {
      await c.storage.from('media').uploadBinary(path, bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'));
      return null;
    } catch (e) {
      return e;
    }
  }

  test('anon can upload under live/, not under reports/', () async {
    expect(await tryUpload(anon, 'live/$cam/0000000000001.jpg'), isNull);
    expect(await tryUpload(anon, 'reports/${citA.id}/x/f0.jpg'), isNotNull);
  });

  test('citizen uploads only under own reports/ prefix', () async {
    expect(await tryUpload(citA.client, 'reports/${citA.id}/d1/f0.jpg'), isNull);
    expect(
        await tryUpload(citA.client, 'reports/${citB.id}/d1/f0.jpg'), isNotNull);
  });

  test('citizen can copy live -> own reports and delete own, not others',
      () async {
    await citA.client.storage
        .from('media')
        .copy('live/$cam/0000000000001.jpg', 'reports/${citA.id}/d1/f1.jpg');
    final listed = await citA.client.storage.from('media').list(
        path: 'reports/${citA.id}/d1',
        searchOptions: const SearchOptions(limit: 10));
    expect([for (final o in listed) o.name], containsAll(['f0.jpg', 'f1.jpg']));

    await citA.client.storage
        .from('media')
        .remove(['reports/${citA.id}/d1/f1.jpg']);
    // cross-user delete: silently removes nothing
    await citB.client.storage
        .from('media')
        .remove(['reports/${citA.id}/d1/f0.jpg']);
    final still = await env.admin.storage.from('media').list(
        path: 'reports/${citA.id}/d1',
        searchOptions: const SearchOptions(limit: 10));
    expect([for (final o in still) o.name], contains('f0.jpg'));
  });
}
