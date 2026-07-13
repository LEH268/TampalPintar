import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_gate.dart';
import 'config.dart';
import 'session_state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ms'); // tarikh dalam Bahasa Malaysia
  await Supabase.initialize(url: kSupabaseUrl, anonKey: kSupabaseAnonKey);
  runApp(const GovApp());
}

class GovApp extends StatelessWidget {
  const GovApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'TampalPintar Kerajaan',
        scaffoldMessengerKey: rootMessengerKey,
        theme: buildGovTheme(),
        home: const AuthGate(),
      );
}
