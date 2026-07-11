import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';

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
    if (!_loaded) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        TextField(
            controller: _displayName,
            decoration: const InputDecoration(labelText: 'Display name')),
        TextField(
            controller: _dashcamId,
            decoration: const InputDecoration(labelText: 'Dashcam ID')),
        DropdownButtonFormField<String?>(
          initialValue: _vehicle,
          decoration: const InputDecoration(labelText: 'My Vehicle'),
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('None')),
            for (final e in kVehicleOptions.entries)
              DropdownMenuItem<String?>(value: e.key, child: Text(e.value)),
          ],
          onChanged: (v) => setState(() => _vehicle = v),
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: _save, child: const Text('Save')),
        const SizedBox(height: 32),
        OutlinedButton(
          onPressed: () => Supabase.instance.client.auth.signOut(),
          child: const Text('Log out'),
        ),
      ],
    );
  }
}
