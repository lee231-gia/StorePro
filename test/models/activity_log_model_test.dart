import 'package:flutter_test/flutter_test.dart';
import 'package:storepro/models/activity_log_model.dart';

void main() {
  group('ActivityLogModel', () {
    test('fromMap and toMap roundtrip with details map', () {
      const original = ActivityLogModel(
        id: 'log_001',
        storeId: 'store_001',
        employeeId: 'emp_001',
        employeeName: 'Maria Santos',
        action: 'new_sale',
        targetType: 'sale',
        targetId: 'sale_001',
        targetName: 'Sale to Juan Dela Cruz',
        timestamp: '2026-06-15T14:30:00.000',
        details: {'total': 115.00, 'items_count': 2},
      );
      final map = original.toMap();
      final restored = ActivityLogModel.fromMap(map);
      expect(restored.action, equals('new_sale'));
      expect(restored.employeeName, equals('Maria Santos'));
      expect(restored.details['total'], equals(115.00));
      expect(restored.details['items_count'], equals(2));
    });

    test('fromMap parses detailsJson string when details is absent', () {
      final result = ActivityLogModel.fromMap({
        'id': 'log_002',
        'storeId': 'store_001',
        'employeeId': 'emp_001',
        'employeeName': 'Juan Dela Cruz',
        'action': 'add_product',
        'targetType': 'product',
        'targetId': 'prod_001',
        'targetName': 'Coca-Cola 1L',
        'timestamp': '2026-06-15T15:00:00.000',
        'detailsJson': '{"price": 25.00, "category": "Beverages"}',
      });
      expect(result.details['price'], equals(25.00));
      expect(result.details['category'], equals('Beverages'));
    });

    test('fromMap returns empty details when both details and detailsJson are missing', () {
      final result = ActivityLogModel.fromMap({
        'id': 'log_003',
        'storeId': 'store_001',
        'employeeId': 'emp_001',
        'employeeName': 'Pedro Reyes',
        'action': 'login',
        'targetType': 'auth',
        'targetId': '',
        'targetName': '',
        'timestamp': '2026-06-15T08:00:00.000',
      });
      expect(result.details, isEmpty);
    });

    test('fromMap parses detailsJson when details is null', () {
      final result = ActivityLogModel.fromMap({
        'id': 'log_004',
        'storeId': 'store_001',
        'employeeId': 'emp_001',
        'employeeName': 'Maria Santos',
        'action': 'edit_product',
        'targetType': 'product',
        'targetId': 'prod_001',
        'targetName': 'Mountain Dew',
        'timestamp': '2026-06-15T16:00:00.000',
        'detailsJson': '{"price_old": 25.00, "price_new": 28.00}',
      });
      expect(result.details['price_old'], equals(25.00));
      expect(result.details['price_new'], equals(28.00));
    });

    test('fromMap handles malformed detailsJson gracefully', () {
      final result = ActivityLogModel.fromMap({
        'id': 'log_005',
        'storeId': 'store_001',
        'employeeId': 'emp_001',
        'employeeName': 'Test',
        'action': 'test',
        'targetType': 'test',
        'targetId': '',
        'targetName': '',
        'timestamp': '2026-06-15T00:00:00.000',
        'detailsJson': '{invalid json}',
      });
      expect(result.details, isEmpty);
    });

    test('toMap includes both details and detailsJson', () {
      const log = ActivityLogModel(
        id: 'log_006',
        storeId: 'store_001',
        employeeId: 'emp_001',
        employeeName: 'Maria Santos',
        action: 'delete_product',
        targetType: 'product',
        targetId: 'prod_002',
        targetName: 'Expired Item',
        timestamp: '2026-06-15T17:00:00.000',
        details: {'reason': 'expired'},
      );
      final map = log.toMap();
      expect(map['details'], isA<Map>());
      expect(map['detailsJson'], isA<String>());
      expect(map['details']['reason'], equals('expired'));
    });
  });
}
