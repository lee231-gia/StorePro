import 'package:flutter_test/flutter_test.dart';
import 'package:storepro/models/customer_model.dart';

void main() {
  group('CustomerModel', () {
    test('fromMap and toMap roundtrip correctly', () {
      const original = CustomerModel(
        id: 'cust_001',
        storeId: 'store_001',
        name: 'Juan Dela Cruz',
        phone: '09171234567',
        address: '123 Rizal Street, Manila',
        notes: 'Regular customer, prefers delivery',
        totalPurchases: 1250.75,
        createdAt: '2026-01-15',
        updatedAt: '2026-06-20',
      );
      final map = original.toMap();
      final restored = CustomerModel.fromMap(map);
      expect(restored.name, equals('Juan Dela Cruz'));
      expect(restored.phone, equals('09171234567'));
      expect(restored.totalPurchases, equals(1250.75));
    });

    test('fromMap uses defaults when keys are missing', () {
      final result = CustomerModel.fromMap({
        'id': 'c1', 'storeId': 's1', 'name': 'Test',
        'createdAt': '', 'updatedAt': '',
      });
      expect(result.phone, equals(''));
      expect(result.address, equals(''));
      expect(result.totalPurchases, equals(0.0));
    });

    test('toSql returns same as toMap', () {
      const customer = CustomerModel(
        id: 'cust_002', storeId: 'store_001', name: 'Maria Santos',
        createdAt: '2026-02-01', updatedAt: '2026-06-01',
      );
      expect(customer.toSql(), equals(customer.toMap()));
    });

    test('copyWith updates only specified fields', () {
      const customer = CustomerModel(
        id: 'cust_001', storeId: 'store_001', name: 'Juan',
        createdAt: '2026-01-01', updatedAt: '2026-06-01',
      );
      final copied = customer.copyWith(name: 'Juan Dela Cruz Jr.', phone: '09179876543');
      expect(copied.name, equals('Juan Dela Cruz Jr.'));
      expect(copied.phone, equals('09179876543'));
      expect(copied.id, equals('cust_001'));
      expect(copied.totalPurchases, equals(0.0));
    });
  });
}
