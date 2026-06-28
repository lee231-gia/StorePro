import 'package:flutter_test/flutter_test.dart';
import 'package:storepro/core/utils/session.dart';
import 'package:storepro/models/product_model.dart';
import 'package:storepro/repositories/product_repository.dart';
import 'package:storepro/core/services/sqlite_service.dart';
import 'repository_test_base.dart';

void main() {
  setUpAll(() async {
    await initRepositories();
  });

  setUp(() async {
    await setupRepositories();
  });

  tearDown(() async {
    await SQLiteService.deleteWhere('products', '1=1', []);
    await SQLiteService.deleteWhere('sync_queue', '1=1', []);
    await SQLiteService.deleteWhere('activity_logs', '1=1', []);
  });

  group('ProductRepository.save and getOne', () {
    test('saves a new product and retrieves it', () async {
      final product = ProductModel(
        id: '',
        storeId: Session.storeId,
        name: 'Coca-Cola 1.5L',
        description: 'Soft drink',
        categoryId: 'cat-1',
        categoryName: 'Beverages',
        hasVariants: false,
        iconIndex: 0,
        colorIndex: 1,
        variants: [
          VariantModel(
            id: 'v-1',
            name: '1.5L',
            unit: 'bottle',
            price: 65.0,
            originalPrice: 65.0,
            costPrice: 52.0,
            batches: [
              BatchModel(id: 'b-1', qty: 20, costPrice: 52.0, addedOn: '2026-06-01'),
            ],
          ),
        ],
        addedOn: '2026-06-28',
        updatedAt: '2026-06-28T10:00:00',
      );
      final saved = await ProductRepository.save(product);
      expect(saved.id, isNot(equals('')));
      expect(saved.name, equals('Coca-Cola 1.5L'));
      expect(saved.variants.length, equals(1));
      expect(saved.variants.first.totalStock, equals(20));
      final loaded = await ProductRepository.getOne(saved.id);
      expect(loaded, isNotNull);
      expect(loaded!.name, equals('Coca-Cola 1.5L'));
      expect(loaded.variants.first.price, equals(65.0));
    });

    test('updates an existing product', () async {
      final product = ProductModel(
        id: '',
        storeId: Session.storeId,
        name: 'Original Name',
        categoryId: 'cat-1',
        categoryName: 'Beverages',
        addedOn: '2026-06-28',
        updatedAt: '2026-06-28T10:00:00',
      );
      final saved = await ProductRepository.save(product);
      final updated = await ProductRepository.save(
        saved.copyWith(
          name: 'Updated Name',
          updatedAt: '2026-06-28T11:00:00',
        ),
      );
      expect(updated.name, equals('Updated Name'));
      final loaded = await ProductRepository.getOne(saved.id);
      expect(loaded!.name, equals('Updated Name'));
    });

    test('returns null for non-existent product', () async {
      final result = await ProductRepository.getOne('non-existent-id');
      expect(result, isNull);
    });
  });

  group('ProductRepository.getAll', () {
    test('returns all products for the current store', () async {
      await ProductRepository.save(
        ProductModel(
          id: '',
          storeId: Session.storeId,
          name: 'Product A',
          categoryId: 'cat-1',
          categoryName: 'Goods',
          addedOn: '2026-06-28',
          updatedAt: '2026-06-28T10:00:00',
        ),
      );
      await ProductRepository.save(
        ProductModel(
          id: '',
          storeId: Session.storeId,
          name: 'Product B',
          categoryId: 'cat-2',
          categoryName: 'Goods',
          addedOn: '2026-06-28',
          updatedAt: '2026-06-28T10:00:00',
        ),
      );
      final products = await ProductRepository.getAll();
      expect(products.length, equals(2));
      expect(products.map((p) => p.name), containsAll(['Product A', 'Product B']));
    });

    test('returns only products for the current store', () async {
      await ProductRepository.save(
        ProductModel(
          id: '',
          storeId: Session.storeId,
          name: 'Store 1 Product',
          categoryId: 'cat-1',
          categoryName: 'Goods',
          addedOn: '2026-06-28',
          updatedAt: '2026-06-28T10:00:00',
        ),
      );
      await SQLiteService.upsert('products', {
        'id': 'other-store-product',
        'storeId': 'other-store',
        'name': 'Other Store Product',
        'dataJson': '{"id":"other-store-product","name":"Other Store Product"}',
        'addedOn': '2026-06-28',
        'updatedAt': '2026-06-28T10:00:00',
      });
      final products = await ProductRepository.getAll();
      expect(products.length, equals(1));
      expect(products.first.name, equals('Store 1 Product'));
    });

    test('returns empty list when no products', () async {
      final products = await ProductRepository.getAll();
      expect(products, isEmpty);
    });
  });

  group('ProductRepository.delete', () {
    test('removes a product from the database', () async {
      final saved = await ProductRepository.save(
        ProductModel(
          id: '',
          storeId: Session.storeId,
          name: 'To Delete',
          categoryId: 'cat-1',
          categoryName: 'Goods',
          addedOn: '2026-06-28',
          updatedAt: '2026-06-28T10:00:00',
        ),
      );
      expect(await ProductRepository.getOne(saved.id), isNotNull);
      await ProductRepository.delete(saved.id, saved.name);
      expect(await ProductRepository.getOne(saved.id), isNull);
    });
  });

  group('ProductRepository.deductFifo', () {
    test('deducts from the oldest batch first', () async {
      final saved = await ProductRepository.save(
        ProductModel(
          id: '',
          storeId: Session.storeId,
          name: 'Milk Tea',
          categoryId: 'cat-3',
          categoryName: 'Beverages',
          hasVariants: false,
          variants: [
            VariantModel(
              id: 'v-1',
              name: 'Regular',
              unit: 'cup',
              price: 55.0,
              originalPrice: 55.0,
              costPrice: 35.0,
              batches: [
                BatchModel(id: 'b-1', qty: 10, costPrice: 30.0, addedOn: '2026-06-01'),
                BatchModel(id: 'b-2', qty: 10, costPrice: 35.0, addedOn: '2026-06-15'),
              ],
            ),
          ],
          addedOn: '2026-06-28',
          updatedAt: '2026-06-28T10:00:00',
        ),
      );
      final result = await ProductRepository.deductFifo(saved.id, 'v-1', 12);
      expect(result, isNotNull);
      final updated = await ProductRepository.getOne(saved.id);
      expect(updated!.variants.first.totalStock, equals(8));
      expect(updated.variants.first.batches.length, equals(1));
      expect(updated.variants.first.batches[0].qty, equals(8));
    });

    test('removes exhausted batches', () async {
      final saved = await ProductRepository.save(
        ProductModel(
          id: '',
          storeId: Session.storeId,
          name: 'Batch Test',
          categoryId: 'cat-1',
          categoryName: 'Goods',
          variants: [
            VariantModel(
              id: 'v-1',
              name: 'Single',
              unit: 'pc',
              price: 10.0,
              originalPrice: 10.0,
              costPrice: 7.0,
              batches: [
                BatchModel(id: 'b-1', qty: 10, costPrice: 7.0, addedOn: '2026-06-01'),
              ],
            ),
          ],
          addedOn: '2026-06-28',
          updatedAt: '2026-06-28T10:00:00',
        ),
      );
      await ProductRepository.deductFifo(saved.id, 'v-1', 10);
      final updated = await ProductRepository.getOne(saved.id);
      expect(updated!.variants.first.totalStock, equals(0));
      expect(updated.variants.first.batches, isEmpty);
    });

    test('returns null when product is not found', () async {
      final result = await ProductRepository.deductFifo('non-existent', 'v-1', 5);
      expect(result, isNull);
    });
  });
}
