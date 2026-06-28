import 'package:flutter_test/flutter_test.dart';
import 'package:storepro/core/utils/session.dart';

void main() {
  setUp(() {
    Session.clear();
  });

  group('Session', () {
    test('clear resets all fields to defaults', () {
      Session.storeId = 'store_001';
      Session.storeName = 'Juan\'s Sari-Sari Store';
      Session.ownerName = 'Juan Dela Cruz';
      Session.activeEmployeeId = 'emp_001';
      Session.activeEmployeeName = 'Maria Santos';
      Session.employeeSelected = true;
      Session.isOnline = false;

      Session.clear();

      expect(Session.storeId, equals(''));
      expect(Session.storeName, equals(''));
      expect(Session.ownerName, equals(''));
      expect(Session.activeEmployeeId, equals(''));
      expect(Session.activeEmployeeName, equals(''));
      expect(Session.trackActivity, isTrue);
      expect(Session.notificationsEnabled, isTrue);
      expect(Session.employeeFeature, isFalse);
      expect(Session.employeeSelected, isFalse);
      expect(Session.isOnline, isTrue);
    });

    test('default values after clear', () {
      expect(Session.storeId, equals(''));
      expect(Session.storeName, equals(''));
      expect(Session.ownerName, equals(''));
      expect(Session.trackActivity, isTrue);
      expect(Session.notificationsEnabled, isTrue);
      expect(Session.employeeFeature, isFalse);
      expect(Session.isOnline, isTrue);
      expect(Session.employeeSelected, isFalse);
    });

    test('safeEmployeeId returns "owner" when no active employee', () {
      Session.activeEmployeeId = '';
      expect(Session.safeEmployeeId, equals('owner'));
    });

    test('safeEmployeeId returns activeEmployeeId when set', () {
      Session.activeEmployeeId = 'emp_001';
      expect(Session.safeEmployeeId, equals('emp_001'));
    });

    test('safeEmployeeName returns active employee name when set', () {
      Session.activeEmployeeName = '  Maria Santos  ';
      expect(Session.safeEmployeeName, equals('Maria Santos'));
    });

    test('safeEmployeeName returns ownerName when no active employee name', () {
      Session.activeEmployeeName = '';
      Session.ownerName = 'Juan Dela Cruz';
      expect(Session.safeEmployeeName, equals('Juan Dela Cruz'));
    });

    test('safeEmployeeName returns "Owner" when both names are empty', () {
      expect(Session.safeEmployeeName, equals('Owner'));
    });

    test('fields are mutable and persist after assignment', () {
      Session.storeId = 'store_002';
      Session.storeName = 'Maria\'s Store';
      Session.ownerName = 'Maria Santos';
      Session.ownerEmail = 'maria@example.com';
      Session.isOnline = false;
      Session.employeeFeature = true;

      expect(Session.storeId, equals('store_002'));
      expect(Session.storeName, equals('Maria\'s Store'));
      expect(Session.ownerName, equals('Maria Santos'));
      expect(Session.ownerEmail, equals('maria@example.com'));
      expect(Session.isOnline, isFalse);
      expect(Session.employeeFeature, isTrue);
    });
  });
}
