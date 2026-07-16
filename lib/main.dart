import 'package:flutter/material.dart';

import 'app.dart';
import 'core/services/firebase_service.dart';
import 'core/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final themeProvider = ThemeProvider();
  runApp(StorePro(themeProvider: themeProvider));

  FirebaseService.ensureInitialized()
      .timeout(const Duration(seconds: 8), onTimeout: () {})
      .ignore();
}
