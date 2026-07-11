import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _displayName = TextEditingController();
  final _dashcamId = TextEditingController();
  String? _vehicle;
  bool _busy = false;

  Future<void> _signup() async {
    setState(() => _busy = true);
    try {
      await Supabase.instance.client.auth.signUp(
        email: _email.text.trim(),
        password: _password.text,
        data: {
          if (_displayName.text.trim().isNotEmpty)
            'display_name': _displayName.text.trim(),
          if (_dashcamId.text.trim().isNotEmpty)
            'dashcam_id': _dashcamId.text.trim(),
          if (_vehicle != null) 'default_vehicle_type': _vehicle,
        },
      );
      if (mounted) Navigator.of(context).pop();
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Network error. Check your connection and try again.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Sign up')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email')),
              TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password')),
              TextField(
                  controller: _displayName,
                  decoration: const InputDecoration(
                      labelText: 'Display name (shown on leaderboards)')),
              TextField(
                  controller: _dashcamId,
                  decoration: const InputDecoration(
                      labelText: 'Dashcam ID (optional)')),
              DropdownButtonFormField<String>(
                initialValue: _vehicle,
                decoration:
                    const InputDecoration(labelText: 'My Vehicle (optional)'),
                items: [
                  for (final e in kVehicleOptions.entries)
                    DropdownMenuItem(value: e.key, child: Text(e.value)),
                ],
                onChanged: (v) => setState(() => _vehicle = v),
              ),
              const SizedBox(height: 16),
              FilledButton(
                  onPressed: _busy ? null : _signup,
                  child: const Text('Create account')),
            ],
          ),
        ),
      );
}
