import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';
import '../lib/helpers.dart';

void main() {
  late TestEnv env;
  late TestActor cit;
  final cam = 'CLEANCAM${DateTime.now().millisecondsSinceEpoch}';
  final bytes = Uint8List.fromList(List.filled(32, 0xCD));

  setUpAll(() async {
    env = await TestEnv.load();
    cit = await env.createCitizen();
  });
  tearDownAll(() async => env.dispose());

  test('deletes all of live/{id}, never touches reports/', () async {
    for (var i = 1; i <= 3; i++) {
      await env.admin.storage.from('media').uploadBinary(
          'live/$cam/000000000000$i.jpg', bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'));
    }
    await env.admin.storage.from('media').uploadBinary(
        'reports/${cit.id}/keepme/f0.jpg', bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg'));

    final res = await http.post(
      Uri.parse('${env.functionsUrl}/dashcam-cleanup'),
      headers: {
        'Authorization': 'Bearer ${env.anonKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'dashcam_id': cam}),
    );
    expect(res.statusCode, 200);
    expect(jsonDecode(res.body)['deleted'], 3);

    final live = await env.admin.storage.from('media').list(
        path: 'live/$cam', searchOptions: const SearchOptions(limit: 10));
    expect(live, isEmpty);
    final kept = await env.admin.storage.from('media').list(
        path: 'reports/${cit.id}/keepme',
        searchOptions: const SearchOptions(limit: 10));
    expect([for (final o in kept) o.name], contains('f0.jpg'));
  });

  test('missing dashcam_id -> 400', () async {
    final res = await http.post(
      Uri.parse('${env.functionsUrl}/dashcam-cleanup'),
      headers: {
        'Authorization': 'Bearer ${env.anonKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({}),
    );
    expect(res.statusCode, 400);
  });
}
