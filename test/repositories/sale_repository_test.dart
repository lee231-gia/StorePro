import 'package:flutter_test/flutter_test.dart';
import 'package:storepro/core/utils/session.dart';
import 'package:storepro/models/sale_model.dart';
import 'package:storepro/repositories/sale_repository.dart';
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
    await SQLiteService.deleteWhere('sales', '1=1', []);
    await SQLiteService.deleteWhere('sync_queue', '1=1', []);
    await SQLiteService.deleteWhere('activity_logs', '1=1', []);
  });

  group('SaleRepository.save', () {
    test('saves a new sale with items', () async {
      final sale = SaleModel(
        id: '',
        storeId: Session.storeId,
        customerName: 'Juan dela Cruz',
        employeeName: 'Cashier',
        items: [
          SaleItemModel(
            productId: 'p-1',
            productName: 'Coca-Cola 1.5L',
            variantId: 'v-1',
            variantName: '1.5L',
            qty: 2,
            price: 65.0,
            costPrice: 52.0,
          ),
          SaleItemModel(
            productId: 'p-2',
            productName: 'Skyflakes',
            variantId: 'v-2',
            variantName: '200g',
            qty: 1,
            price: 25.0,
            costPrice: 20.0,
          ),
        ],
        subtotal: 155.0,
        totalDiscount: 5.0,
        total: 150.0,
        amountPaid: 150.0,
        change: 0.0,
        paymentType: 'cash',
        status: 'completed',
        date: '2026-06-28',
        timestamp: '2026-06-28T10:30:00',
        updatedAt: '2026-06-28T10:30:00',
      );
      final saved = await SaleRepository.save(sale);
      expect(saved.id, isNot(equals('')));
      expect(saved.total, equals(150.0));
      expect(saved.items.length, equals(2));
      expect(saved.customerName, equals('Juan dela Cruz'));
    });

    test('preserves all fields through save and retrieve roundtrip', () async {
      final sale = SaleModel(
        id: '',
        storeId: Session.storeId,
        customerId: 'cust-1',
        customerName: 'Maria Santos',
        employeeId: 'emp-1',
        employeeName: 'Ana',
        items: [
          SaleItemModel(
            productId: 'p-1',
            productName: 'Test Item',
            variantId: 'v-1',
            variantName: 'Regular',
            qty: 3,
            price: 100.0,
            costPrice: 75.0,
            discount: 10.0,
          ),
        ],
        subtotal: 300.0,
        totalDiscount: 10.0,
        total: 290.0,
        amountPaid: 300.0,
        change: 10.0,
        paymentType: 'cash',
        status: 'completed',
        notes: 'Thank you',
        date: '2026-06-28',
        timestamp: '2026-06-28T11:00:00',
        updatedAt: '2026-06-28T11:00:00',
        editHistory: [],
      );
      final saved = await SaleRepository.save(sale);
      final sales = await SaleRepository.getAll();
      final found = sales.firstWhere((s) => s.id == saved.id);
      expect(found.customerId, equals('cust-1'));
      expect(found.employeeName, equals('Ana'));
      expect(found.items.first.discount, equals(10.0));
      expect(found.change, equals(10.0));
      expect(found.notes, equals('Thank you'));
      expect(found.status, equals('completed'));
      expect(found.profit,
          equals((100.0 - 75.0) * 3 - 10.0));
    });
  });

  group('SaleRepository.getAll', () {
    test('returns sales ordered by date descending', () async {
      final s1 = await SaleRepository.save(
        SaleModel(
          id: '',
          storeId: Session.storeId,
          items: [],
          subtotal: 100, total: 100, amountPaid: 100,
          date: '2026-06-27', timestamp: '2026-06-27T10:00:00',
          updatedAt: '2026-06-27T10:00:00',
        ),
      );
      final s2 = await SaleRepository.save(
        SaleModel(
          id: '',
          storeId: Session.storeId,
          items: [],
          subtotal: 200, total: 200, amountPaid: 200,
          date: '2026-06-28', timestamp: '2026-06-28T10:00:00',
          updatedAt: '2026-06-28T10:00:00',
        ),
      );
      final sales = await SaleRepository.getAll();
      expect(sales.length, equals(2));
      expect(sales.first.id, equals(s2.id));
      expect(sales.last.id, equals(s1.id));
    });

    test('returns only sales for the current store', () async {
      await SaleRepository.save(
        SaleModel(
          id: '',
          storeId: Session.storeId,
          items: [],
          subtotal: 100, total: 100, amountPaid: 100,
          date: '2026-06-28', timestamp: '2026-06-28T10:00:00',
          updatedAt: '2026-06-28T10:00:00',
        ),
      );
      await SQLiteService.upsert('sales', {
        'id': 'other-sale',
        'storeId': 'other-store',
        'dataJson': '{"id":"other-sale"}',
        'date': '2026-06-28', 'total': 50,
        'updatedAt': '2026-06-28T10:00:00',
      });
      final sales = await SaleRepository.getAll();
      expect(sales.length, equals(1));
    });
  });

  group('SaleRepository.refund', () {
    test('creates a refunded copy with editHistory', () async {
      final original = await SaleRepository.save(
        SaleModel(
          id: '',
          storeId: Session.storeId,
          customerName: 'Refund Customer',
          items: [
            SaleItemModel(
              productId: 'p-1', productName: 'Item A',
              variantId: 'v-1', variantName: 'Regular',
              qty: 1, price: 100, costPrice: 70,
            ),
          ],
          subtotal: 100, total: 100, amountPaid: 100,
          date: '2026-06-28', timestamp: '2026-06-28T10:00:00',
          updatedAt: '2026-06-28T10:00:00',
        ),
      );
      final edited = original.copyWith(
        items: [],
        subtotal: 0, total: 0, amountPaid: 0, status: 'refunded',
      );
      final refunded = await SaleRepository.refund(original, edited);
      expect(refunded.status, equals('refunded'));
      expect(refunded.editHistory.length, equals(1));
      expect(refunded.editHistory.first['snapshot']['id'], equals(original.id));
    });
  });

  group('SaleRepository.delete', () {
    test('removes a sale from the database', () async {
      final saved = await SaleRepository.save(
        SaleModel(
          id: '',
          storeId: Session.storeId,
          items: [],
          subtotal: 100, total: 100, amountPaid: 100,
          date: '2026-06-28', timestamp: '2026-06-28T10:00:00',
          updatedAt: '2026-06-28T10:00:00',
        ),
      );
      await SaleRepository.delete(saved.id);
      final sales = await SaleRepository.getAll();
      expect(sales.any((s) => s.id == saved.id), isFalse);
    });
  });
}
