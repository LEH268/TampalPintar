import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';
import '../theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _service = ProfileService(Supabase.instance.client);
  final _displayName = TextEditingController();
  final _dashcamId = TextEditingController();
  String? _vehicle;
  bool _loaded = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    Map<String, dynamic> p;
    try {
      p = await _service.fetchMine();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Could not load your profile. Pull to retry.';
        _loaded = true;
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _displayName.text = p['display_name'] ?? '';
      _dashcamId.text = p['dashcam_id'] ?? '';
      _vehicle = p['default_vehicle_type'];
      _loaded = true;
    });
  }

  Future<void> _save() async {
    await _service.updateMine(
        displayName: _displayName.text,
        dashcamId: _dashcamId.text,
        defaultVehicleType: _vehicle);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (!_loaded) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 36, color: scheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(_loadError!),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _loaded = false;
                  _loadError = null;
                });
                _load();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SectionHeader('Profile', top: 0),
            TextField(
                controller: _displayName,
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  helperText: 'Shown on the Top Reporters leaderboard',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                )),
            const SizedBox(height: 12),
            TextField(
                controller: _dashcamId,
                decoration: const InputDecoration(
                  labelText: 'Dashcam ID',
                  helperText: 'Pairs your dashcam for hands-free reports',
                  prefixIcon: Icon(Icons.videocam_outlined),
                )),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _vehicle,
              decoration: const InputDecoration(
                labelText: 'My Vehicle',
                prefixIcon: Icon(Icons.directions_car_outlined),
              ),
              items: [
                const DropdownMenuItem<String?>(
                    value: null, child: Text('None')),
                for (final e in kVehicleOptions.entries)
                  DropdownMenuItem<String?>(
                      value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => setState(() => _vehicle = v),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check_rounded, size: 20),
                  label: const Text('Save changes')),
            ),
            const SectionHeader('Account'),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: scheme.error,
                side: BorderSide(color: scheme.error.withValues(alpha: 0.5)),
              ),
              onPressed: () => Supabase.instance.client.auth.signOut(),
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text('Log out'),
            ),
          ],
        ),
      ),
    );
  }
}
