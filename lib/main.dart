import 'package:flutter/material.dart';

import 'app.dart';
import 'core/services/firebase_service.dart';
import 'core/services/sqlite_service.dart';
import 'repositories/auth_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await SQLiteService.init().timeout(
      const Duration(seconds: 5),
      onTimeout: () {},
    );
    await AuthRepository.restoreLocalSession().timeout(
      const Duration(seconds: 2),
      onTimeout: () => false,
    );
  } catch (_) {
    // Local boot must never prevent the app shell from rendering.
  }

  runApp(const StorePro(localBootstrapped: true));

  FirebaseService.ensureInitialized()
      .timeout(const Duration(seconds: 8), onTimeout: () {})
      .ignore();
}
