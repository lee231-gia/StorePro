import '../core/services/sqlite_service.dart';
import '../core/utils/session.dart';
import '../models/sale_model.dart';
import '../models/inventory_model.dart';
import '../models/activity_log_model.dart';
import '../models/product_model.dart';

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
    double grossRevenue = 0;
    double totalProfit = 0;
    double totalDiscount = 0;
    double cogs = 0;
    double cashCollected = 0;
    double utangTotal = 0;
    int totalTx = sales.length;
    final Map<String, Map<String, dynamic>> productQty = {};

    for (final sale in sales) {
      totalRevenue += sale.total;
      grossRevenue += sale.subtotal;
      totalProfit += sale.profit;
      totalDiscount += sale.totalDiscount;
      if (sale.paymentType == 'utang' || sale.paymentType == 'multi') {
        final cash = sale.amountPaid.clamp(0, sale.total).toDouble();
        cashCollected += cash;
        utangTotal += (sale.total - cash).clamp(0, sale.total).toDouble();
      } else {
        cashCollected += sale.total;
      }
      for (final item in sale.items) {
        final key = '${item.productId}||${item.variantId}';
        final current = productQty[key];
        final itemCogs = item.costPrice * item.qty;
        cogs += itemCogs;
        productQty[key] = {
          'productId': item.productId,
          'variantId': item.variantId,
          'name': item.productName,
          'variantName': item.variantName,
          'qty': ((current?['qty'] as int?) ?? 0) + item.qty,
          'revenue':
              ((current?['revenue'] as num?)?.toDouble() ?? 0) + item.subtotal,
          'profit':
              ((current?['profit'] as num?)?.toDouble() ?? 0) + item.profit,
        };
      }
    }

    final topProducts =
        (productQty.values.toList()
              ..sort((a, b) => (b['qty'] as int).compareTo(a['qty'] as int)))
            .take(10)
            .map(
              (e) => {
                'productId': e['productId'],
                'variantId': e['variantId'],
                'name': e['name'],
                'variantName': e['variantName'],
                'qty': e['qty'],
                'revenue': e['revenue'],
                'profit': e['profit'],
              },
            )
            .toList();

    return {
      'grossRevenue': grossRevenue,
      'totalRevenue': totalRevenue,
      'netRevenue': totalRevenue,
      'totalProfit': totalProfit,
      'totalDiscount': totalDiscount,
      'cogs': cogs,
      'cashCollected': cashCollected,
      'utangTotal': utangTotal,
      'totalTx': totalTx,
      'topProducts': topProducts,
      'sales': sales
          .map(
            (sale) => {
              'id': sale.id,
              'date': sale.date,
              'timestamp': sale.timestamp,
              'customerName': sale.customerName,
              'paymentType': sale.paymentType,
              'subtotal': sale.subtotal,
              'discount': sale.totalDiscount,
              'total': sale.total,
              'profit': sale.profit,
              'items': sale.items.map((item) => item.toMap()).toList(),
            },
          )
          .toList(),
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

    final rows = await SQLiteService.query(
      'activity_logs',
      where: where,
      whereArgs: args,
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    final logs = rows
        .map((row) => ActivityLogModel.fromMap(row).toMap())
        .toList();
    final synthetic = await _legacyActivityLogs(employeeId: employeeId);
    final explicitKeys = logs
        .map(
          (log) =>
              '${log['action'] ?? ''}|${log['targetType'] ?? ''}|${log['targetId'] ?? ''}',
        )
        .toSet();
    logs.addAll(
      synthetic.where((log) {
        final key =
            '${log['action'] ?? ''}|${log['targetType'] ?? ''}|${log['targetId'] ?? ''}';
        return !explicitKeys.contains(key);
      }),
    );
    logs.sort(
      (a, b) => (b['timestamp'] ?? '').toString().compareTo(
        (a['timestamp'] ?? '').toString(),
      ),
    );
    return logs.take(limit).toList();
  }

  static Future<List<Map<String, dynamic>>> _legacyActivityLogs({
    String? employeeId,
  }) async {
    final logs = <ActivityLogModel>[];
    bool includeEmployee(String id) => employeeId == null || employeeId == id;

    try {
      final sales = await getSalesInRange('2020-01-01', '2099-12-31');
      for (final sale in sales) {
        final empId = sale.employeeId.isEmpty ? 'owner' : sale.employeeId;
        if (!includeEmployee(empId)) continue;
        logs.add(
          ActivityLogModel(
            id: 'legacy-sale-${sale.id}',
            storeId: Session.storeId,
            employeeId: empId,
            employeeName: sale.employeeName.isEmpty
                ? Session.safeEmployeeName
                : sale.employeeName,
            action: 'new_sale',
            targetType: 'sale',
            targetId: sale.id,
            targetName: sale.customerName,
            timestamp: sale.timestamp.isNotEmpty
                ? sale.timestamp
                : _dateFallback(sale.date),
            details: _saleDetails(sale),
          ),
        );
      }
    } catch (_) {}

    try {
      final inventoryRows = await SQLiteService.query(
        'inventory_logs',
        where: 'storeId = ?',
        whereArgs: [Session.storeId],
        orderBy: 'updatedAt DESC',
      );
      for (final row in inventoryRows) {
        final entry = InventoryLogModel.fromMap(row);
        final empId = entry.employeeId.isEmpty ? 'owner' : entry.employeeId;
        if (!includeEmployee(empId)) continue;
        logs.add(
          ActivityLogModel(
            id: 'legacy-inventory-${entry.id}',
            storeId: Session.storeId,
            employeeId: empId,
            employeeName: entry.employeeName.isEmpty
                ? Session.safeEmployeeName
                : entry.employeeName,
            action: entry.qty >= 0 ? 'inventory_add' : 'inventory_remove',
            targetType: 'inventory',
            targetId: entry.id,
            targetName: entry.productName,
            timestamp: entry.updatedAt.isNotEmpty
                ? entry.updatedAt
                : _dateFallback(entry.date),
            details: {
              'productName': entry.productName,
              'variantName': entry.variantName,
              'qty': entry.qty,
              'reason': entry.reason,
              'costPrice': entry.costPrice,
            },
          ),
        );
      }
    } catch (_) {}

    try {
      final productRows = await SQLiteService.query(
        'products',
        where: 'storeId = ?',
        whereArgs: [Session.storeId],
      );
      for (final row in productRows) {
        final product = ProductModel.fromSql(row);
        if (!includeEmployee('owner')) continue;
        logs.add(
          ActivityLogModel(
            id: 'legacy-product-${product.id}',
            storeId: Session.storeId,
            employeeId: 'owner',
            employeeName: Session.safeEmployeeName,
            action: 'add_product',
            targetType: 'product',
            targetId: product.id,
            targetName: product.name,
            timestamp: product.updatedAt.isNotEmpty
                ? product.updatedAt
                : _dateFallback(product.addedOn),
            details: {
              'productName': product.name,
              'variantCount': product.variants.length,
              'variants': product.variants
                  .map(
                    (variant) => {
                      'name': variant.name,
                      'stock': variant.totalStock,
                      'price': variant.price,
                      'costPrice': variant.costPrice,
                    },
                  )
                  .toList(),
            },
          ),
        );
      }
    } catch (_) {}

    for (final spec in const [
      _LegacyTableSpec(
        table: 'categories',
        action: 'add_category',
        targetType: 'category',
        targetNameColumn: 'name',
        timestampColumn: 'updatedAt',
      ),
      _LegacyTableSpec(
        table: 'customers',
        action: 'add_customer',
        targetType: 'customer',
        targetNameColumn: 'name',
        timestampColumn: 'updatedAt',
      ),
      _LegacyTableSpec(
        table: 'notes',
        action: 'save_note',
        targetType: 'note',
        targetNameColumn: 'title',
        timestampColumn: 'updatedAt',
      ),
      _LegacyTableSpec(
        table: 'utang',
        action: 'create_utang',
        targetType: 'utang',
        targetNameColumn: 'customerName',
        timestampColumn: 'updatedAt',
      ),
    ]) {
      try {
        final rows = await SQLiteService.query(
          spec.table,
          where: 'storeId = ?',
          whereArgs: [Session.storeId],
          orderBy: '${spec.timestampColumn} DESC',
        );
        for (final row in rows) {
          if (!includeEmployee('owner')) continue;
          logs.add(
            ActivityLogModel(
              id: 'legacy-${spec.table}-${row['id'] ?? ''}',
              storeId: Session.storeId,
              employeeId: 'owner',
              employeeName: Session.safeEmployeeName,
              action: spec.action,
              targetType: spec.targetType,
              targetId: (row['id'] ?? '').toString(),
              targetName: (row[spec.targetNameColumn] ?? '').toString(),
              timestamp: _dateFallback(
                (row[spec.timestampColumn] ?? '').toString(),
              ),
              details: Map<String, dynamic>.from(row),
            ),
          );
        }
      } catch (_) {}
    }

    return logs.map((log) => log.toMap()).toList();
  }

  static String _dateFallback(String value) {
    if (value.trim().isEmpty) return DateTime.now().toIso8601String();
    if (DateTime.tryParse(value) != null && value.length > 10) return value;
    return '${value.trim()}T00:00:00.000';
  }

  static Map<String, dynamic> _saleDetails(SaleModel sale) {
    final cashPaid = sale.paymentType == 'utang' || sale.paymentType == 'multi'
        ? sale.amountPaid.clamp(0, sale.total).toDouble()
        : sale.total;
    final utangBalance =
        sale.paymentType == 'utang' || sale.paymentType == 'multi'
        ? (sale.total - cashPaid).clamp(0, sale.total).toDouble()
        : 0.0;
    final cogs = sale.items.fold(
      0.0,
      (sum, item) => sum + (item.costPrice * item.qty),
    );

    return {
      'customerName': sale.customerName,
      'grandTotal': sale.total,
      'cash': cashPaid,
      'utang': utangBalance,
      'subtotal': sale.subtotal,
      'discount': sale.totalDiscount,
      'cogs': cogs,
      'profit': sale.profit,
      'paymentType': sale.paymentType,
      'items': sale.items.map((item) => item.toMap()).toList(),
    };
  }
}

class _LegacyTableSpec {
  final String table;
  final String action;
  final String targetType;
  final String targetNameColumn;
  final String timestampColumn;

  const _LegacyTableSpec({
    required this.table,
    required this.action,
    required this.targetType,
    required this.targetNameColumn,
    required this.timestampColumn,
  });
}
