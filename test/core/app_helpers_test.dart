import 'package:flutter_test/flutter_test.dart';
import 'package:storepro/core/utils/app_helpers.dart';

void main() {
  group('AppHelpers.formatDate', () {
    test('formats valid ISO date to MMM d, yyyy', () {
      expect(AppHelpers.formatDate('2026-06-15'), equals('Jun 15, 2026'));
    });

    test('returns "No date" for empty string', () {
      expect(AppHelpers.formatDate(''), equals('No date'));
    });

    test('returns raw string for unparseable date', () {
      expect(AppHelpers.formatDate('not-a-date'), equals('not-a-date'));
    });

    test('formats date with single-digit day', () {
      expect(AppHelpers.formatDate('2026-01-05'), equals('Jan 5, 2026'));
    });
  });

  group('AppHelpers.peso', () {
    test('formats positive amount with peso sign and 2 decimals', () {
      expect(AppHelpers.peso(115.00), equals('₱115.00'));
    });

    test('formats zero amount', () {
      expect(AppHelpers.peso(0), equals('₱0.00'));
    });

    test('formats large amount with no commas', () {
      expect(AppHelpers.peso(25000.50), equals('₱25000.50'));
    });
  });

  group('AppHelpers.daysLeft', () {
    test('returns 999 for empty expiry', () {
      expect(AppHelpers.daysLeft(''), equals(999));
    });

    test('returns 999 for invalid date string', () {
      expect(AppHelpers.daysLeft('invalid'), equals(999));
    });
  });

  group('AppHelpers.expiryStatus', () {
    test('returns "good" for empty expiry', () {
      expect(AppHelpers.expiryStatus(''), equals('good'));
    });
  });

  group('AppHelpers.hashPassword', () {
    test('returns consistent SHA-256 hash for same input', () {
      final hash1 = AppHelpers.hashPassword('MyStore@123');
      final hash2 = AppHelpers.hashPassword('MyStore@123');
      expect(hash1, equals(hash2));
    });

    test('returns different hash for different passwords', () {
      final hash1 = AppHelpers.hashPassword('password123');
      final hash2 = AppHelpers.hashPassword('password456');
      expect(hash1, isNot(equals(hash2)));
    });

    test('returns 64-character hex string', () {
      final hash = AppHelpers.hashPassword('test');
      expect(hash.length, equals(64));
      expect(hash, matches(RegExp(r'^[a-f0-9]+$')));
    });
  });

  group('AppHelpers.generateOtp', () {
    test('generates 6-digit string by default', () {
      final otp = AppHelpers.generateOtp();
      expect(otp.length, equals(6));
      expect(otp, matches(RegExp(r'^\d{6}$')));
    });

    test('generates OTP of requested length', () {
      final otp = AppHelpers.generateOtp(length: 8);
      expect(otp.length, equals(8));
      expect(otp, matches(RegExp(r'^\d{8}$')));
    });
  });

  group('AppHelpers.stockStatus', () {
    test('returns "no_stock" when qty is 0', () {
      expect(AppHelpers.stockStatus(0), equals('no_stock'));
    });

    test('returns "low" when qty is between 1 and 10', () {
      expect(AppHelpers.stockStatus(1), equals('low'));
      expect(AppHelpers.stockStatus(5), equals('low'));
      expect(AppHelpers.stockStatus(10), equals('low'));
    });

    test('returns "good" when qty is above 10', () {
      expect(AppHelpers.stockStatus(11), equals('good'));
      expect(AppHelpers.stockStatus(100), equals('good'));
    });
  });

  group('AppHelpers.calcProfit', () {
    test('computes (sellPrice - costPrice) * qty', () {
      expect(AppHelpers.calcProfit(25.00, 15.00, 3), equals(30.00));
    });

    test('returns 0 when sellPrice equals costPrice', () {
      expect(AppHelpers.calcProfit(20.00, 20.00, 5), equals(0.00));
    });

    test('returns negative when selling below cost', () {
      expect(AppHelpers.calcProfit(10.00, 15.00, 2), equals(-10.00));
    });

    test('returns 0 when qty is 0', () {
      expect(AppHelpers.calcProfit(25.00, 15.00, 0), equals(0.00));
    });
  });

  group('AppHelpers.validateNotEmpty', () {
    test('returns null for non-empty string', () {
      expect(AppHelpers.validateNotEmpty('Juan Dela Cruz', 'Name'), isNull);
    });

    test('returns error message for null', () {
      expect(AppHelpers.validateNotEmpty(null, 'Name'), equals('Name is required.'));
    });

    test('returns error message for empty string', () {
      expect(AppHelpers.validateNotEmpty('', 'Name'), equals('Name is required.'));
    });

    test('returns error message for whitespace-only string', () {
      expect(AppHelpers.validateNotEmpty('   ', 'Name'), equals('Name is required.'));
    });
  });

  group('AppHelpers.validatePassword', () {
    test('returns null for password with 6+ characters', () {
      expect(AppHelpers.validatePassword('MyStore@123'), isNull);
    });

    test('returns error for null password', () {
      expect(AppHelpers.validatePassword(null), equals('Password must be at least 6 characters.'));
    });

    test('returns error for password shorter than 6 characters', () {
      expect(AppHelpers.validatePassword('Abc12'), equals('Password must be at least 6 characters.'));
    });

    test('returns null for exactly 6 characters', () {
      expect(AppHelpers.validatePassword('Abc123'), isNull);
    });
  });
}
