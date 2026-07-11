import 'package:supabase_flutter/supabase_flutter.dart';

const kVehicleOptions = {
  'motorcycle': 'Motorcycle',
  'car': 'Car',
  'heavy_commercial': 'Heavy Commercial',
};

class ProfileService {
  ProfileService(this._client);
  final SupabaseClient _client;

  Future<Map<String, dynamic>> fetchMine() async {
    final uid = _client.auth.currentUser!.id;
    return await _client.from('profiles').select().eq('id', uid).single();
  }

  Future<void> updateMine(
      {String? displayName, String? dashcamId, String? defaultVehicleType}) async {
    final user = _client.auth.currentUser!;
    final name = (displayName == null || displayName.trim().isEmpty)
        ? user.email!.split('@').first
        : displayName.trim();
    await _client.from('profiles').update({
      'display_name': name,
      'dashcam_id':
          (dashcamId == null || dashcamId.trim().isEmpty) ? null : dashcamId.trim(),
      'default_vehicle_type':
          (defaultVehicleType == null || defaultVehicleType.isEmpty)
              ? null
              : defaultVehicleType,
    }).eq('id', user.id);
  }
}
