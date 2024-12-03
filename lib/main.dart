import 'package:card_fusion/screens/auth/login_screen.dart';
import 'package:card_fusion/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load();

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const CardFusion());
}

class CardFusion extends StatelessWidget {
  const CardFusion({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }

          if (snapshot.hasError) {
            return const LoginScreen();
          }

          if (snapshot.hasData) {
            final authState = snapshot.data!;
            
            // Handle different auth states
            switch (authState.event) {
              case AuthChangeEvent.signedIn:
                if (authState.session != null) {
                  return const HomeScreen();
                }
                break;
              case AuthChangeEvent.signedOut:
              case AuthChangeEvent.userDeleted:
                return const LoginScreen();
              default:
                break;
            }
          }

          // Default to login screen if no other conditions are met
          return const LoginScreen();
        },
      ),
    );
  }
}
