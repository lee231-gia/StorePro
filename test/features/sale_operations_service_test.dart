import 'package:flutter_test/flutter_test.dart';
import 'package:storepro/core/services/sqlite_service.dart';
import 'package:storepro/core/utils/session.dart';
import 'package:storepro/features/sales/services/sale_operations_service.dart';
import 'package:storepro/models/product_model.dart';
import 'package:storepro/models/sale_model.dart';
import 'package:storepro/models/customer_model.dart';
import 'package:storepro/models/utang_model.dart';
import 'package:storepro/repositories/product_repository.dart';
import 'package:storepro/repositories/sale_repository.dart';
import 'package:storepro/repositories/customer_repository.dart';
import 'package:storepro/repositories/utang_repository.dart';
import '../repositories/repository_test_base.dart';

void main() {
  setUpAll(() async {
    await initRepositories();
  });

  setUp(() async {
    await setupRepositories();
    Session.activeEmployeeName = 'Test Cashier';
  });

  tearDown(() async {
    await SQLiteService.deleteWhere('products', '1=1', []);
    await SQLiteService.deleteWhere('sales', '1=1', []);
    await SQLiteService.deleteWhere('customers', '1=1', []);
    await SQLiteService.deleteWhere('utang', '1=1', []);
    await SQLiteService.deleteWhere('inventory_logs', '1=1', []);
    await SQLiteService.deleteWhere('activity_logs', '1=1', []);
    await SQLiteService.deleteWhere('sync_queue', '1=1', []);
  });

  Future<ProductModel> _seedProduct({int stock = 20}) async {
    return ProductRepository.save(
      ProductModel(
        id: '',
        storeId: Session.storeId,
        name: 'Coca-Cola 1.5L',
        categoryId: 'cat-1',
        categoryName: 'Beverages',
        variants: [
          VariantModel(
            id: 'v-1',
            name: '1.5L',
            unit: 'bottle',
            price: 65.0,
            originalPrice: 65.0,
            costPrice: 52.0,
            batches: [
              BatchModel(id: 'b-1', qty: stock, costPrice: 52.0, addedOn: '2026-06-01'),
            ],
          ),
        ],
        addedOn: '2026-06-28',
        updatedAt: '2026-06-28T10:00:00',
      ),
    );
  }

  Future<SaleModel> _seedSale(ProductModel product, {int qty = 3}) async {
    return SaleRepository.save(
      SaleModel(
        id: '',
        storeId: Session.storeId,
        customerName: 'Juan dela Cruz',
        items: [
          SaleItemModel(
            productId: product.id,
            productName: product.name,
            variantId: product.variants.first.id,
            variantName: product.variants.first.name,
            qty: qty,
            price: product.variants.first.price,
            costPrice: product.variants.first.costPrice,
          ),
        ],
        subtotal: product.variants.first.price * qty,
        total: product.variants.first.price * qty,
        amountPaid: product.variants.first.price * qty,
        paymentType: 'cash',
        status: 'completed',
        date: '2026-06-28',
        timestamp: '2026-06-28T10:30:00',
        updatedAt: '2026-06-28T10:30:00',
      ),
    );
  }

  group('SaleOperationsService.refundSale', () {
    test('restores stock and marks sale as refunded', () async {
      final product = await _seedProduct(stock: 20);
      final sale = await _seedSale(product, qty: 3);
      await ProductRepository.deductFifo(product.id, product.variants.first.id, 3);
      expect((await ProductRepository.getOne(product.id))!.variants.first.totalStock, equals(17));
      final refunded = await SaleOperationsService.refundSale(sale, reason: 'Customer returned');
      expect(refunded.status, equals('refunded'));
      final updated = await ProductRepository.getOne(product.id);
      expect(updated!.variants.first.totalStock, equals(20));
    });

    test('skips already refunded sales', () async {
      final product = await _seedProduct(stock: 10);
      final sale = await _seedSale(product, qty: 2);
      await ProductRepository.deductFifo(product.id, product.variants.first.id, 2);
      await SaleOperationsService.refundSale(sale, reason: 'First refund');
      final already = await SaleRepository.getAll();
      final refundedSale = already.firstWhere((s) => s.id == sale.id);
      final result = await SaleOperationsService.refundSale(refundedSale, reason: 'Second refund');
      expect(result.status, equals('refunded'));
      final updated = await ProductRepository.getOne(product.id);
      expect(updated!.variants.first.totalStock, equals(10));
    });
  });

  group('SaleOperationsService.editSale', () {
    test('adjusts stock when items change', () async {
      final product = await _seedProduct(stock: 10);
      final sale = await _seedSale(product, qty: 4);
      await ProductRepository.deductFifo(product.id, product.variants.first.id, 4);
      expect((await ProductRepository.getOne(product.id))!.variants.first.totalStock, equals(6));
      final edited = sale.copyWith(
        items: [
          SaleItemModel(
            productId: product.id,
            productName: product.name,
            variantId: product.variants.first.id,
            variantName: product.variants.first.name,
            qty: 2,
            price: product.variants.first.price,
            costPrice: product.variants.first.costPrice,
          ),
        ],
        subtotal: product.variants.first.price * 2,
        total: product.variants.first.price * 2,
      );
      await SaleOperationsService.editSale(original: sale, edited: edited, reason: 'Qty adjustment');
      final updated = await ProductRepository.getOne(product.id);
      expect(updated!.variants.first.totalStock, equals(8));
    });
  });
}
