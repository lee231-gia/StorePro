import 'package:flutter/material.dart';

import 'app.dart';
import 'core/services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const StorePro());

  FirebaseService.ensureInitialized()
      .timeout(const Duration(seconds: 8), onTimeout: () {})
      .ignore();
}
