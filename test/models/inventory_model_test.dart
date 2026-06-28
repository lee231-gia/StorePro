import 'package:flutter_test/flutter_test.dart';
import 'package:storepro/models/inventory_model.dart';

void main() {
  group('InventoryLogModel', () {
    test('fromMap and toMap roundtrip for add type', () {
      const original = InventoryLogModel(
        id: 'log_001',
        storeId: 'store_001',
        productId: 'prod_001',
        productName: 'Coca-Cola 1L',
        variantId: 'v_001',
        variantName: 'Liter Solo',
        type: 'add',
        qty: 50,
        costPrice: 15.00,
        reason: 'replenishment',
        employeeId: 'emp_001',
        employeeName: 'Maria Santos',
        date: '2026-06-15',
        updatedAt: '2026-06-15T10:00:00',
      );
      final map = original.toMap();
      final restored = InventoryLogModel.fromMap(map);
      expect(restored.type, equals('add'));
      expect(restored.qty, equals(50));
      expect(restored.reason, equals('replenishment'));
      expect(restored.employeeName, equals('Maria Santos'));
    });

    test('fromMap roundtrip for all log types', () {
      const types = ['add', 'remove', 'waste', 'loss', 'adjustment', 'sale'];
      for (final type in types) {
        final log = InventoryLogModel(
          id: 'log_${type}',
          storeId: 'store_001',
          productId: 'prod_001',
          productName: 'Test Product',
          variantId: 'v_001',
          variantName: 'Test Variant',
          type: type,
          qty: type == 'add' ? 10 : -5,
          reason: type == 'waste' ? 'damage' : type == 'loss' ? 'missing' : type == 'sale' ? 'sale' : 'replenishment',
          date: '2026-06-15',
          updatedAt: '2026-06-15T10:00:00',
        );
        final map = log.toMap();
        final restored = InventoryLogModel.fromMap(map);
        expect(restored.type, equals(type));
      }
    });

    test('fromMap uses defaults when keys are missing', () {
      final result = InventoryLogModel.fromMap({
        'id': 'l1', 'storeId': 's1', 'productId': 'p1', 'productName': 'P',
        'variantId': 'v1', 'variantName': 'V', 'type': 'add', 'qty': 0,
        'date': '', 'updatedAt': '',
      });
      expect(result.costPrice, equals(0.0));
      expect(result.reason, equals(''));
      expect(result.employeeName, equals(''));
    });

    test('toSql returns same as toMap', () {
      const log = InventoryLogModel(
        id: 'log_002', storeId: 'store_001',
        productId: 'prod_001', productName: 'Test',
        variantId: 'v_001', variantName: 'V',
        type: 'remove', qty: -10, reason: 'damage',
        date: '2026-06-15', updatedAt: '2026-06-15T10:00:00',
      );
      expect(log.toSql(), equals(log.toMap()));
    });
  });
}
