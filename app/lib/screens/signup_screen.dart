import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';
import '../theme.dart';

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
  bool _showPassword = false;

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
            content: Text('Ralat rangkaian. Semak sambungan anda dan cuba lagi.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Cipta Akaun')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Sertai TampalPintar',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text('Kumpul mata setiap kali lubang jalan yang anda laporkan dibaiki.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant)),
                const SectionHeader('Akaun'),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'E-mel',
                    prefixIcon: Icon(Icons.mail_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: !_showPassword,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    labelText: 'Kata Laluan',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      tooltip: _showPassword
                          ? 'Sembunyikan kata laluan'
                          : 'Tunjukkan kata laluan',
                      icon: Icon(_showPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                ),
                const SectionHeader('Profil'),
                TextField(
                  controller: _displayName,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nama Paparan',
                    helperText: 'Dipaparkan pada papan pendahulu Pelapor Terbaik',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _dashcamId,
                  decoration: const InputDecoration(
                    labelText: 'ID Dashcam (pilihan)',
                    helperText: 'Memadankan dashcam anda untuk laporan bebas tangan',
                    prefixIcon: Icon(Icons.videocam_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _vehicle,
                  decoration: const InputDecoration(
                    labelText: 'Kenderaan Saya (pilihan)',
                    prefixIcon: Icon(Icons.directions_car_outlined),
                  ),
                  items: [
                    for (final e in kVehicleOptions.entries)
                      DropdownMenuItem(value: e.key, child: Text(e.value)),
                  ],
                  onChanged: (v) => setState(() => _vehicle = v),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _busy ? null : _signup,
                    child: _busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5))
                        : const Text('Cipta Akaun'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
