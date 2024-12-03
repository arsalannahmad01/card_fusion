import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show debugPrint;

class SupabaseService {
  final _supabase = Supabase.instance.client;
  
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId: Platform.isIOS
        ? '133282886935-7pgodcdhrig3dqd9ojaodpkevmehbd09.apps.googleusercontent.com'
        : null,
    serverClientId: '133282886935-7pgodcdhrig3dqd9ojaodpkevmehbd09.apps.googleusercontent.com'
  );

  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<bool> signInWithGoogle() async {
    try {
      debugPrint('Starting Google Sign In...');
      
      // Clear any existing sign in
      await _googleSignIn.signOut();
      await _supabase.auth.signOut();
      
      // Trigger Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('Sign in cancelled by user');
        return false;
      }

      debugPrint('Getting auth tokens...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.idToken == null) {
        debugPrint('No ID token received');
        return false;
      }

      debugPrint('Signing in to Supabase with ID token...');
      final response = await _supabase.auth.signInWithIdToken(
        provider: Provider.google,
        idToken: googleAuth.idToken!,
      );

      final success = response.session != null;
      debugPrint('Sign in ${success ? 'successful' : 'failed'}: ${response.user?.id}');
      return success;
    } catch (e) {
      debugPrint('Error in signInWithGoogle: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      debugPrint('Signing out...');
      await Future.wait([
        _googleSignIn.signOut(),
        _supabase.auth.signOut(),
      ]);
      debugPrint('Sign out successful');
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }
}
