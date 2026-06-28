import 'package:flutter_test/flutter_test.dart';
import 'package:storepro/core/utils/session.dart';
import 'package:storepro/models/sale_model.dart';
import 'package:storepro/repositories/sale_repository.dart';
import 'package:storepro/repositories/report_repository.dart';
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
    await SQLiteService.deleteWhere('inventory_logs', '1=1', []);
    await SQLiteService.deleteWhere('activity_logs', '1=1', []);
    await SQLiteService.deleteWhere('sync_queue', '1=1', []);
  });

  Future<void> _insertSale({
    required String id,
    required String date,
    double total = 100,
    double amountPaid = 100,
    String paymentType = 'cash',
  }) async {
    final sale = SaleModel(
      id: id,
      storeId: Session.storeId,
      customerName: 'Customer',
      items: [
        SaleItemModel(
          productId: 'p-1', productName: 'Item',
          variantId: 'v-1', variantName: 'Regular',
          qty: 1, price: total, costPrice: total * 0.7,
        ),
      ],
      subtotal: total,
      total: total,
      amountPaid: amountPaid,
      paymentType: paymentType,
      date: date,
      timestamp: '${date}T10:00:00',
      updatedAt: '${date}T10:00:00',
    );
    await SaleRepository.save(sale);
  }

  group('ReportRepository.getSalesInRange', () {
    test('returns sales within date range', () async {
      await _insertSale(id: '', date: '2026-06-25');
      await _insertSale(id: '', date: '2026-06-27');
      await _insertSale(id: '', date: '2026-06-29');
      final range = await ReportRepository.getSalesInRange('2026-06-26', '2026-06-28');
      expect(range.length, equals(1));
      expect(range.first.date, equals('2026-06-27'));
    });

    test('returns empty when no sales in range', () async {
      await _insertSale(id: '', date: '2026-06-01');
      final range = await ReportRepository.getSalesInRange('2026-07-01', '2026-07-31');
      expect(range, isEmpty);
    });
  });

  group('ReportRepository.getSummary', () {
    test('calculates revenue, profit, and cogs correctly', () async {
      await _insertSale(id: '', date: '2026-06-28', total: 300);
      final summary = await ReportRepository.getSummary('2026-06-01', '2026-06-30');
      expect(summary['totalRevenue'], equals(300.0));
      expect(summary['totalProfit'], equals((100 - 70) * 3.0));
      expect(summary['cogs'], equals(70 * 3.0));
      expect(summary['totalTx'], equals(1));
    });

    test('handles multiple sales with mixed payment types', () async {
      await _insertSale(id: '', date: '2026-06-28', total: 500, paymentType: 'cash');
      await _insertSale(id: '', date: '2026-06-28', total: 300, amountPaid: 100, paymentType: 'utang');
      final summary = await ReportRepository.getSummary('2026-06-01', '2026-06-30');
      expect(summary['totalRevenue'], equals(800.0));
      expect(summary['cashCollected'], equals(600.0));
      expect(summary['utangTotal'], equals(200.0));
      expect(summary['totalTx'], equals(2));
    });

    test('returns zero values when no sales', () async {
      final summary = await ReportRepository.getSummary('2026-06-01', '2026-06-30');
      expect(summary['totalRevenue'], equals(0.0));
      expect(summary['totalProfit'], equals(0.0));
      expect(summary['totalTx'], equals(0));
    });
  });

  group('ReportRepository.getPresetSummaries', () {
    test('returns all preset keys', () async {
      final presets = await ReportRepository.getPresetSummaries();
      expect(presets.containsKey('hour'), isTrue);
      expect(presets.containsKey('today'), isTrue);
      expect(presets.containsKey('yesterday'), isTrue);
      expect(presets.containsKey('week'), isTrue);
      expect(presets.containsKey('month'), isTrue);
      expect(presets.containsKey('year'), isTrue);
      expect(presets.containsKey('total'), isTrue);
    });
  });

  group('ReportRepository.getInventoryLogs', () {
    test('returns inventory logs within date range', () async {
      await SQLiteService.upsert('inventory_logs', {
        'id': 'log-1', 'storeId': Session.storeId,
        'productId': 'p-1', 'productName': 'Item A',
        'variantId': 'v-1', 'variantName': 'Regular',
        'type': 'add', 'qty': 10, 'date': '2026-06-25',
        'updatedAt': '2026-06-25T10:00:00',
      });
      await SQLiteService.upsert('inventory_logs', {
        'id': 'log-2', 'storeId': Session.storeId,
        'productId': 'p-2', 'productName': 'Item B',
        'variantId': 'v-2', 'variantName': 'Large',
        'type': 'remove', 'qty': -5, 'date': '2026-06-28',
        'updatedAt': '2026-06-28T10:00:00',
      });
      final logs = await ReportRepository.getInventoryLogs('2026-06-26', '2026-06-30');
      expect(logs.length, equals(1));
      expect(logs.first.id, equals('log-2'));
    });
  });
}
