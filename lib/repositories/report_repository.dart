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

    double totalRevenue = 0;
    double totalProfit = 0;
    double totalDiscount = 0;
    int totalTx = sales.length;
    final Map<String, int> productQty = {};

    for (final sale in sales) {
      totalRevenue += sale.total;
      totalProfit += sale.profit;
      totalDiscount += sale.totalDiscount;
      for (final item in sale.items) {
        productQty[item.productName] =
            (productQty[item.productName] ?? 0) + item.qty;
      }
    }

    final topProducts =
        (productQty.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .take(10)
            .map((e) => {'name': e.key, 'qty': e.value})
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
