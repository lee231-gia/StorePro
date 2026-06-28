import 'package:flutter_test/flutter_test.dart';
import 'package:storepro/models/sale_model.dart';

void main() {
  group('SaleItemModel', () {
    test('subtotal computes price * qty minus discount', () {
      const item = SaleItemModel(
        productId: 'prod_001',
        productName: 'Coca-Cola 1L',
        variantId: 'v_001',
        variantName: 'Liter Solo',
        qty: 3,
        price: 25.00,
        costPrice: 15.00,
        discount: 5.00,
      );
      expect(item.subtotal, equals(70.00));
    });

    test('subtotal equals price * qty when no discount', () {
      const item = SaleItemModel(
        productId: 'prod_001',
        productName: 'Coca-Cola 1L',
        variantId: 'v_001',
        variantName: 'Liter Solo',
        qty: 2,
        price: 25.00,
      );
      expect(item.subtotal, equals(50.00));
    });

    test('profit computes (price - costPrice) * qty - discount', () {
      const item = SaleItemModel(
        productId: 'prod_001',
        productName: 'Coca-Cola 1L',
        variantId: 'v_001',
        variantName: 'Liter Solo',
        qty: 3,
        price: 25.00,
        costPrice: 15.00,
        discount: 5.00,
      );
      expect(item.profit, equals(25.00));
    });

    test('fromMap and toMap roundtrip correctly', () {
      const original = SaleItemModel(
        productId: 'prod_001',
        productName: 'Mountain Dew 1L',
        variantId: 'v_002',
        variantName: 'Liter Solo',
        qty: 5,
        price: 25.00,
        costPrice: 14.50,
        discount: 0.0,
      );
      final map = original.toMap();
      final restored = SaleItemModel.fromMap(map);
      expect(restored.productName, equals('Mountain Dew 1L'));
      expect(restored.qty, equals(5));
      expect(restored.subtotal, equals(125.00));
    });

    test('fromMap uses defaults when keys are missing', () {
      final result = SaleItemModel.fromMap({
        'productId': 'p1', 'productName': 'Test', 'variantId': 'v1', 'variantName': 'V', 'qty': 1, 'price': 10.0,
      });
      expect(result.conditionName, equals(''));
      expect(result.costPrice, equals(0.0));
      expect(result.discount, equals(0.0));
    });

    test('copyWith updates only specified fields', () {
      const item = SaleItemModel(
        productId: 'p1', productName: 'Item', variantId: 'v1', variantName: 'V',
        qty: 2, price: 20.0,
      );
      final copied = item.copyWith(qty: 5, discount: 10.0);
      expect(copied.qty, equals(5));
      expect(copied.discount, equals(10.0));
      expect(copied.productId, equals('p1'));
    });
  });

  group('SaleModel', () {
    final sale = SaleModel(
      id: 'sale_001',
      storeId: 'store_001',
      customerName: 'Juan Dela Cruz',
      employeeName: 'Maria Santos',
      items: [
        const SaleItemModel(
          productId: 'prod_001', productName: 'Coca-Cola 1L',
          variantId: 'v_001', variantName: 'Liter Solo',
          qty: 3, price: 25.00, costPrice: 15.00,
        ),
        const SaleItemModel(
          productId: 'prod_002', productName: 'Lays Classic',
          variantId: 'v_002', variantName: 'Small Pack',
          qty: 2, price: 20.00, costPrice: 12.00,
        ),
      ],
      subtotal: 115.00,
      totalDiscount: 0.00,
      total: 115.00,
      amountPaid: 150.00,
      change: 35.00,
      paymentType: 'cash',
      status: 'completed',
      date: '2026-06-15',
      timestamp: '2026-06-15T14:30:00.000',
      updatedAt: '2026-06-15T14:30:00.000',
    );

    test('profit sums profit across all items', () {
      expect(sale.profit, equals(46.00));
    });

    test('profit returns 0 when items is empty', () {
      final empty = SaleModel(
        id: 's2', storeId: 's1', items: [],
        subtotal: 0, total: 0, amountPaid: 0,
        date: '', timestamp: '', updatedAt: '',
      );
      expect(empty.profit, equals(0.0));
    });

    test('fromMap and toMap roundtrip correctly', () {
      final map = sale.toMap();
      final restored = SaleModel.fromMap(map);
      expect(restored.id, equals('sale_001'));
      expect(restored.customerName, equals('Juan Dela Cruz'));
      expect(restored.items.length, equals(2));
      expect(restored.total, equals(115.00));
      expect(restored.profit, equals(46.00));
    });

    test('fromMap uses defaults when keys are missing', () {
      final result = SaleModel.fromMap({
        'id': 's1', 'storeId': 'st1', 'items': [],
        'subtotal': 0.0, 'total': 0.0, 'amountPaid': 0.0,
        'date': '', 'timestamp': '', 'updatedAt': '',
      });
      expect(result.customerName, equals('Walk-in'));
      expect(result.paymentType, equals('cash'));
      expect(result.status, equals('completed'));
    });

    test('fromMap parses editHistory correctly', () {
      final result = SaleModel.fromMap({
        'id': 's1', 'storeId': 'st1', 'items': [],
        'subtotal': 0.0, 'total': 0.0, 'amountPaid': 0.0,
        'date': '', 'timestamp': '', 'updatedAt': '',
        'editHistory': [
          {'reason': 'Refund - damaged item', 'timestamp': '2026-06-16T10:00:00'},
        ],
      });
      expect(result.editHistory.length, equals(1));
      expect(result.editHistory[0]['reason'], equals('Refund - damaged item'));
    });

    test('toSql and fromSql roundtrip correctly', () {
      final sqlMap = sale.toSql();
      final restored = SaleModel.fromSql(sqlMap);
      expect(restored.id, equals('sale_001'));
      expect(restored.items.length, equals(2));
      expect(restored.profit, equals(46.00));
    });

    test('copyWith updates only specified fields', () {
      final copied = sale.copyWith(status: 'refunded', notes: 'Customer returned items');
      expect(copied.status, equals('refunded'));
      expect(copied.notes, equals('Customer returned items'));
      expect(copied.total, equals(115.00));
    });
  });
}
