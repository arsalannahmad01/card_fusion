import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'dart:io' show Platform;

class SupabaseService {
  final _supabase = Supabase.instance.client;

  // For iOS, we need specific configuration
  final GoogleSignIn _googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      clientId: Platform.isIOS
          ? '133282886935-7pgodcdhrig3dqd9ojaodpkevmehbd09.apps.googleusercontent.com'
          : null,
      serverClientId:
          '133282886935-7pgodcdhrig3dqd9ojaodpkevmehbd09.apps.googleusercontent.com');

  Future<bool> signInWithGoogle() async {
    print("Google Sign In: ${_googleSignIn}");
    try {
      // Clear any existing sign in first
      await _googleSignIn.signOut();

      debugPrint('Starting Google Sign In...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('Sign in cancelled by user');
        return false;
      }

      print(googleUser);

      debugPrint('Getting auth tokens...');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null) {
        debugPrint('No ID token received');
        return false;
      }

      debugPrint('Signing in to Supabase...');
      final response = await _supabase.auth.signInWithIdToken(
        provider: Provider.google,
        idToken: googleAuth.idToken!,
      );

      final success = response.session != null;
      debugPrint('Sign in ${success ? 'successful' : 'failed'}');
      return success;
    } catch (e) {
      debugPrint('Sign in error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  bool get isAuthenticated => _supabase.auth.currentUser != null;
  User? get currentUser => _supabase.auth.currentUser;
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
