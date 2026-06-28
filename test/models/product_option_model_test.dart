import 'package:flutter_test/flutter_test.dart';
import 'package:storepro/models/product_option_model.dart';

void main() {
  group('ProductOptionModel', () {
    test('fromMap and toMap roundtrip for UOM option', () {
      const original = ProductOptionModel(
        id: 'opt_001',
        storeId: 'store_001',
        type: 'uom',
        value: 'kilogram',
        pcsPerUnit: 1,
        updatedAt: '2026-06-01',
      );
      final map = original.toMap();
      final restored = ProductOptionModel.fromMap(map);
      expect(restored.type, equals('uom'));
      expect(restored.value, equals('kilogram'));
      expect(restored.pcsPerUnit, equals(1));
    });

    test('fromMap and toMap roundtrip for packaging option', () {
      const original = ProductOptionModel(
        id: 'opt_002',
        storeId: 'store_001',
        type: 'packaging',
        value: 'Case of 24',
        pcsPerUnit: 24,
        updatedAt: '2026-06-01',
      );
      final map = original.toMap();
      final restored = ProductOptionModel.fromMap(map);
      expect(restored.type, equals('packaging'));
      expect(restored.value, equals('Case of 24'));
      expect(restored.pcsPerUnit, equals(24));
    });

    test('fromMap uses defaults when keys are missing', () {
      final result = ProductOptionModel.fromMap({
        'id': 'o1', 'storeId': 's1', 'type': 'uom', 'value': 'piece',
        'updatedAt': '',
      });
      expect(result.pcsPerUnit, equals(1));
    });

    test('toSql returns same as toMap', () {
      const option = ProductOptionModel(
        id: 'opt_003', storeId: 'store_001', type: 'uom', value: 'liter',
        updatedAt: '2026-06-01',
      );
      expect(option.toSql(), equals(option.toMap()));
    });
  });
}
