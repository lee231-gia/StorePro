import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:storepro/core/services/sqlite_service.dart';
import 'package:storepro/core/utils/session.dart';

Future<void> initRepositories() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

Future<void> setupRepositories() async {
  SQLiteService.reset();
  Session.clear();
  Session.storeId = 'test-store-1';
  Session.storeName = 'Test Store';
  Session.trackActivity = false;
  await SQLiteService.init();
}
