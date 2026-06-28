import 'package:flutter_test/flutter_test.dart';
import 'package:storepro/models/product_model.dart';

void main() {
  group('LifeIndicator', () {
    test('hasDate returns true when type is not N/A and date is not empty', () {
      const indicator = LifeIndicator(type: 'Expiry Date', date: '2027-06-01');
      expect(indicator.hasDate, isTrue);
    });

    test('hasDate returns false when type is N/A', () {
      const indicator = LifeIndicator(type: 'N/A', date: '2027-06-01');
      expect(indicator.hasDate, isFalse);
    });

    test('hasDate returns false when date is empty', () {
      const indicator = LifeIndicator(type: 'Expiry Date', date: '');
      expect(indicator.hasDate, isFalse);
    });

    test('affectsExpiry returns true for expiry-relevant types', () {
      const indicator = LifeIndicator(type: 'Use-By', date: '2027-06-01');
      expect(indicator.affectsExpiry, isTrue);
    });

    test('affectsExpiry returns false for origin dates', () {
      const indicator = LifeIndicator(type: 'Manufacturing Date (MFG)', date: '2026-01-15');
      expect(indicator.affectsExpiry, isFalse);
    });

    test('isOriginDate returns true for MFG, Production, Packed On', () {
      const mfg = LifeIndicator(type: 'Manufacturing Date (MFG)', date: '2026-01-15');
      const prod = LifeIndicator(type: 'Production Date', date: '2026-01-15');
      const packed = LifeIndicator(type: 'Packed On', date: '2026-01-15');
      expect(mfg.isOriginDate, isTrue);
      expect(prod.isOriginDate, isTrue);
      expect(packed.isOriginDate, isTrue);
    });

    test('fromMap and toMap roundtrip correctly', () {
      const original = LifeIndicator(type: 'Best Before', date: '2027-03-15');
      final map = original.toMap();
      final restored = LifeIndicator.fromMap(map);
      expect(restored.type, equals('Best Before'));
      expect(restored.date, equals('2027-03-15'));
    });

    test('fromMap uses defaults when keys are missing', () {
      final result = LifeIndicator.fromMap({});
      expect(result.type, equals('N/A'));
      expect(result.date, equals(''));
    });

    test('shortLabel returns abbreviated form for known types', () {
      const indicator = LifeIndicator(type: 'Expiry Date', date: '2027-06-01');
      expect(indicator.shortLabel, equals('Exp'));
    });

    test('shortLabel returns raw type for unknown types', () {
      const indicator = LifeIndicator(type: 'Random Label', date: '2027-06-01');
      expect(indicator.shortLabel, equals('Random Label'));
    });
  });

  group('BatchModel', () {
    final baseBatch = BatchModel(
      id: 'batch_001',
      batchNumber: 'B2026-001',
      qty: 50,
      costPrice: 15.75,
      indicators: const [
        LifeIndicator(type: 'Expiry Date', date: '2027-06-01'),
        LifeIndicator(type: 'Manufacturing Date (MFG)', date: '2026-01-15'),
      ],
      addedOn: '2026-01-20',
    );

    test('primaryExpiry returns earliest expiry-relevant date', () {
      expect(baseBatch.primaryExpiry, equals('2027-06-01'));
    });

    test('primaryExpiry returns empty when no expiry-relevant indicators', () {
      final batch = BatchModel(
        id: 'batch_002',
        qty: 10,
        costPrice: 10.0,
        indicators: const [
          LifeIndicator(type: 'Manufacturing Date (MFG)', date: '2026-01-15'),
        ],
        addedOn: '2026-01-20',
      );
      expect(batch.primaryExpiry, equals(''));
    });

    test('primaryExpiry sorts by date then type priority', () {
      final batch = BatchModel(
        id: 'batch_003',
        qty: 20,
        costPrice: 12.0,
        indicators: const [
          LifeIndicator(type: 'Best Before', date: '2027-06-01'),
          LifeIndicator(type: 'Expiry Date', date: '2027-06-01'),
        ],
        addedOn: '2026-02-01',
      );
      expect(batch.primaryExpiry, equals('2027-06-01'));
    });

    test('fromMap and toMap roundtrip correctly', () {
      final map = baseBatch.toMap();
      final restored = BatchModel.fromMap(map);
      expect(restored.id, equals('batch_001'));
      expect(restored.qty, equals(50));
      expect(restored.costPrice, equals(15.75));
      expect(restored.indicators.length, equals(2));
      expect(restored.indicators[0].type, equals('Expiry Date'));
    });

    test('fromMap uses defaults when keys are missing', () {
      final result = BatchModel.fromMap({'id': 'b1', 'qty': 0, 'addedOn': ''});
      expect(result.batchNumber, equals(''));
      expect(result.costPrice, equals(0.0));
      expect(result.indicators, isEmpty);
    });
  });

  group('ConditionModel', () {
    test('fromMap and toMap roundtrip correctly', () {
      const original = ConditionModel(name: 'With Ice', additionalPrice: 5.0);
      final map = original.toMap();
      final restored = ConditionModel.fromMap(map);
      expect(restored.name, equals('With Ice'));
      expect(restored.additionalPrice, equals(5.0));
    });

    test('price getter returns additionalPrice', () {
      const condition = ConditionModel(name: 'Extra Shot', additionalPrice: 15.0);
      expect(condition.price, equals(15.0));
    });

    test('fromMap uses defaults when keys are missing', () {
      final result = ConditionModel.fromMap({});
      expect(result.name, equals(''));
      expect(result.additionalPrice, equals(0.0));
    });
  });

  group('DiscountModel', () {
    test('fromMap and toMap roundtrip correctly', () {
      const original = DiscountModel(title: 'Storewide Sale', type: '%', value: 15.0);
      final map = original.toMap();
      final restored = DiscountModel.fromMap(map);
      expect(restored.title, equals('Storewide Sale'));
      expect(restored.type, equals('%'));
      expect(restored.value, equals(15.0));
    });

    test('fromMap uses defaults when keys are missing', () {
      final result = DiscountModel.fromMap({});
      expect(result.title, equals(''));
      expect(result.type, equals('%'));
      expect(result.value, equals(0.0));
    });
  });

  group('VariantModel', () {
    final variant = VariantModel(
      id: 'variant_001',
      name: 'Liter Solo',
      sku: 'COLA-LTR-001',
      unit: 'bottle',
      packaging: 'Solo',
      pcsPerUnit: 1,
      price: 25.00,
      originalPrice: 30.00,
      costPrice: 15.00,
      hasDiscount: true,
      discounts: const [
        DiscountModel(title: 'Promo', type: '₱', value: 5.0),
      ],
      conditions: const [
        ConditionModel(name: 'With Ice', additionalPrice: 3.0),
      ],
      batches: [
        BatchModel(
          id: 'batch_001', qty: 30, costPrice: 14.00,
          indicators: const [LifeIndicator(type: 'Expiry Date', date: '2027-08-01')],
          addedOn: '2026-03-01',
        ),
        BatchModel(
          id: 'batch_002', qty: 20, costPrice: 16.50,
          indicators: const [LifeIndicator(type: 'Expiry Date', date: '2027-06-01')],
          addedOn: '2026-04-15',
        ),
      ],
    );

    test('totalStock sums quantities across all batches', () {
      expect(variant.totalStock, equals(50));
    });

    test('totalStock returns 0 when batches is empty', () {
      final empty = VariantModel(
        id: 'v2', name: 'Empty Variant', unit: 'piece',
        price: 10.0, originalPrice: 10.0, costPrice: 5.0,
      );
      expect(empty.totalStock, equals(0));
    });

    test('nearestExpiry returns earliest date across batches', () {
      expect(variant.nearestExpiry, equals('2027-06-01'));
    });

    test('nearestExpiry returns empty when no batches have expiry dates', () {
      final noExpiry = VariantModel(
        id: 'v3', name: 'No Expiry', unit: 'piece',
        price: 10.0, originalPrice: 10.0,
        batches: [
          BatchModel(id: 'b1', qty: 5, costPrice: 3.0, addedOn: '2026-01-01'),
        ],
      );
      expect(noExpiry.nearestExpiry, equals(''));
    });

    test('avgCostPrice computes weighted average across batches', () {
      expect(variant.avgCostPrice, closeTo(15.0, 0.001));
    });

    test('avgCostPrice returns costPrice when total stock is 0', () {
      final zeroStock = VariantModel(
        id: 'v4', name: 'Zero Stock', unit: 'piece',
        price: 10.0, originalPrice: 10.0, costPrice: 8.0,
      );
      expect(zeroStock.avgCostPrice, equals(8.00));
    });

    test('fromMap and toMap roundtrip correctly', () {
      final map = variant.toMap();
      final restored = VariantModel.fromMap(map);
      expect(restored.name, equals('Liter Solo'));
      expect(restored.price, equals(25.00));
      expect(restored.totalStock, equals(50));
      expect(restored.discounts.length, equals(1));
      expect(restored.conditions.length, equals(1));
      expect(restored.batches.length, equals(2));
    });

    test('fromMap uses defaults when keys are missing', () {
      final result = VariantModel.fromMap({'id': 'v1', 'name': 'Test', 'unit': 'piece', 'price': 0.0, 'originalPrice': 0.0});
      expect(result.sku, equals(''));
      expect(result.pcsPerUnit, equals(1));
      expect(result.discounts, isEmpty);
      expect(result.batches, isEmpty);
    });

    test('copyWith updates only specified fields', () {
      final copied = variant.copyWith(name: 'Liter Family Size', price: 45.00);
      expect(copied.id, equals('variant_001'));
      expect(copied.name, equals('Liter Family Size'));
      expect(copied.price, equals(45.00));
      expect(copied.totalStock, equals(50));
    });

    test('expiryTier returns no_date when nearestExpiry is empty', () {
      final noExpiry = VariantModel(
        id: 'v5', name: 'No Date', unit: 'piece',
        price: 5.0, originalPrice: 5.0,
      );
      expect(noExpiry.expiryTier, equals('no_date'));
    });
  });

  group('ProductModel', () {
    final product = ProductModel(
      id: 'prod_001',
      storeId: 'store_001',
      name: 'Coca-Cola Original',
      description: 'Classic 1L carbonated soft drink',
      categoryId: 'cat_001',
      categoryName: 'Beverages',
      hasVariants: true,
      iconIndex: 3,
      colorIndex: 1,
      imageUrl: 'https://res.cloudinary.com/example/coke.jpg',
      variants: [
        VariantModel(
          id: 'v1', name: 'Liter Solo', unit: 'bottle', price: 25.00,
          originalPrice: 30.00, costPrice: 15.00,
          batches: [
            BatchModel(id: 'b1', qty: 30, costPrice: 14.00,
              indicators: const [LifeIndicator(type: 'Expiry Date', date: '2027-08-01')],
              addedOn: '2026-03-01'),
            BatchModel(id: 'b2', qty: 20, costPrice: 16.50,
              indicators: const [LifeIndicator(type: 'Expiry Date', date: '2027-06-01')],
              addedOn: '2026-04-15'),
          ],
        ),
        VariantModel(
          id: 'v2', name: '1.5L Family', unit: 'bottle', price: 40.00,
          originalPrice: 45.00, costPrice: 25.00,
          batches: [
            BatchModel(id: 'b3', qty: 15, costPrice: 24.00,
              indicators: const [LifeIndicator(type: 'Expiry Date', date: '2027-09-01')],
              addedOn: '2026-05-01'),
          ],
        ),
      ],
      addedOn: '2026-01-01',
      updatedAt: '2026-06-01',
    );

    test('totalStock sums across all variants', () {
      expect(product.totalStock, equals(65));
    });

    test('totalStock returns 0 when no variants', () {
      final empty = ProductModel(
        id: 'p2', storeId: 's1', name: 'Empty', categoryId: 'c1',
        categoryName: 'Test', addedOn: '', updatedAt: '',
      );
      expect(empty.totalStock, equals(0));
    });

    test('lowestPrice returns minimum price across variants', () {
      expect(product.lowestPrice, equals(25.00));
    });

    test('lowestPrice returns 0 when no variants', () {
      final empty = ProductModel(
        id: 'p3', storeId: 's1', name: 'Empty', categoryId: 'c1',
        categoryName: 'Test', addedOn: '', updatedAt: '',
      );
      expect(empty.lowestPrice, equals(0));
    });

    test('nearestExpiry returns earliest date across all variants', () {
      expect(product.nearestExpiry, equals('2027-06-01'));
    });

    test('nearestExpiry returns empty when no variants have expiry dates', () {
      final noExpiry = ProductModel(
        id: 'p4', storeId: 's1', name: 'No Expiry', categoryId: 'c1',
        categoryName: 'Test', variants: [
          VariantModel(id: 'vx', name: 'V', unit: 'pc', price: 5.0, originalPrice: 5.0),
        ],
        addedOn: '', updatedAt: '',
      );
      expect(noExpiry.nearestExpiry, equals(''));
    });

    test('fromMap and toMap roundtrip correctly', () {
      final map = product.toMap();
      final restored = ProductModel.fromMap(map);
      expect(restored.name, equals('Coca-Cola Original'));
      expect(restored.variants.length, equals(2));
      expect(restored.lowestPrice, equals(25.00));
    });

    test('fromMap uses defaults when keys are missing', () {
      final result = ProductModel.fromMap({'id': 'p1', 'storeId': 's1', 'name': 'T', 'categoryId': 'c1', 'categoryName': 'C', 'addedOn': '', 'updatedAt': ''});
      expect(result.description, equals(''));
      expect(result.hasVariants, isFalse);
      expect(result.variants, isEmpty);
    });

    test('toSql and fromSql roundtrip correctly', () {
      final sqlMap = product.toSql();
      final restored = ProductModel.fromSql(sqlMap);
      expect(restored.id, equals('prod_001'));
      expect(restored.name, equals('Coca-Cola Original'));
      expect(restored.totalStock, equals(65));
      expect(restored.hasVariants, isTrue);
    });

    test('copyWith updates only specified fields', () {
      final copied = product.copyWith(name: 'Coca-Cola Zero', categoryName: 'Sugar-Free Beverages');
      expect(copied.id, equals('prod_001'));
      expect(copied.name, equals('Coca-Cola Zero'));
      expect(copied.categoryName, equals('Sugar-Free Beverages'));
      expect(copied.totalStock, equals(65));
    });
  });
}
