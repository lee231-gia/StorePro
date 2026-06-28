import 'package:flutter_test/flutter_test.dart';
import 'package:storepro/core/enums/product_browser_enums.dart';
import 'package:storepro/models/product_model.dart';
import 'package:storepro/shared/controllers/product_browser_controller.dart';

void main() {
  late ProductBrowserController controller;

  final products = [
    ProductModel(
      id: 'prod_001', storeId: 'store_001', name: 'Coca-Cola Original',
      categoryId: 'cat_001', categoryName: 'Beverages',
      variants: [
        VariantModel(id: 'v1', name: 'Liter Solo', unit: 'bottle', price: 25.00, originalPrice: 30.00, costPrice: 15.00,
          batches: [BatchModel(id: 'b1', qty: 30, costPrice: 14.00, addedOn: '2026-03-01')]),
        VariantModel(id: 'v2', name: '1.5L Family', unit: 'bottle', price: 40.00, originalPrice: 45.00, costPrice: 25.00,
          batches: [BatchModel(id: 'b2', qty: 15, costPrice: 24.00, addedOn: '2026-05-01')]),
      ],
      addedOn: '2026-01-15', updatedAt: '2026-06-01',
    ),
    ProductModel(
      id: 'prod_002', storeId: 'store_001', name: 'Mountain Dew',
      categoryId: 'cat_001', categoryName: 'Beverages',
      variants: [
        VariantModel(id: 'v3', name: 'Liter Solo', unit: 'bottle', price: 25.00, originalPrice: 30.00, costPrice: 15.00,
          batches: [BatchModel(id: 'b3', qty: 5, costPrice: 14.00, addedOn: '2026-02-01')]),
      ],
      addedOn: '2026-02-20', updatedAt: '2026-06-01',
    ),
    ProductModel(
      id: 'prod_003', storeId: 'store_001', name: 'Lays Classic',
      categoryId: 'cat_002', categoryName: 'Snacks',
      variants: [
        VariantModel(id: 'v4', name: 'Small Pack', unit: 'piece', price: 20.00, originalPrice: 22.00, costPrice: 12.00,
          batches: [BatchModel(id: 'b4', qty: 50, costPrice: 11.50, addedOn: '2026-04-01')]),
      ],
      addedOn: '2026-04-10', updatedAt: '2026-06-01',
    ),
    ProductModel(
      id: 'prod_004', storeId: 'store_001', name: 'Piatos',
      categoryId: 'cat_002', categoryName: 'Snacks',
      variants: [
        VariantModel(id: 'v5', name: 'Regular', unit: 'piece', price: 18.00, originalPrice: 20.00, costPrice: 11.00,
          batches: []),
      ],
      addedOn: '2026-03-05', updatedAt: '2026-06-01',
    ),
  ];

  setUp(() {
    controller = ProductBrowserController();
  });

  group('ProductBrowserController.search', () {
    test('returns all products when search is empty', () {
      final result = controller.apply(products);
      expect(result.length, equals(4));
    });

    test('filters by product name', () {
      controller.search = 'coca';
      final result = controller.apply(products);
      expect(result.length, equals(1));
      expect(result.first.name, equals('Coca-Cola Original'));
    });

    test('filters by category name', () {
      controller.search = 'snacks';
      final result = controller.apply(products);
      expect(result.length, equals(2));
      expect(result.every((p) => p.categoryName == 'Snacks'), isTrue);
    });

    test('filters by variant name', () {
      controller.search = '1.5L';
      final result = controller.apply(products);
      expect(result.length, equals(1));
      expect(result.first.name, equals('Coca-Cola Original'));
    });

    test('is case-insensitive', () {
      controller.search = 'COCA';
      final result = controller.apply(products);
      expect(result.length, equals(1));
    });

    test('returns empty list when no match', () {
      controller.search = 'nonexistent';
      final result = controller.apply(products);
      expect(result, isEmpty);
    });
  });

  group('ProductBrowserController.categoryFilter', () {
    test('returns only products in the selected category', () {
      controller.categoryFilter = 'Snacks';
      final result = controller.apply(products);
      expect(result.length, equals(2));
      expect(result.every((p) => p.categoryName == 'Snacks'), isTrue);
    });

    test('returns all products when category is All', () {
      controller.categoryFilter = 'All';
      final result = controller.apply(products);
      expect(result.length, equals(4));
    });
  });

  group('ProductBrowserController.sortOption', () {
    test('sorts by name ascending', () {
      controller.sortOption = ProductSortOption.nameAsc;
      final result = controller.apply(products);
      expect(result[0].name, equals('Coca-Cola Original'));
      expect(result[3].name, equals('Piatos'));
    });

    test('sorts by name descending', () {
      controller.sortOption = ProductSortOption.nameDesc;
      final result = controller.apply(products);
      expect(result[0].name, equals('Piatos'));
      expect(result[3].name, equals('Coca-Cola Original'));
    });

    test('sorts by stock ascending', () {
      controller.sortOption = ProductSortOption.stockAsc;
      final result = controller.apply(products);
      expect(result[0].name, equals('Piatos')); // 0 stock
      expect(result[3].name, equals('Lays Classic')); // 50 stock
    });

    test('sorts by stock descending', () {
      controller.sortOption = ProductSortOption.stockDesc;
      final result = controller.apply(products);
      expect(result[0].name, equals('Lays Classic')); // 50 stock
    });

    test('sorts by price ascending', () {
      controller.sortOption = ProductSortOption.priceAsc;
      final result = controller.apply(products);
      expect(result[0].lowestPrice, equals(18.00));
      expect(result[1].lowestPrice, equals(20.00));
      expect(result[2].lowestPrice, equals(25.00));
    });

    test('sorts by price descending', () {
      controller.sortOption = ProductSortOption.priceDesc;
      final result = controller.apply(products);
      expect(result[0].lowestPrice, equals(25.00));
      expect(result[2].lowestPrice, equals(20.00));
      expect(result[3].lowestPrice, equals(18.00));
    });

    test('sorts by category ascending', () {
      controller.sortOption = ProductSortOption.categoryAsc;
      final result = controller.apply(products);
      expect(result[0].categoryName, equals('Beverages'));
      expect(result[2].categoryName, equals('Snacks'));
    });

    test('sorts by category descending', () {
      controller.sortOption = ProductSortOption.categoryDesc;
      final result = controller.apply(products);
      expect(result[0].categoryName, equals('Snacks'));
    });
  });

  group('ProductBrowserController.statusFilter', () {
    test('returns only products with 0 stock for No Stock', () {
      controller.statusFilter = 'No Stock';
      final result = controller.apply(products);
      expect(result.length, equals(1));
      expect(result.first.name, equals('Piatos'));
    });

    test('returns only products with stock > 0 for Available', () {
      controller.statusFilter = 'Available';
      final result = controller.apply(products);
      expect(result.length, equals(3));
      expect(result.every((p) => p.totalStock > 0), isTrue);
    });

    test('returns only products with stock <= 10 for Low Stock', () {
      controller.statusFilter = 'Low Stock';
      final result = controller.apply(products);
      expect(result.length, equals(1));
      expect(result.first.name, equals('Mountain Dew'));
    });
  });

  group('ProductBrowserController.viewMode', () {
    test('setting viewMode updates the getter', () {
      expect(controller.viewMode, equals(ProductViewMode.list));
      controller.viewMode = ProductViewMode.grid;
      expect(controller.viewMode, equals(ProductViewMode.grid));
    });
  });

  group('ProductBrowserController.groupVariants', () {
    test('setting groupVariants updates the getter', () {
      expect(controller.groupVariants, isTrue);
      controller.groupVariants = false;
      expect(controller.groupVariants, isFalse);
    });
  });

  group('ProductBrowserController.apply with combined filters', () {
    test('combines search and category filter', () {
      controller.search = 'lay';
      controller.categoryFilter = 'Snacks';
      final result = controller.apply(products);
      expect(result.length, equals(1));
      expect(result.first.name, equals('Lays Classic'));
    });

    test('search + status filter', () {
      controller.search = 'coca';
      controller.statusFilter = 'Available';
      final result = controller.apply(products);
      expect(result.length, equals(1));
    });
  });
}
