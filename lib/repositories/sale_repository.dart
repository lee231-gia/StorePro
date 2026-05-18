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
    _log('new_sale', updated.id, updated.customerName);
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

  static Future<void> delete(String id) async {
    await SQLiteService.delete(_table, id);
    SyncService.deleteInBackground(_col, id);
  }

  static void _log(String action, String targetId, String name) async {
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
    );
    SyncService.write(
      'activity_logs',
      log.id,
      log.toMap(),
      'activity_logs',
      log.toSql(),
    );
  }
}
