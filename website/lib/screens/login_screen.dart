import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';
import '../session_state.dart';
import '../theme.dart';

/// Maps a login failure to a message that is safe to put in front of a user.
///
/// gotrue packs raw diagnostics into [AuthRetryableFetchException.message] — the
/// underlying `ClientException` including the full backend URL on a network or
/// CORS failure, and the raw response body on a 5xx. Neither belongs on screen,
/// so retryable-fetch failures are answered with a generic connection message.
/// Every other [AuthException] carries a curated message (gotrue's own, or the
/// role rejection thrown below) and is passed through.
@visibleForTesting
String loginErrorMessage(Object error) {
  if (error is AuthRetryableFetchException) {
    return 'Ralat rangkaian. Semak sambungan anda dan cuba lagi.';
  }
  if (error is AuthException) return error.message;
  return 'Log masuk gagal. Sila cuba lagi.';
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Sila masukkan e-mel.';
    // Pragmatic shape check, not RFC 5322 — the server stays the real authority.
    // This only spares the user a round-trip on an obvious typo.
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Format e-mel tidak sah.';
    }
    return null;
  }

  // Presence only. A minimum length here would lock out existing accounts whose
  // passwords predate the rule; password policy belongs at signup.
  String? _validatePassword(String? value) =>
      (value ?? '').isEmpty ? 'Sila masukkan kata laluan.' : null;

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    final client = Supabase.instance.client;
    try {
      await client.auth.signInWithPassword(
          email: _email.text.trim(), password: _password.text);
      final profile = await client
          .from('profiles')
          .select('role')
          .eq('id', client.auth.currentUser!.id)
          .single();
      final role = profile['role'] as String?;
      // Allowlist against the four government roles (kRoleLabels keys).
      if (role == null || !kRoleLabels.containsKey(role)) {
        await client.auth.signOut();
        throw const AuthException(
            'Akaun rakyat tidak boleh mengakses papan pemuka kerajaan.');
      }
      govRoleVerified.value = true; // auth gate swaps to the dashboard
    } on AuthException catch (e) {
      debugPrint('Login failed: $e'); // detail stays in the console, not the UI
      rootMessengerKey.currentState
          ?.showSnackBar(SnackBar(content: Text(loginErrorMessage(e))));
    } catch (e) {
      // A non-auth failure (e.g. the profile lookup) after sign-in would leave a
      // live but unverified session — sign it out so the gate can't be entered.
      await client.auth.signOut();
      debugPrint('Login failed: $e');
      rootMessengerKey.currentState
          ?.showSnackBar(SnackBar(content: Text(loginErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: BrandMark(size: 56)),
                    const SizedBox(height: 16),
                    Text('TampalPintar',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Text('Papan Pemuka Kerajaan — Selangor',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 28),
                    TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        validator: _validateEmail,
                        decoration: const InputDecoration(
                          labelText: 'E-mel',
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                        )),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: _password,
                        obscureText: !_showPassword,
                        autofillHints: const [AutofillHints.password],
                        validator: _validatePassword,
                        onFieldSubmitted: (_) => _busy ? null : _login(),
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
                            onPressed: () => setState(
                                () => _showPassword = !_showPassword),
                          ),
                        )),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: _busy ? null : _login,
                        child: _busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5))
                            : const Text('Log Masuk'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Akaun pihak berkuasa yang dibenarkan sahaja',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12, color: scheme.onSurfaceVariant)),
                  ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
