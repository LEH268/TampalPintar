import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';
import '../session_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
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
            'Citizen accounts cannot access the government dashboard.');
      }
      govRoleVerified.value = true; // auth gate swaps to the dashboard
    } on AuthException catch (e) {
      rootMessengerKey.currentState
          ?.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      // A non-auth failure (e.g. the profile lookup) after sign-in would leave a
      // live but unverified session — sign it out so the gate can't be entered.
      await client.auth.signOut();
      rootMessengerKey.currentState
          ?.showSnackBar(SnackBar(content: Text('Sign-in failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: SizedBox(
            width: 380,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_balance, size: 56, color: Colors.red),
                const Text('TampalPintar — Government',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                TextField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: 'Email')),
                TextField(
                    controller: _password,
                    obscureText: true,
                    onSubmitted: (_) => _login(),
                    decoration: const InputDecoration(labelText: 'Password')),
                const SizedBox(height: 16),
                FilledButton(
                    onPressed: _busy ? null : _login,
                    child: const Text('Log in')),
              ],
            ),
          ),
        ),
      );
}
