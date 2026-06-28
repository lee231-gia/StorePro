import 'package:flutter_test/flutter_test.dart';
import 'package:storepro/models/utang_model.dart';

void main() {
  group('UtangPaymentModel', () {
    test('fromMap and toMap roundtrip correctly', () {
      const original = UtangPaymentModel(
        id: 'pay_001',
        amount: 250.00,
        method: 'cash',
        date: '2026-06-20',
        employeeName: 'Maria Santos',
      );
      final map = original.toMap();
      final restored = UtangPaymentModel.fromMap(map);
      expect(restored.amount, equals(250.00));
      expect(restored.method, equals('cash'));
      expect(restored.employeeName, equals('Maria Santos'));
    });

    test('fromMap uses defaults when keys are missing', () {
      final result = UtangPaymentModel.fromMap({'id': 'p1', 'amount': 0.0, 'date': ''});
      expect(result.method, equals('cash'));
      expect(result.paidItemId, equals(''));
      expect(result.paidQty, equals(0));
    });

    test('item payment serializes correctly', () {
      const payment = UtangPaymentModel(
        id: 'pay_002',
        amount: 50.00,
        method: 'item',
        paidItemId: 'variant_001',
        paidItemName: 'Coca-Cola 1L',
        paidQty: 2,
        date: '2026-06-21',
      );
      final map = payment.toMap();
      expect(map['method'], equals('item'));
      expect(map['paidItemName'], equals('Coca-Cola 1L'));
      expect(map['paidQty'], equals(2));
    });
  });

  group('UtangModel', () {
    test('balance returns totalAmount minus amountPaid', () {
      const utang = UtangModel(
        id: 'utang_001',
        storeId: 'store_001',
        customerId: 'cust_001',
        customerName: 'Juan Dela Cruz',
        saleId: 'sale_001',
        items: [
          {'productId': 'prod_001', 'name': 'Coca-Cola 1L', 'qty': 5, 'price': 25.00},
        ],
        totalAmount: 500.00,
        amountPaid: 200.00,
        startDate: '2026-06-01',
        dueDate: '2026-07-01',
        status: 'partial',
        updatedAt: '2026-06-20',
      );
      expect(utang.balance, equals(300.00));
    });

    test('balance clamps to 0 when overpaid', () {
      const utang = UtangModel(
        id: 'utang_002',
        storeId: 'store_001',
        customerId: 'cust_001',
        customerName: 'Maria Santos',
        saleId: 'sale_002',
        items: [],
        totalAmount: 200.00,
        amountPaid: 250.00,
        startDate: '2026-06-01',
        status: 'paid',
        updatedAt: '2026-06-15',
      );
      expect(utang.balance, equals(0.0));
    });

    test('balance returns totalAmount when nothing paid', () {
      const utang = UtangModel(
        id: 'utang_003',
        storeId: 'store_001',
        customerId: 'cust_001',
        customerName: 'Pedro Reyes',
        saleId: 'sale_003',
        items: [],
        totalAmount: 350.00,
        amountPaid: 0.00,
        startDate: '2026-06-10',
        status: 'pending',
        updatedAt: '2026-06-10',
      );
      expect(utang.balance, equals(350.00));
    });

    test('fromMap and toMap roundtrip correctly', () {
      const original = UtangModel(
        id: 'utang_001',
        storeId: 'store_001',
        customerId: 'cust_001',
        customerName: 'Juan Dela Cruz',
        customerPhone: '09171234567',
        saleId: 'sale_001',
        items: [
          {'productId': 'prod_001', 'name': 'Coca-Cola 1L', 'qty': 5, 'price': 25.00},
        ],
        totalAmount: 500.00,
        amountPaid: 200.00,
        startDate: '2026-06-01',
        dueDate: '2026-07-01',
        status: 'partial',
        payments: [
          UtangPaymentModel(id: 'pay_001', amount: 200.00, date: '2026-06-15'),
        ],
        notes: 'First payment received',
        updatedAt: '2026-06-20',
      );
      final map = original.toMap();
      final restored = UtangModel.fromMap(map);
      expect(restored.customerName, equals('Juan Dela Cruz'));
      expect(restored.totalAmount, equals(500.00));
      expect(restored.balance, equals(300.00));
      expect(restored.payments.length, equals(1));
      expect(restored.notes, equals('First payment received'));
    });

    test('fromMap uses defaults when keys are missing', () {
      final result = UtangModel.fromMap({
        'id': 'u1', 'storeId': 's1', 'customerId': 'c1', 'customerName': 'N',
        'saleId': 'sl1', 'items': [], 'totalAmount': 0.0, 'startDate': '',
        'updatedAt': '',
      });
      expect(result.status, equals('pending'));
      expect(result.payments, isEmpty);
      expect(result.notes, equals(''));
    });

    test('toSql and fromSql roundtrip correctly', () {
      const utang = UtangModel(
        id: 'utang_004',
        storeId: 'store_001',
        customerId: 'cust_002',
        customerName: 'Ana Lopez',
        saleId: 'sale_004',
        items: [],
        totalAmount: 150.00,
        amountPaid: 50.00,
        startDate: '2026-06-15',
        status: 'partial',
        updatedAt: '2026-06-18',
      );
      final sqlMap = utang.toSql();
      final restored = UtangModel.fromSql(sqlMap);
      expect(restored.id, equals('utang_004'));
      expect(restored.balance, equals(100.00));
      expect(restored.status, equals('partial'));
    });
  });
}
