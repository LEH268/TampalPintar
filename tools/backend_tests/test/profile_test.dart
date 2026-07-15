import 'package:test/test.dart';
import '../lib/helpers.dart';

void main() {
  late TestEnv env;
  setUpAll(() async => env = await TestEnv.load());
  tearDownAll(() async => env.dispose());

  test('signup metadata lands in profile', () async {
    final a = await env.createCitizen(
        displayName: 'Test Aisyah',
        dashcamId: 'TESTCAM-${DateTime.now().millisecondsSinceEpoch}',
        defaultVehicleType: 'motorcycle');
    final row =
        await env.admin.from('profiles').select().eq('id', a.id).single();
    expect(row['role'], 'citizen');
    expect(row['display_name'], 'Test Aisyah');
    expect(row['dashcam_id'], startsWith('TESTCAM-'));
    expect(row['default_vehicle_type'], 'motorcycle');
  });

  test('display_name falls back to email prefix', () async {
    final a = await env.createCitizen(); // no display_name metadata
    final row =
        await env.admin.from('profiles').select().eq('id', a.id).single();
    expect(row['display_name'], a.email.split('@').first);
  });

  test('dashcam_id is unique across profiles', () async {
    final cam = 'DUPCAM-${DateTime.now().millisecondsSinceEpoch}';
    final a = await env.createCitizen(dashcamId: cam);
    final b = await env.createCitizen();
    expect(a.id, isNot(b.id));
    Object? err;
    try {
      await env.admin
          .from('profiles')
          .update({'dashcam_id': cam}).eq('id', b.id);
    } catch (e) {
      err = e;
    }
    expect(err, isNotNull, reason: 'unique violation expected');
  });
}
