import 'package:flutter_test/flutter_test.dart';
import 'package:storepro/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('fullName combines firstName and lastName', () {
      const user = UserModel(
        id: 'user_001',
        email: 'juan.delacruz@example.com',
        firstName: 'Juan',
        lastName: 'Dela Cruz',
        username: 'juandelacruz',
        storeName: 'Juan\'s Sari-Sari Store',
        createdAt: '2026-01-01',
      );
      expect(user.fullName, equals('Juan Dela Cruz'));
    });

    test('fullName trims trailing space when lastName is empty', () {
      const user = UserModel(
        id: 'user_002',
        email: 'maria@example.com',
        firstName: 'Maria',
        lastName: '',
        username: 'maria',
        storeName: 'Maria\'s Store',
        createdAt: '2026-02-01',
      );
      expect(user.fullName, equals('Maria'));
    });

    test('fromMap and toMap roundtrip correctly', () {
      const original = UserModel(
        id: 'user_001',
        email: 'juan.delacruz@example.com',
        firstName: 'Juan',
        lastName: 'Dela Cruz',
        username: 'juandelacruz',
        storeName: 'Juan\'s Sari-Sari Store',
        avatarColorIndex: '3',
        securityQuestion: 'What is your pet\'s name?',
        securityAnswerHash: 'a1b2c3d4e5f6...',
        otpCode: '482916',
        otpExpiresAt: '2026-06-28T12:00:00',
        trackActivity: true,
        notificationsEnabled: true,
        employeeFeature: false,
        createdAt: '2026-01-01',
      );
      final map = original.toMap();
      final restored = UserModel.fromMap(map);
      expect(restored.fullName, equals('Juan Dela Cruz'));
      expect(restored.storeName, equals('Juan\'s Sari-Sari Store'));
      expect(restored.otpCode, equals('482916'));
      expect(restored.trackActivity, isTrue);
      expect(restored.employeeFeature, isFalse);
    });

    test('fromMap uses defaults when keys are missing', () {
      final result = UserModel.fromMap({
        'id': 'u1', 'email': 't@t.com', 'firstName': 'T', 'lastName': 'U',
        'username': 'tu', 'storeName': 'TS', 'createdAt': '',
      });
      expect(result.avatarColorIndex, equals('0'));
      expect(result.trackActivity, isTrue);
      expect(result.employeeFeature, isTrue);
    });

    test('fromMap reads boolean flags correctly when false', () {
      final result = UserModel.fromMap({
        'id': 'u2', 'email': 't@t.com', 'firstName': 'A', 'lastName': 'B',
        'username': 'ab', 'storeName': 'S', 'createdAt': '',
        'trackActivity': false, 'notificationsEnabled': false, 'employeeFeature': false,
      });
      expect(result.trackActivity, isFalse);
      expect(result.notificationsEnabled, isFalse);
      expect(result.employeeFeature, isFalse);
    });

    test('copyWith updates only specified fields', () {
      const user = UserModel(
        id: 'user_001', email: 'j@j.com', firstName: 'Juan', lastName: 'DC',
        username: 'jdc', storeName: 'Store', createdAt: '2026-01-01',
      );
      final copied = user.copyWith(storeName: 'Juan\'s New Store', otpCode: '123456');
      expect(copied.storeName, equals('Juan\'s New Store'));
      expect(copied.otpCode, equals('123456'));
      expect(copied.firstName, equals('Juan'));
    });

    test('OTP expiry fields serialize correctly', () {
      const user = UserModel(
        id: 'user_003', email: 'a@b.com', firstName: 'A', lastName: 'B',
        username: 'ab', storeName: 'S', otpCode: '', otpExpiresAt: '',
        createdAt: '2026-01-01',
      );
      final map = user.toMap();
      expect(map['otpCode'], equals(''));
      expect(map['otpExpiresAt'], equals(''));
    });

    test('security fields serialize correctly', () {
      const user = UserModel(
        id: 'user_004', email: 'a@b.com', firstName: 'A', lastName: 'B',
        username: 'ab', storeName: 'S',
        securityQuestion: 'What is your mother\'s maiden name?',
        securityAnswerHash: 'sha256hashvalue',
        createdAt: '2026-01-01',
      );
      final map = user.toMap();
      expect(map['securityQuestion'], equals('What is your mother\'s maiden name?'));
      expect(map['securityAnswerHash'], equals('sha256hashvalue'));
    });
  });
}
