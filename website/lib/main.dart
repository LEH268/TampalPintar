import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_gate.dart';
import 'config.dart';
import 'session_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: kSupabaseUrl, anonKey: kSupabaseAnonKey);
  runApp(const GovApp());
}

class GovApp extends StatelessWidget {
  const GovApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'TampalPintar Government',
        scaffoldMessengerKey: rootMessengerKey,
        theme: ThemeData(colorSchemeSeed: Colors.red, useMaterial3: true),
        home: const AuthGate(),
      );
}
