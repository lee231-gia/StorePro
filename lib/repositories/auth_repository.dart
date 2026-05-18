import 'dart:convert';

import '../core/services/auth_service.dart';
import '../core/services/firebase_service.dart';
import '../core/services/sqlite_service.dart';
import '../core/utils/app_helpers.dart';
import '../core/utils/session.dart';
import '../models/user_model.dart';

class AuthRepository {
  AuthRepository._();

  // ── SIGN UP ───────────────────────────────────────────────
  // Creates Firebase Auth account + Firestore store profile.
  static Future<String?> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String username,
    required String storeName,
    required String securityQuestion,
    required String securityAnswer,
  }) async {
    try {
      final normalizedUsername = username.trim().toLowerCase();

      // 1. Check username is unique. Before account creation this must only
      // read /usernames because /stores/{storeId} is private in Firestore.
      final usernameTaken = await _usernameTaken(
        normalizedUsername,
      ).timeout(FirebaseService.timeout, onTimeout: () => false);
      if (usernameTaken) return 'Username already taken.';

      // 2. Create Firebase Auth account
      final cred = await AuthService.signUp(email, password);
      if (cred == null) return 'Sign up failed.';

      final uid = cred.user!.uid;

      // 3. Build user model
      final user = UserModel(
        id: uid,
        email: email.trim(),
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        username: normalizedUsername,
        storeName: storeName.trim().isEmpty ? 'My Store' : storeName.trim(),
        securityQuestion: securityQuestion,
        securityAnswerHash: AppHelpers.hashPassword(
          securityAnswer.trim().toLowerCase(),
        ),
        createdAt: AppHelpers.nowStr(),
      );

      // 4. Save to Firestore (two places: stores doc + username index)
      await _cacheLocalProfile(user);
      FirebaseService.setGlobal('stores', uid, user.toMap()).ignore();
      FirebaseService.setGlobal('usernames', normalizedUsername, {
        'storeId': uid,
        'username': normalizedUsername,
        'email': email.trim(),
        'securityQuestion': securityQuestion,
        'securityAnswerHash': user.securityAnswerHash,
      }).ignore();

      // 5. Load session
      _loadSession(user);
      return null; // null = success
    } catch (e) {
      return e.toString();
    }
  }

  // ── LOGIN ─────────────────────────────────────────────────
  static Future<String?> login(String email, String password) async {
    try {
      final cred = await AuthService.login(email, password);
      if (cred == null) return 'Login failed.';

      final uid = cred.user!.uid;

      // Load the cached profile first so navigation never waits on Firestore.
      final localData = await _getLocalProfile(uid);
      if (localData != null) {
        final user = UserModel.fromMap(localData);
        _loadSession(user);
        _refreshLocalProfileFromFirebase(uid);
        return null;
      }

      // First login on a device may need one cloud read to seed SQLite.
      final data = await FirebaseService.getGlobal(
        'stores',
        uid,
      ).timeout(FirebaseService.timeout, onTimeout: () => null);
      if (data == null) {
        return 'Profile not found locally. Connect once to finish login.';
      }

      final user = UserModel.fromMap(data);
      await _cacheLocalProfile(user);
      _loadSession(user);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ── LOGOUT ────────────────────────────────────────────────
  static Future<void> logout() async {
    try {
      await AuthService.logout().timeout(const Duration(seconds: 6));
    } catch (_) {}
    Session.clear();
  }

  // ── FORGOT PASSWORD: STEP 1 — verify username ─────────────
  // Returns the security question if username found, else null.
  static Future<Map<String, dynamic>?> getSecurityQuestion(
    String username,
  ) async {
    final data = await _findByUsername(username.trim().toLowerCase());
    if (data == null) return null;
    return {
      'storeId': data['storeId'],
      'question': data['securityQuestion'] ?? '',
      'email': data['email'] ?? '',
    };
  }

  // ── FORGOT PASSWORD: STEP 2 — verify answer + send OTP ────
  // Returns OTP and reset email if answer correct, else null.
  // static Future<Map<String, String>?> verifySecurityAnswer({
  //   required String storeId,
  //   required String answer,
  //   String username = '',
  // }) async {
  //   final answerHash = AppHelpers.hashPassword(answer.trim().toLowerCase());
  //   if (username.trim().isNotEmpty) {
  //     final indexed = await _findByUsername(username.trim().toLowerCase());
  //     if (indexed != null &&
  //         indexed['storeId'] == storeId &&
  //         indexed['securityAnswerHash'] == answerHash) {
  //       final otp = await _saveOtp(storeId);
  //       return {'otp': otp, 'email': indexed['email'] ?? ''};
  //     }
  //   }
  //   final data = await FirebaseService.getGlobal(
  //     'stores',
  //     storeId,
  //   ).timeout(FirebaseService.timeout, onTimeout: () => null);
  //   if (data == null) return null;

  //   final user = UserModel.fromMap(data);

  //   if (answerHash != user.securityAnswerHash) return null;

  //   final otp = await _saveOtp(storeId);
  //   return {'otp': otp, 'email': user.email};
  // }

  // ── FORGOT PASSWORD: STEP 2 — verify answer + send OTP ────
  static Future<Map<String, String>?> verifySecurityAnswer({
    required String storeId,
    required String answer,
    String username = '',
  }) async {
    final answerHash = AppHelpers.hashPassword(answer.trim().toLowerCase());

    if (username.trim().isNotEmpty) {
      final indexed = await _findByUsername(username.trim().toLowerCase());

      if (indexed != null &&
          indexed['storeId'] == storeId &&
          indexed['securityAnswerHash'] == answerHash) {
        final otp = await _saveOtp(/*storeId*/);

        return {'otp': otp, 'email': indexed['email'] ?? ''};
      }
    }

    return null;
  }

  // ── FORGOT PASSWORD: STEP 3 — verify OTP ──────────────────
  // static Future<String?> verifyOtp(String storeId, String otp) async {
  //   final data = await FirebaseService.getGlobal(
  //     'stores',
  //     storeId,
  //   ).timeout(FirebaseService.timeout, onTimeout: () => null);
  //   if (data == null) return 'Account not found.';

  //   final user = UserModel.fromMap(data);

  //   if (user.otpCode != otp) return 'Incorrect OTP.';

  //   // Check expiry
  //   try {
  //     final expires = DateTime.parse(user.otpExpiresAt);
  //     if (DateTime.now().isAfter(expires)) return 'OTP expired.';
  //   } catch (_) {
  //     return 'OTP expired.';
  //   }

  //   return null; // null = valid
  // }

  // ── FORGOT PASSWORD: STEP 4 — reset password ──────────────
  static Future<String?> resetPassword(
    String storeId,
    String newPassword,
  ) async {
    try {
      // Clear OTP
      await FirebaseService.setGlobal('stores', storeId, {
        'otpCode': '',
        'otpExpiresAt': '',
      }).timeout(FirebaseService.timeout);
      await AuthService.updatePassword(newPassword);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  static Future<String?> sendPasswordResetEmail(String email) async {
    if (email.trim().isEmpty) {
      return 'Reset email is missing for this account. Ask the owner to sign in once or update the username index.';
    }
    try {
      await AuthService.sendPasswordResetEmail(email);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ── DELETE ACCOUNT ────────────────────────────────────────
  static Future<String?> deleteAccount() async {
    try {
      final uid = AuthService.currentUser?.uid;
      if (uid == null) return 'Not logged in.';

      // Remove username index
      final data = await FirebaseService.getGlobal(
        'stores',
        uid,
      ).timeout(FirebaseService.timeout, onTimeout: () => null);
      if (data != null) {
        final username = data['username'] as String? ?? '';
        if (username.isNotEmpty) {
          FirebaseService.setGlobal('usernames', username, {
            'deleted': true,
          }).ignore();
        }
      }

      await AuthService.deleteAccount();
      await SQLiteService.delete('store_profiles', uid);
      Session.clear();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ── LOAD SESSION ──────────────────────────────────────────
  static void _loadSession(UserModel user) {
    Session.storeId = user.id;
    Session.storeName = user.storeName;
    Session.ownerName = user.fullName;
    Session.ownerUsername = user.username;
    Session.ownerEmail = user.email;
    Session.trackActivity = user.trackActivity;
    Session.employeeFeature = user.employeeFeature;
  }

  static Future<bool> restoreLocalSession() async {
    try {
      final rows = await SQLiteService.query(
        'store_profiles',
        orderBy: 'updatedAt DESC',
        limit: 1,
      );
      if (rows.isEmpty) return false;
      final data = jsonDecode(rows.first['dataJson'] as String);
      if (data is! Map) return false;
      _loadSession(UserModel.fromMap(Map<String, dynamic>.from(data)));
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _cacheLocalProfile(UserModel user) async {
    await SQLiteService.upsert('store_profiles', {
      'id': user.id,
      'dataJson': jsonEncode(user.toMap()),
      'updatedAt': AppHelpers.nowStr(),
    });
  }

  static Future<void> updateCachedSessionProfile(
    Map<String, dynamic> changes,
  ) async {
    if (Session.storeId.isEmpty) return;
    final current = await _getLocalProfile(Session.storeId) ?? {};
    final data = {
      ...current,
      'id': Session.storeId,
      'email': Session.ownerEmail,
      ...changes,
    };
    await SQLiteService.upsert('store_profiles', {
      'id': Session.storeId,
      'dataJson': jsonEncode(data),
      'updatedAt': AppHelpers.nowStr(),
    });
  }

  static Future<Map<String, dynamic>?> _getLocalProfile(String id) async {
    try {
      final rows = await SQLiteService.query(
        'store_profiles',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      final data = jsonDecode(rows.first['dataJson'] as String);
      return data is Map ? Map<String, dynamic>.from(data) : null;
    } catch (_) {
      return null;
    }
  }

  static void _refreshLocalProfileFromFirebase(String uid) async {
    try {
      final data = await FirebaseService.getGlobal(
        'stores',
        uid,
      ).timeout(FirebaseService.timeout, onTimeout: () => null);
      if (data == null) return;
      await _cacheLocalProfile(UserModel.fromMap(data));
    } catch (_) {}
  }

  // ── USERNAME LOOKUP ───────────────────────────────────────
  static Future<bool> _usernameTaken(String username) async {
    final index = await FirebaseService.getGlobal(
      'usernames',
      username,
    ).timeout(FirebaseService.timeout, onTimeout: () => null);
    return index != null && index['deleted'] != true;
  }

  static Future<Map<String, dynamic>?> _findByUsername(String username) async {
    // Check username index
    final index = await FirebaseService.getGlobal(
      'usernames',
      username,
    ).timeout(FirebaseService.timeout, onTimeout: () => null);
    if (index == null || index['deleted'] == true) return null;

    final storeId = index['storeId'] as String;
    if ((index['securityAnswerHash'] as String? ?? '').isNotEmpty ||
        (index['securityQuestion'] as String? ?? '').isNotEmpty) {
      return {
        'storeId': storeId,
        'email': index['email'] ?? '',
        'securityQuestion': index['securityQuestion'] ?? '',
        'securityAnswerHash': index['securityAnswerHash'] ?? '',
      };
    }
    final store = await FirebaseService.getGlobal(
      'stores',
      storeId,
    ).timeout(FirebaseService.timeout, onTimeout: () => null);
    if (store == null) return null;

    return {
      'storeId': storeId,
      'email': store['email'] ?? index['email'] ?? '',
      'securityQuestion': store['securityQuestion'] ?? '',
      'securityAnswerHash': store['securityAnswerHash'] ?? '',
    };
  }

  static Future<String> _saveOtp(/*String storeId*/) async {
    final otp = AppHelpers.generateOtp();
    // final expires = DateTime.now()
    //     .add(const Duration(minutes: 10))
    //     .toIso8601String();

    // try {
    //   await FirebaseService.setGlobal('stores', storeId, {
    //     'otpCode': otp,
    //     'otpExpiresAt': expires,
    //   }).timeout(FirebaseService.timeout);
    // } catch (_) {
    //   // The local flow can still verify the OTP shown on screen. Firestore
    //   // persistence is best effort because unauthenticated rules may block it.
    // }

    return otp;
  }
}
