import '../core/services/sqlite_service.dart';
import '../core/services/sync_service.dart';
import '../core/utils/app_helpers.dart';
import '../core/utils/session.dart';
import '../models/sale_model.dart';
import '../models/activity_log_model.dart';

class SaleRepository {
  SaleRepository._();
  static const _col = 'sales';
  static const _table = 'sales';

  static Future<List<SaleModel>> getAll() async {
    final rows = await SQLiteService.query(
      _table,
      where: 'storeId = ?',
      whereArgs: [Session.storeId],
      orderBy: 'date DESC',
    );
    return rows.map(SaleModel.fromSql).toList();
  }

  static void syncInBackground(void Function(List<SaleModel>) onSync) {
    SyncService.syncFromFirebase(
      _col,
      _table,
      (r) => SaleModel.fromMap(r).toSql(),
      (rows) => onSync(rows.map(SaleModel.fromSql).toList()),
    );
  }

  static Future<SaleModel> save(SaleModel sale) async {
    final now = AppHelpers.nowStr();
    final updated = SaleModel(
      id: sale.id.isEmpty ? AppHelpers.newId() : sale.id,
      storeId: Session.storeId,
      customerId: sale.customerId,
      customerName: sale.customerName,
      employeeId: sale.employeeId,
      employeeName: sale.employeeName,
      items: sale.items,
      subtotal: sale.subtotal,
      totalDiscount: sale.totalDiscount,
      total: sale.total,
      amountPaid: sale.amountPaid,
      change: sale.change,
      paymentType: sale.paymentType,
      status: sale.status,
      notes: sale.notes,
      date: sale.date.isEmpty ? AppHelpers.todayStr() : sale.date,
      timestamp: sale.timestamp.isEmpty ? now : sale.timestamp,
      updatedAt: now,
      editHistory: sale.editHistory,
    );
    await SyncService.write(
      _col,
      updated.id,
      updated.toMap(),
      _table,
      updated.toSql(),
    );
    _log('new_sale', updated.id, updated.customerName, sale: updated);
    return updated;
  }

  static Future<SaleModel> refund(SaleModel original, SaleModel edited) async {
    final history = List<Map<String, dynamic>>.from(original.editHistory)
      ..add({
        'at': AppHelpers.nowStr(),
        'employee': Session.safeEmployeeName,
        'snapshot': original.toMap(),
      });
    final updated = SaleModel(
      id: original.id,
      storeId: original.storeId,
      customerId: edited.customerId,
      customerName: edited.customerName,
      employeeId: Session.safeEmployeeId,
      employeeName: Session.safeEmployeeName,
      items: edited.items,
      subtotal: edited.subtotal,
      totalDiscount: edited.totalDiscount,
      total: edited.total,
      amountPaid: edited.amountPaid,
      change: edited.change,
      paymentType: edited.paymentType,
      status: 'refunded',
      notes: edited.notes,
      date: original.date,
      timestamp: original.timestamp,
      updatedAt: AppHelpers.nowStr(),
      editHistory: history,
    );
    await SyncService.write(
      _col,
      updated.id,
      updated.toMap(),
      _table,
      updated.toSql(),
    );
    return updated;
  }

  static Future<SaleModel> updateEdited(
    SaleModel sale, {
    String action = 'edit_sale',
  }) async {
    await SyncService.write(_col, sale.id, sale.toMap(), _table, sale.toSql());
    _log(action, sale.id, sale.customerName, sale: sale);
    return sale;
  }

  static Future<void> delete(String id) async {
    await SQLiteService.delete(_table, id);
    SyncService.deleteInBackground(_col, id);
  }

  static void _log(
    String action,
    String targetId,
    String name, {
    SaleModel? sale,
  }) async {
    if (!Session.trackActivity) return;
    final log = ActivityLogModel(
      id: AppHelpers.newId(),
      storeId: Session.storeId,
      employeeId: Session.safeEmployeeId,
      employeeName: Session.safeEmployeeName,
      action: action,
      targetType: 'sale',
      targetId: targetId,
      targetName: name,
      timestamp: AppHelpers.nowStr(),
      details: sale == null ? const {} : _saleDetails(sale),
    );
    SyncService.write(
      'activity_logs',
      log.id,
      log.toMap(),
      'activity_logs',
      log.toSql(),
    );
  }

  static Map<String, dynamic> _saleDetails(SaleModel sale) {
    final cashPaid = sale.paymentType == 'utang'
        ? sale.amountPaid.clamp(0, sale.total).toDouble()
        : sale.total;
    final utangBalance = sale.paymentType == 'utang'
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
      'items': sale.items
          .map(
            (item) => {
              'productName': item.productName,
              'variantName': item.variantName,
              'conditionName': item.conditionName,
              'qty': item.qty,
              'price': item.price,
              'costPrice': item.costPrice,
              'discount': item.discount,
              'subtotal': item.subtotal,
            },
          )
          .toList(),
    };
  }
}
