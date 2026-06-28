import 'package:flutter_test/flutter_test.dart';
import 'package:storepro/models/product_model.dart';
import 'package:storepro/widgets/product_card.dart';

void main() {
  group('ProductDisplayItem', () {
    final variantSingle = VariantModel(
      id: 'v_single', name: 'Liter Solo', unit: 'bottle',
      price: 25.00, originalPrice: 30.00, costPrice: 15.00,
      imageUrl: 'https://example.com/variant.jpg',
      batches: [
        BatchModel(id: 'b1', qty: 30, costPrice: 14.00,
          indicators: const [LifeIndicator(type: 'Expiry Date', date: '2027-08-01')],
          addedOn: '2026-03-01'),
      ],
    );

    final variantFamily = VariantModel(
      id: 'v_family', name: '1.5L Family', unit: 'bottle',
      price: 40.00, originalPrice: 45.00, costPrice: 25.00,
      batches: [
        BatchModel(id: 'b2', qty: 15, costPrice: 24.00, addedOn: '2026-05-01'),
      ],
    );

    final product = ProductModel(
      id: 'prod_001', storeId: 'store_001', name: 'Coca-Cola Original',
      categoryId: 'cat_001', categoryName: 'Beverages',
      imageUrl: 'https://example.com/product.jpg',
      variants: [variantSingle, variantFamily],
      addedOn: '2026-01-15', updatedAt: '2026-06-01',
    );

    final singleVariantProduct = ProductModel(
      id: 'prod_002', storeId: 'store_001', name: 'Mountain Dew',
      categoryId: 'cat_001', categoryName: 'Beverages',
      imageUrl: 'https://example.com/mdew.jpg',
      variants: [
        VariantModel(id: 'v3', name: 'Liter Solo', unit: 'bottle',
          price: 25.00, originalPrice: 30.00, costPrice: 15.00,
          batches: [BatchModel(id: 'b3', qty: 5, costPrice: 14.00, addedOn: '2026-02-01')]),
      ],
      addedOn: '2026-02-20', updatedAt: '2026-06-01',
    );

    group('ProductDisplayItem.grouped', () {
      test('creates a grouped item with no variant', () {
        final item = ProductDisplayItem.grouped(product);
        expect(item.product.name, equals('Coca-Cola Original'));
        expect(item.variant, isNull);
        expect(item.isVariant, isFalse);
      });

      test('name returns product name for grouped items', () {
        final item = ProductDisplayItem.grouped(product);
        expect(item.name, equals('Coca-Cola Original'));
      });

      test('id returns product id for grouped items', () {
        final item = ProductDisplayItem.grouped(product);
        expect(item.id, equals('prod_001'));
      });

      test('totalStock returns product totalStock for grouped items', () {
        final item = ProductDisplayItem.grouped(product);
        expect(item.totalStock, equals(45));
      });

      test('price returns lowestPrice for grouped items', () {
        final item = ProductDisplayItem.grouped(product);
        expect(item.price, equals(25.00));
      });

      test('nearestExpiry returns product nearestExpiry for grouped items', () {
        final item = ProductDisplayItem.grouped(product);
        expect(item.nearestExpiry, equals('2027-08-01'));
      });

      test('imageUrl returns product imageUrl for grouped items', () {
        final item = ProductDisplayItem.grouped(product);
        expect(item.imageUrl, equals('https://example.com/product.jpg'));
      });

      test('variantCount returns number of variants', () {
        final item = ProductDisplayItem.grouped(product);
        expect(item.variantCount, equals(2));
      });
    });

    group('ProductDisplayItem with variant', () {
      test('creates an item with a specific variant', () {
        final item = ProductDisplayItem(product: product, variant: variantSingle);
        expect(item.variant, isNotNull);
        expect(item.isVariant, isTrue);
      });

      test('name combines product name and variant name', () {
        final item = ProductDisplayItem(product: product, variant: variantSingle);
        expect(item.name, equals('Coca-Cola Original - Liter Solo'));
      });

      test('id includes variant id', () {
        final item = ProductDisplayItem(product: product, variant: variantSingle);
        expect(item.id, equals('prod_001:v_single'));
      });

      test('totalStock returns variant totalStock', () {
        final item = ProductDisplayItem(product: product, variant: variantSingle);
        expect(item.totalStock, equals(30));
      });

      test('price returns variant price', () {
        final item = ProductDisplayItem(product: product, variant: variantSingle);
        expect(item.price, equals(25.00));
      });

      test('imageUrl returns variant imageUrl when variant has one', () {
        final item = ProductDisplayItem(product: product, variant: variantSingle);
        expect(item.imageUrl, equals('https://example.com/variant.jpg'));
      });

      test('imageUrl falls back to product imageUrl when variant has none', () {
        final item = ProductDisplayItem(product: product, variant: variantFamily);
        expect(item.imageUrl, equals('https://example.com/product.jpg'));
      });
    });

    group('ProductDisplayItem.fromProducts', () {
      test('single-variant product always gets its variant assigned', () {
        final items = ProductDisplayItem.fromProducts(
          [singleVariantProduct],
          groupVariants: true,
        );
        expect(items.length, equals(1));
        expect(items.first.isVariant, isTrue);
        expect(items.first.name, equals('Mountain Dew - Liter Solo'));
      });

      test('multi-variant product is grouped when groupVariants is true', () {
        final items = ProductDisplayItem.fromProducts(
          [product],
          groupVariants: true,
        );
        expect(items.length, equals(1));
        expect(items.first.isVariant, isFalse);
        expect(items.first.name, equals('Coca-Cola Original'));
      });

      test('multi-variant product is ungrouped when groupVariants is false', () {
        final items = ProductDisplayItem.fromProducts(
          [product],
          groupVariants: false,
        );
        expect(items.length, equals(2));
        expect(items[0].isVariant, isTrue);
        expect(items[1].isVariant, isTrue);
        expect(items[0].name, equals('Coca-Cola Original - Liter Solo'));
        expect(items[1].name, equals('Coca-Cola Original - 1.5L Family'));
      });

      test('handles multiple products', () {
        final items = ProductDisplayItem.fromProducts(
          [singleVariantProduct, product],
          groupVariants: true,
        );
        expect(items.length, equals(2));
        expect(items[0].name, equals('Mountain Dew - Liter Solo'));
        expect(items[1].name, equals('Coca-Cola Original'));
      });

      test('processes empty product list', () {
        final items = ProductDisplayItem.fromProducts([], groupVariants: true);
        expect(items, isEmpty);
      });
    });
  });
}
