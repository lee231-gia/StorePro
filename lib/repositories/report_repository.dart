import '../core/services/sqlite_service.dart';
import '../core/utils/session.dart';
import '../models/sale_model.dart';
import '../models/inventory_model.dart';

// Reports always read from SQLite — fastest possible
class ReportRepository {
  ReportRepository._();

  // ── SALES IN RANGE ────────────────────────────────────────
  static Future<List<SaleModel>> getSalesInRange(String from, String to) async {
    final rows = await SQLiteService.query(
      'sales',
      where: 'storeId = ? AND date >= ? AND date <= ?',
      whereArgs: [Session.storeId, from, to],
      orderBy: 'date DESC',
    );
    return rows.map(SaleModel.fromSql).toList();
  }

  // ── SUMMARY ───────────────────────────────────────────────
  static Future<Map<String, dynamic>> getSummary(String from, String to) async {
    final sales = await getSalesInRange(from, to);
    return _summarizeSales(sales, from, to);
  }

  static Map<String, dynamic> _summarizeSales(
    List<SaleModel> sales,
    String from,
    String to,
  ) {
    double totalRevenue = 0;
    double totalProfit = 0;
    double totalDiscount = 0;
    int totalTx = sales.length;
    final Map<String, Map<String, dynamic>> productQty = {};

    for (final sale in sales) {
      totalRevenue += sale.total;
      totalProfit += sale.profit;
      totalDiscount += sale.totalDiscount;
      for (final item in sale.items) {
        final key = '${item.productName}||${item.variantName}';
        final current = productQty[key];
        productQty[key] = {
          'name': item.productName,
          'variantName': item.variantName,
          'qty': ((current?['qty'] as int?) ?? 0) + item.qty,
        };
      }
    }

    final topProducts =
        (productQty.values.toList()
              ..sort((a, b) => (b['qty'] as int).compareTo(a['qty'] as int)))
            .take(10)
            .map(
              (e) => {
                'name': e['name'],
                'variantName': e['variantName'],
                'qty': e['qty'],
              },
            )
            .toList();

    return {
      'totalRevenue': totalRevenue,
      'totalProfit': totalProfit,
      'totalDiscount': totalDiscount,
      'totalTx': totalTx,
      'topProducts': topProducts,
      'from': from,
      'to': to,
    };
  }

  static Future<Map<String, Map<String, dynamic>>> getPresetSummaries() async {
    final now = DateTime.now();
    String fmt(DateTime d) =>
        '${d.year}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';

    final yesterday = now.subtract(const Duration(days: 1));
    final ranges = <String, List<String>>{
      'today': [fmt(DateTime(now.year, now.month, now.day)), fmt(now)],
      'yesterday': [
        fmt(DateTime(yesterday.year, yesterday.month, yesterday.day)),
        fmt(DateTime(yesterday.year, yesterday.month, yesterday.day)),
      ],
      'week': [fmt(now.subtract(const Duration(days: 7))), fmt(now)],
      'month': [fmt(DateTime(now.year, now.month, 1)), fmt(now)],
      'year': [fmt(DateTime(now.year, 1, 1)), fmt(now)],
      'total': [fmt(DateTime(2020, 1, 1)), fmt(now)],
    };

    final result = <String, Map<String, dynamic>>{};
    final todaySales = await getSalesInRange(fmt(now), fmt(now));
    final hourStart = now.subtract(const Duration(hours: 1));
    final hourSales = todaySales.where((sale) {
      final timestamp = DateTime.tryParse(sale.timestamp);
      return timestamp != null && timestamp.isAfter(hourStart);
    }).toList();
    result['hour'] = _summarizeSales(hourSales, fmt(now), fmt(now));
    for (final entry in ranges.entries) {
      result[entry.key] = await getSummary(entry.value[0], entry.value[1]);
    }
    return result;
  }

  // ── INVENTORY LOGS ────────────────────────────────────────
  static Future<List<InventoryLogModel>> getInventoryLogs(
    String from,
    String to,
  ) async {
    final rows = await SQLiteService.query(
      'inventory_logs',
      where: 'storeId = ? AND date >= ? AND date <= ?',
      whereArgs: [Session.storeId, from, to],
      orderBy: 'date DESC',
    );
    return rows.map(InventoryLogModel.fromMap).toList();
  }

  // ── ACTIVITY LOGS ─────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getActivityLogs({
    String? employeeId,
    int limit = 100,
  }) async {
    final where = employeeId != null
        ? 'storeId = ? AND employeeId = ?'
        : 'storeId = ?';
    final args = employeeId != null
        ? [Session.storeId, employeeId]
        : [Session.storeId];

    return SQLiteService.query(
      'activity_logs',
      where: where,
      whereArgs: args,
      orderBy: 'timestamp DESC',
      limit: limit,
    );
  }
}
