import 'package:flutter_test/flutter_test.dart';
import 'package:storepro/core/utils/session.dart';
import 'package:storepro/models/utang_model.dart';
import 'package:storepro/repositories/utang_repository.dart';
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
    await SQLiteService.deleteWhere('utang', '1=1', []);
    await SQLiteService.deleteWhere('sync_queue', '1=1', []);
  });

  group('UtangRepository.save', () {
    test('saves a new utang record', () async {
      final utang = UtangModel(
        id: '',
        storeId: Session.storeId,
        customerId: 'cust-1',
        customerName: 'Juan dela Cruz',
        saleId: 'sale-1',
        items: [
          {'productName': 'Rice 5kg', 'qty': 1, 'price': 280.0},
        ],
        totalAmount: 280.0,
        startDate: '2026-06-28',
        updatedAt: '2026-06-28T10:00:00',
      );
      final saved = await UtangRepository.save(utang);
      expect(saved.id, isNot(equals('')));
      expect(saved.totalAmount, equals(280.0));
      expect(saved.status, equals('pending'));
      expect(saved.customerName, equals('Juan dela Cruz'));
    });

    test('preserves all fields through roundtrip', () async {
      final utang = UtangModel(
        id: '',
        storeId: Session.storeId,
        customerId: 'cust-2',
        customerName: 'Maria Santos',
        customerPhone: '09171234567',
        saleId: 'sale-2',
        items: [
          {'productName': 'Sardines', 'qty': 5, 'price': 25.0},
        ],
        totalAmount: 125.0,
        amountPaid: 25.0,
        startDate: '2026-06-01',
        dueDate: '2026-07-01',
        status: 'partial',
        notes: 'Payment every week',
        updatedAt: '2026-06-28T10:00:00',
      );
      final saved = await UtangRepository.save(utang);
      final all = await UtangRepository.getAll();
      final found = all.firstWhere((u) => u.id == saved.id);
      expect(found.customerName, equals('Maria Santos'));
      expect(found.customerPhone, equals('09171234567'));
      expect(found.totalAmount, equals(125.0));
      expect(found.amountPaid, equals(25.0));
      expect(found.status, equals('partial'));
      expect(found.balance, equals(100.0));
      expect(found.notes, equals('Payment every week'));
    });
  });

  group('UtangRepository.getAll', () {
    test('returns all utang records', () async {
      await UtangRepository.save(
        UtangModel(
          id: '',
          storeId: Session.storeId,
          customerId: 'c-1', customerName: 'A',
          saleId: 's-1', items: [],
          totalAmount: 100, startDate: '2026-06-28',
          updatedAt: '2026-06-28T10:00:00',
        ),
      );
      await UtangRepository.save(
        UtangModel(
          id: '',
          storeId: Session.storeId,
          customerId: 'c-2', customerName: 'B',
          saleId: 's-2', items: [],
          totalAmount: 200, startDate: '2026-06-28',
          updatedAt: '2026-06-28T10:00:00',
        ),
      );
      final all = await UtangRepository.getAll();
      expect(all.length, equals(2));
    });

    test('returns only records for the current store', () async {
      await UtangRepository.save(
        UtangModel(
          id: '',
          storeId: Session.storeId,
          customerId: 'c-1', customerName: 'Store 1',
          saleId: 's-1', items: [],
          totalAmount: 100, startDate: '2026-06-28',
          updatedAt: '2026-06-28T10:00:00',
        ),
      );
      await SQLiteService.upsert('utang', {
        'id': 'other-utang',
        'storeId': 'other-store',
        'customerName': 'Other Store',
        'dataJson': '{"id":"other-utang","customerName":"Other Store"}',
        'totalAmount': 50,
        'updatedAt': '2026-06-28T10:00:00',
      });
      final all = await UtangRepository.getAll();
      expect(all.length, equals(1));
      expect(all.first.customerName, equals('Store 1'));
    });
  });

  group('UtangRepository.addPayment', () {
    test('adds a partial payment and updates status to partial', () async {
      final saved = await UtangRepository.save(
        UtangModel(
          id: '',
          storeId: Session.storeId,
          customerId: 'c-1', customerName: 'Juan',
          saleId: 's-1', items: [],
          totalAmount: 500.0,
          startDate: '2026-06-01',
          updatedAt: '2026-06-28T10:00:00',
        ),
      );
      final payment = UtangPaymentModel(
        id: 'pmt-1',
        amount: 200.0,
        date: '2026-06-15',
        employeeName: 'Cashier',
      );
      final updated = await UtangRepository.addPayment(saved, payment);
      expect(updated.amountPaid, equals(200.0));
      expect(updated.status, equals('partial'));
      expect(updated.payments.length, equals(1));
    });

    test('marks as paid when amount reaches total', () async {
      final saved = await UtangRepository.save(
        UtangModel(
          id: '',
          storeId: Session.storeId,
          customerId: 'c-2', customerName: 'Maria',
          saleId: 's-2', items: [],
          totalAmount: 300.0,
          startDate: '2026-06-01',
          updatedAt: '2026-06-28T10:00:00',
        ),
      );
      final payment = UtangPaymentModel(
        id: 'pmt-2',
        amount: 300.0,
        date: '2026-06-28',
        employeeName: 'Cashier',
      );
      final updated = await UtangRepository.addPayment(saved, payment);
      expect(updated.amountPaid, equals(300.0));
      expect(updated.status, equals('paid'));
      expect(updated.balance, equals(0.0));
    });

    test('accumulates multiple payments', () async {
      final saved = await UtangRepository.save(
        UtangModel(
          id: '',
          storeId: Session.storeId,
          customerId: 'c-3', customerName: 'Pedro',
          saleId: 's-3', items: [],
          totalAmount: 1000.0,
          startDate: '2026-06-01',
          updatedAt: '2026-06-28T10:00:00',
        ),
      );
      final p1 = UtangPaymentModel(id: 'pmt-3a', amount: 300, date: '2026-06-10');
      final after1 = await UtangRepository.addPayment(saved, p1);
      expect(after1.amountPaid, equals(300));
      expect(after1.status, equals('partial'));
      final p2 = UtangPaymentModel(id: 'pmt-3b', amount: 200, date: '2026-06-20');
      final after2 = await UtangRepository.addPayment(after1, p2);
      expect(after2.amountPaid, equals(500));
      expect(after2.status, equals('partial'));
      expect(after2.payments.length, equals(2));
    });
  });

  group('UtangRepository.delete', () {
    test('removes a utang record', () async {
      final saved = await UtangRepository.save(
        UtangModel(
          id: '',
          storeId: Session.storeId,
          customerId: 'c-1', customerName: 'Delete Me',
          saleId: 's-1', items: [],
          totalAmount: 100, startDate: '2026-06-28',
          updatedAt: '2026-06-28T10:00:00',
        ),
      );
      await UtangRepository.delete(saved.id);
      final all = await UtangRepository.getAll();
      expect(all.any((u) => u.id == saved.id), isFalse);
    });
  });
}
