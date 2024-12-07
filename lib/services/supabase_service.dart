import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../utils/error_handler.dart';

class SupabaseService {
  final _supabase = Supabase.instance.client;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
      // scopes: ['email', 'profile'],
      clientId:
          '133282886935-7pgodcdhrig3dqd9ojaodpkevmehbd09.apps.googleusercontent.com',
      serverClientId:
          '133282886935-gltcf4j106lh7ipugcr4dk1a6hdlvp7e.apps.googleusercontent.com');

  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<bool> signInWithGoogle() async {
    try {
      debugPrint('Starting Google Sign In...');

      await _googleSignIn.signOut();
      await _supabase.auth.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw AppError(
          message: 'Sign in was cancelled',
          type: ErrorType.authentication,
        );
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null) {
        throw AppError(
          message: 'Failed to get authentication token',
          type: ErrorType.authentication,
        );
      }

      final response = await _supabase.auth.signInWithIdToken(
        provider: Provider.google,
        idToken: googleAuth.idToken!,
      );

      if (response.session == null) {
        throw AppError(
          message: 'Failed to authenticate with server',
          type: ErrorType.authentication,
        );
      }

      return true;
    } catch (e, stackTrace) {
      if (e is AppError) rethrow;
      throw AppError(
        message: 'Failed to sign in with Google',
        type: ErrorType.authentication,
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> signOut() async {
    try {
      await Future.wait([
        _googleSignIn.signOut(),
        _supabase.auth.signOut(),
      ]);
    } catch (e, stackTrace) {
      throw AppError(
        message: 'Failed to sign out',
        type: ErrorType.authentication,
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}
