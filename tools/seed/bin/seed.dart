import 'dart:io';
import 'package:supabase/supabase.dart';

const kPassword = 'TampalPintar#2026';

const kRoles = {
  'jkr.malaysia@tampalpintar.demo': ['jkr_malaysia', 'JKR Malaysia'],
  'jkr.selangor@tampalpintar.demo': ['jkr_selangor', 'JKR Selangor'],
  'local.council@tampalpintar.demo': ['local_council', 'Local Council (PBT)'],
  'highway@tampalpintar.demo': ['highway', 'Highway Concessionaire'],
};

const kCitizens = {
  'aisyah@tampalpintar.demo': 'Aisyah Rahman',
  'weiming@tampalpintar.demo': 'Tan Wei Ming',
  'kumar@tampalpintar.demo': 'Kumar Selvam',
  'siti@tampalpintar.demo': 'Siti Nurhaliza',
};

const kVouchers = [
  ["Touch 'n Go RM5", "Touch 'n Go", 150, 5.0],
  ['Grab RM8', 'Grab', 200, 8.0],
  ['Petronas RM10', 'Petronas', 250, 10.0],
  ['Shopee RM15', 'Shopee', 400, 15.0],
  ["Touch 'n Go RM20", "Touch 'n Go", 500, 20.0],
];

// [lat, lng, risk, road_type, authority_role, authority_name, source,
//  speed_kmh?, vehicle?, lane?, impact?]
const kActive = [
  [3.0733, 101.5185, 45, 'municipal_local', 'local_council', 'Majlis Bandaraya Shah Alam (MBSA)', 'voice', 42, 'car', 'middle', 'bump'],
  [3.1073, 101.6067, 92, 'highway_expressway', 'highway', 'LITRAK', 'voice', 88, 'motorcycle', 'right_fast', 'swerve'],
  [3.0449, 101.4456, 78, 'federal_route', 'jkr_malaysia', 'JKR Malaysia', 'photo', null, null, null, null],
  [2.8130, 101.5000, 30, 'state_route', 'jkr_selangor', 'JKR Selangor', 'photo', null, null, null, null],
  [3.0567, 101.5851, 55, 'municipal_local', 'local_council', 'Majlis Bandaraya Subang Jaya (MBSJ)', 'voice', 35, 'car', 'left_slow', 'bump'],
  [3.1500, 101.5500, 85, 'highway_expressway', 'highway', 'PLUS Malaysia Berhad', 'voice', 95, null, null, null],
  [3.3200, 101.2500, 62, 'federal_route', 'jkr_malaysia', 'JKR Malaysia', 'voice', 60, 'heavy_commercial', 'middle', 'bump'],
  [3.1500, 101.7600, 38, 'municipal_local', 'local_council', 'Majlis Perbandaran Ampang Jaya (MPAJ)', 'photo', null, null, null, null],
  [3.5500, 101.6500, 71, 'state_route', 'jkr_selangor', 'JKR Selangor', 'voice', 65, 'motorcycle', 'single_lane', 'swerve'],
  [2.8200, 101.7000, 25, 'municipal_local', 'local_council', 'Majlis Perbandaran Sepang (MPSepang)', 'photo', null, null, null, null],
];

// [role, authority_name, risk, days_open]
const kFixed = [
  ['jkr_malaysia', 'JKR Malaysia', 92, 1.2],
  ['jkr_malaysia', 'JKR Malaysia', 55, 2.4],
  ['jkr_selangor', 'JKR Selangor', 68, 3.1],
  ['jkr_selangor', 'JKR Selangor', 44, 4.6],
  ['local_council', 'Majlis Bandaraya Shah Alam (MBSA)', 85, 1.8],
  ['local_council', 'Majlis Bandaraya Petaling Jaya (MBPJ)', 37, 5.0],
  ['highway', 'LITRAK', 90, 1.1],
  ['highway', 'KESAS Sdn Bhd', 51, 2.0],
];

Future<void> main() async {
  final url = Platform.environment['SEED_URL'];
  final key = Platform.environment['SEED_SERVICE_ROLE_KEY'];
  if (url == null || key == null) {
    stderr.writeln('Set SEED_URL and SEED_SERVICE_ROLE_KEY first.');
    exit(1);
  }
  final admin = SupabaseClient(url, key);

  Future<String> ensureUser(String email, Map<String, dynamic> meta) async {
    try {
      final res = await admin.auth.admin.createUser(AdminUserAttributes(
          email: email,
          password: kPassword,
          emailConfirm: true,
          userMetadata: meta));
      return res.user!.id;
    } catch (_) {
      // already exists: find it
      var page = 1;
      while (true) {
        final users =
            await admin.auth.admin.listUsers(page: page, perPage: 100);
        if (users.isEmpty) throw StateError('user $email not found');
        for (final u in users) {
          if (u.email == email) return u.id;
        }
        page++;
      }
    }
  }

  // 1. role accounts
  final roleIds = <String, String>{}; // role enum -> profile id
  for (final e in kRoles.entries) {
    final id = await ensureUser(e.key, {'display_name': e.value[1]});
    await admin
        .from('profiles')
        .update({'role': e.value[0], 'display_name': e.value[1]}).eq('id', id);
    roleIds[e.value[0] as String] = id;
  }

  // 2. citizens
  final citizenIds = <String>[];
  for (final e in kCitizens.entries) {
    final id = await ensureUser(e.key, {'display_name': e.value});
    await admin.from('profiles').update({
      'display_name': e.value,
      if (e.key.startsWith('aisyah')) 'dashcam_id': 'DEMO-CAM-01',
      if (e.key.startsWith('aisyah')) 'default_vehicle_type': 'car',
    }).eq('id', id);
    citizenIds.add(id);
  }

  // 3. wipe previous seed rows (tagged by rationale prefix)
  final old = await admin
      .from('reports')
      .select('id')
      .like('rationale', 'SEED:%');
  for (final r in old) {
    await admin.from('points_ledger').delete().eq('report_id', r['id']);
  }
  await admin
      .from('points_ledger')
      .delete()
      .like('reason', 'SEED:%');
  await admin.from('redemptions').delete().like('code', 'TP-DEMO%');
  await admin.from('reports').delete().like('rationale', 'SEED:%');

  // 4. voucher catalog
  for (final v in kVouchers) {
    await admin.from('voucher_catalog').upsert({
      'name': v[0],
      'brand': v[1],
      'points_cost': v[2],
      'value_rm': v[3],
    }, onConflict: 'name');
  }

  final now = DateTime.now().toUtc();

  // 5. active reports (risk_score set -> webhook stays silent)
  for (var i = 0; i < kActive.length; i++) {
    final a = kActive[i];
    await admin.from('reports').insert({
      'reporter': citizenIds[i % citizenIds.length],
      'lat': a[0],
      'lng': a[1],
      'risk_score': a[2],
      'road_type': a[3],
      'authority_role': a[4],
      'authority_name': a[5],
      'source': a[6],
      'speed_kmh': a[7],
      'vehicle_type': a[8],
      'lane_position': a[9],
      'impact_severity': a[10],
      'assigned': (a[2] as int) >= 80,
      'rationale':
          'SEED: sample ${a[3]} pothole, risk ${a[2]} for demo purposes',
      'factor_breakdown': [
        {'name': 'depth', 'level': 'moderate'},
        {'name': 'speed', 'level': '${a[7] ?? "n/a"} km/h'},
        {'name': 'lighting', 'level': 'day'},
        {'name': 'rainfall', 'level': 'none'},
        {'name': 'traffic', 'level': a[3]},
        if (a[8] != null) {'name': 'vehicle_type', 'level': a[8]},
        if (a[9] != null) {'name': 'lane_position', 'level': a[9]},
        if (a[10] != null) {'name': 'impact_severity', 'level': a[10]},
      ],
      'reported_at':
          now.subtract(Duration(hours: 3 + i * 7)).toIso8601String(),
      'analyzed_at': now.toIso8601String(),
    });
  }

  // 6. fixed reports + points awards
  for (var i = 0; i < kFixed.length; i++) {
    final f = kFixed[i];
    final reporter = citizenIds[i % citizenIds.length];
    final reportedAt =
        now.subtract(Duration(minutes: (((f[3] as double) * 1440) + i * 60).round()));
    final fixedAt =
        reportedAt.add(Duration(minutes: ((f[3] as double) * 1440).round()));
    final row = await admin
        .from('reports')
        .insert({
          'reporter': reporter,
          'lat': 3.0 + i * 0.05,
          'lng': 101.4 + i * 0.04,
          'risk_score': f[2],
          'road_type': f[0] == 'highway'
              ? 'highway_expressway'
              : f[0] == 'jkr_malaysia'
                  ? 'federal_route'
                  : f[0] == 'jkr_selangor'
                      ? 'state_route'
                      : 'municipal_local',
          'authority_role': f[0],
          'authority_name': f[1],
          'source': 'photo',
          'status': 'fixed',
          'assigned': true,
          'rationale': 'SEED: fixed demo report',
          'reported_at': reportedAt.toIso8601String(),
          'fixed_at': fixedAt.toIso8601String(),
        })
        .select('id')
        .single();
    await admin.from('points_ledger').insert({
      'profile_id': reporter,
      'amount': f[2],
      'report_id': row['id'],
      'reason': 'SEED: Pothole fixed',
    });
  }

  // 7. one pre-redeemed voucher for Aisyah (150-pt Touch 'n Go RM5)
  final tng = await admin
      .from('voucher_catalog')
      .select('id')
      .eq('name', "Touch 'n Go RM5")
      .single();
  final redemption = await admin
      .from('redemptions')
      .insert({
        'profile_id': citizenIds[0],
        'catalog_id': tng['id'],
        'code': 'TP-DEMO-0001',
      })
      .select('id')
      .single();
  await admin.from('points_ledger').insert({
    'profile_id': citizenIds[0],
    'amount': -150,
    'redemption_id': redemption['id'],
    'reason': "SEED: Redeemed Touch 'n Go RM5",
  });

  // 8. report summary
  final reports = await admin.from('reports').select('id, status');
  final active = reports.where((r) => r['status'] == 'active').length;
  final fixed = reports.where((r) => r['status'] == 'fixed').length;
  stdout.writeln('Seed complete: $active active / $fixed fixed reports total.');
  admin.dispose();
}
