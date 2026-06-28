import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';

class AuthService {
  AuthService._();
  static FirebaseAuth get _auth => FirebaseAuth.instance;
  static const Duration _timeout = Duration(seconds: 12);

  // ── CURRENT USER ──────────────────────────────────────────
  static User? get currentUser => _auth.currentUser;
  static bool get isLoggedIn => currentUser != null;
  static Stream<User?> get authStream => _auth.authStateChanges();

  // ── SIGN UP ───────────────────────────────────────────────
  static Future<UserCredential?> signUp(String email, String password) async {
    try {
      await FirebaseService.ensureInitialized().timeout(_timeout);
      return await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          )
          .timeout(_timeout);
    } on FirebaseAuthException catch (e) {
      debugPrint('FIREBASE AUTH CODE: ${e.code}');
      debugPrint('FIREBASE AUTH MESSAGE: ${e.message}');
      throw _authError(e.code);
    } on TimeoutException {
      throw 'Authentication timed out. Check your connection and try again.';
    }
  }

  // ── LOGIN ─────────────────────────────────────────────────
  static Future<UserCredential?> login(String email, String password) async {
    try {
      await FirebaseService.ensureInitialized().timeout(_timeout);
      return await _auth
          .signInWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          )
          .timeout(_timeout);
    } on FirebaseAuthException catch (e) {
      debugPrint('FIREBASE AUTH CODE: ${e.code}');
      debugPrint('FIREBASE AUTH MESSAGE: ${e.message}');
      throw _authError(e.code);
    } on TimeoutException {
      throw 'Authentication timed out. Check your connection and try again.';
    }
  }
  // ── LOGOUT ────────────────────────────────────────────────
  static Future<void> logout() async {
    await FirebaseService.ensureInitialized().timeout(_timeout);
    await _auth.signOut().timeout(_timeout);
  }

  // ── DELETE ACCOUNT ────────────────────────────────────────
  static Future<void> deleteAccount() async {
    await FirebaseService.ensureInitialized().timeout(_timeout);
    final user = currentUser;
    if (user != null) await user.delete().timeout(_timeout);
  }

  // ── UPDATE PASSWORD ───────────────────────────────────────
  static Future<void> updatePassword(String newPassword) async {
    await FirebaseService.ensureInitialized().timeout(_timeout);
    final user = currentUser;
    if (user == null) {
      throw 'No signed-in user. Use the email reset link to change this password.';
    }
    await user.updatePassword(newPassword).timeout(_timeout);
  }

  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await FirebaseService.ensureInitialized().timeout(_timeout);
      await _auth
          .sendPasswordResetEmail(email: email.trim())
          .timeout(_timeout);
    } on FirebaseAuthException catch (e) {
      throw _authError(e.code);
    } on TimeoutException {
      throw 'Password reset timed out. Check your connection and try again.';
    }
  }

  // ── ERROR MAPPER ──────────────────────────────────────────
  static String _authError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'Email already registered.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Invalid email address.';
      default:
        return 'Authentication error. Try again.';
    }
  }
}
