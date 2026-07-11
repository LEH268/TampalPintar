import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'session_state.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';

/// Shows the dashboard only when a session exists AND the login flow has
/// confirmed a government role. A citizen's transient post-signin session
/// (before signOut completes) therefore never mounts the dashboard subtree.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<AuthState>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      // Any end of session revokes the verified-role flag.
      if (data.session == null) govRoleVerified.value = false;
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
        valueListenable: govRoleVerified,
        builder: (context, verified, _) {
          final hasSession =
              Supabase.instance.client.auth.currentSession != null;
          return (hasSession && verified)
              ? const DashboardScreen()
              : const LoginScreen();
        },
      );
}
