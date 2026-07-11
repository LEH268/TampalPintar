import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: kSupabaseUrl, anonKey: kSupabaseAnonKey);
  runApp(const TampalPintarApp());
}

class TampalPintarApp extends StatelessWidget {
  const TampalPintarApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'TampalPintar',
        theme: ThemeData(colorSchemeSeed: Colors.red, useMaterial3: true),
        home: StreamBuilder<AuthState>(
          stream: Supabase.instance.client.auth.onAuthStateChange,
          builder: (context, _) =>
              Supabase.instance.client.auth.currentSession == null
                  ? const LoginScreen()
                  : const HomeShell(),
        ),
      );
}
