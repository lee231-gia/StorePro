import '../core/services/sqlite_service.dart';
import '../core/services/sync_service.dart';
import '../core/utils/app_helpers.dart';
import '../core/utils/session.dart';
import '../models/inventory_model.dart';

class InventoryRepository {
  InventoryRepository._();
  static const _col = 'inventory_logs';
  static const _table = 'inventory_logs';

  static Future<List<InventoryLogModel>> getAll() async {
    final rows = await SQLiteService.query(
      _table,
      where: 'storeId = ?',
      whereArgs: [Session.storeId],
      orderBy: 'date DESC',
    );
    return rows.map(InventoryLogModel.fromMap).toList();
  }

  static Future<void> log(InventoryLogModel entry) async {
    final updated = InventoryLogModel(
      id: AppHelpers.newId(),
      storeId: Session.storeId,
      productId: entry.productId,
      productName: entry.productName,
      variantId: entry.variantId,
      variantName: entry.variantName,
      type: entry.type,
      qty: entry.qty,
      costPrice: entry.costPrice,
      reason: entry.reason,
      employeeId: Session.safeEmployeeId,
      employeeName: Session.safeEmployeeName,
      date: AppHelpers.todayStr(),
      updatedAt: AppHelpers.nowStr(),
    );
    await SyncService.write(
      _col,
      updated.id,
      updated.toMap(),
      _table,
      updated.toSql(),
    );
  }
}
