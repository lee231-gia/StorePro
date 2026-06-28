import 'package:flutter_test/flutter_test.dart';
import 'package:storepro/models/category_model.dart';

void main() {
  group('CategoryModel', () {
    test('fromMap and toMap roundtrip correctly', () {
      const original = CategoryModel(
        id: 'cat_001',
        storeId: 'store_001',
        name: 'Beverages',
        details: 'Soft drinks, juices, water, and energy drinks',
        iconIndex: 3,
        colorIndex: 1,
        imageUrl: 'https://res.cloudinary.com/example/beverages.png',
        updatedAt: '2026-06-01',
      );
      final map = original.toMap();
      final restored = CategoryModel.fromMap(map);
      expect(restored.name, equals('Beverages'));
      expect(restored.details, contains('Soft drinks'));
      expect(restored.iconIndex, equals(3));
      expect(restored.colorIndex, equals(1));
    });

    test('fromMap uses defaults when keys are missing', () {
      final result = CategoryModel.fromMap({
        'id': 'c1', 'storeId': 's1', 'name': 'Snacks', 'updatedAt': '',
      });
      expect(result.details, equals(''));
      expect(result.iconIndex, equals(0));
      expect(result.colorIndex, equals(0));
      expect(result.imageUrl, equals(''));
    });

    test('toSql returns same as toMap', () {
      const category = CategoryModel(
        id: 'cat_002', storeId: 'store_001', name: 'Snacks',
        updatedAt: '2026-06-01',
      );
      expect(category.toSql(), equals(category.toMap()));
    });

    test('copyWith updates only specified fields', () {
      const category = CategoryModel(
        id: 'cat_001', storeId: 'store_001', name: 'Beverages',
        updatedAt: '2026-06-01',
      );
      final copied = category.copyWith(name: 'Drinks', iconIndex: 5);
      expect(copied.name, equals('Drinks'));
      expect(copied.iconIndex, equals(5));
      expect(copied.id, equals('cat_001'));
      expect(copied.colorIndex, equals(0));
    });
  });
}
