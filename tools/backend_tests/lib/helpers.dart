import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:supabase/supabase.dart';

const kTestPassword = 'TampalPintar#2026';

class TestActor {
  TestActor(this.id, this.email, this.client);
  final String id;
  final String email;
  final SupabaseClient client;
}

class TestEnv {
  TestEnv._(this.url, this.anonKey, this.serviceRoleKey, this.functionsUrl)
      : admin = SupabaseClient(url, serviceRoleKey);

  final String url, anonKey, serviceRoleKey, functionsUrl;
  final SupabaseClient admin;
  final List<TestActor> _actors = [];
  final _rand = Random();

  static Future<TestEnv> load() async {
    final raw = jsonDecode(
        await File('test_config.json').readAsString()) as Map<String, dynamic>;
    return TestEnv._(raw['url'], raw['anonKey'], raw['serviceRoleKey'],
        raw['functionsUrl']);
  }

  String _uniqueEmail(String tag) =>
      't_${tag}_${DateTime.now().millisecondsSinceEpoch}_${_rand.nextInt(99999)}@test.tampalpintar.dev';

  Future<TestActor> _createUser(String tag, Map<String, dynamic> meta) async {
    final email = _uniqueEmail(tag);
    final res = await admin.auth.admin.createUser(AdminUserAttributes(
        email: email,
        password: kTestPassword,
        emailConfirm: true,
        userMetadata: meta));
    final id = res.user!.id;
    final client = SupabaseClient(url, anonKey);
    await client.auth
        .signInWithPassword(email: email, password: kTestPassword);
    final actor = TestActor(id, email, client);
    _actors.add(actor);
    return actor;
  }

  Future<TestActor> createCitizen(
      {String? displayName,
      String? dashcamId,
      String? defaultVehicleType}) async {
    final actor = await _createUser('cit', {
      if (displayName != null) 'display_name': displayName,
      if (dashcamId != null) 'dashcam_id': dashcamId,
      if (defaultVehicleType != null)
        'default_vehicle_type': defaultVehicleType,
    });
    return actor;
  }

  Future<TestActor> createRole(String role) async {
    final actor = await _createUser(role, {'display_name': 'Test $role'});
    await admin.from('profiles').update({'role': role}).eq('id', actor.id);
    return actor;
  }

  double randomTestLat() => 2.0 + _rand.nextDouble() * 0.5;

  Future<void> dispose() async {
    for (final a in _actors) {
      await admin.from('points_ledger').delete().eq('profile_id', a.id);
      await admin.from('redemptions').delete().eq('profile_id', a.id);
      final reports =
          await admin.from('reports').select('id').eq('reporter', a.id);
      for (final r in reports) {
        await admin.from('points_ledger').delete().eq('report_id', r['id']);
      }
      await admin.from('reports').delete().eq('reporter', a.id);
      try {
        final objs = await admin.storage.from('media').list(
            path: 'reports/${a.id}',
            searchOptions: const SearchOptions(limit: 100));
        for (final o in objs) {
          final sub = await admin.storage.from('media').list(
              path: 'reports/${a.id}/${o.name}',
              searchOptions: const SearchOptions(limit: 100));
          if (sub.isNotEmpty) {
            await admin.storage.from('media').remove(
                [for (final f in sub) 'reports/${a.id}/${o.name}/${f.name}']);
          }
        }
      } catch (_) {}
      a.client.dispose();
      await admin.auth.admin.deleteUser(a.id);
    }
    _actors.clear();
    admin.dispose();
  }
}

double offsetLngMeters(double lat, double meters) =>
    meters / (111320 * cos(lat * pi / 180));
