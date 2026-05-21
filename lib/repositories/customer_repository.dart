import '../core/services/sqlite_service.dart';
import '../core/services/sync_service.dart';
import '../core/utils/app_helpers.dart';
import '../core/utils/session.dart';
import '../models/activity_log_model.dart';
import '../models/customer_model.dart';

class CustomerRepository {
  CustomerRepository._();
  static const _col = 'customers';
  static const _table = 'customers';

  static Future<List<CustomerModel>> getAll() async {
    final rows = await SQLiteService.query(
      _table,
      where: 'storeId = ?',
      whereArgs: [Session.storeId],
    );
    return rows.map(CustomerModel.fromMap).toList();
  }

  static void syncInBackground(void Function(List<CustomerModel>) onSync) {
    SyncService.syncFromFirebase(
      _col,
      _table,
      (r) => CustomerModel.fromMap(r).toSql(),
      (rows) => onSync(rows.map(CustomerModel.fromMap).toList()),
    );
  }

  static Future<CustomerModel> save(
    CustomerModel customer, {
    bool logActivity = true,
  }) async {
    final now = AppHelpers.nowStr();
    final isNew = customer.id.isEmpty;
    final updated = CustomerModel(
      id: customer.id.isEmpty ? AppHelpers.newId() : customer.id,
      storeId: Session.storeId,
      name: customer.name,
      phone: customer.phone,
      address: customer.address,
      notes: customer.notes,
      totalPurchases: customer.totalPurchases,
      createdAt: customer.createdAt.isEmpty ? now : customer.createdAt,
      updatedAt: now,
    );
    await SyncService.write(
      _col,
      updated.id,
      updated.toMap(),
      _table,
      updated.toSql(),
    );
    if (logActivity) {
      await _log(
        isNew ? 'add_customer' : 'edit_customer',
        updated.id,
        updated.name,
        details: {
          'customerName': updated.name,
          'phone': updated.phone,
          'address': updated.address,
          'totalPurchases': updated.totalPurchases,
        },
      );
    }
    return updated;
  }

  static Future<void> delete(String id) async {
    final rows = await SQLiteService.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
    );
    final name = rows.isEmpty ? '' : CustomerModel.fromMap(rows.first).name;
    await SQLiteService.delete(_table, id);
    SyncService.deleteInBackground(_col, id);
    await _log('delete_customer', id, name);
  }

  static Future<void> addPurchase(String customerId, double amount) async {
    if (customerId.isEmpty) return;
    final rows = await SQLiteService.query(
      _table,
      where: 'id = ?',
      whereArgs: [customerId],
    );
    if (rows.isEmpty) return;
    final c = CustomerModel.fromMap(rows.first);
    final updated = c.copyWith(totalPurchases: c.totalPurchases + amount);
    await save(updated, logActivity: false);
  }

  static Future<void> _log(
    String action,
    String targetId,
    String name, {
    Map<String, dynamic> details = const {},
  }) async {
    if (!Session.trackActivity) return;
    final log = ActivityLogModel(
      id: AppHelpers.newId(),
      storeId: Session.storeId,
      employeeId: Session.safeEmployeeId,
      employeeName: Session.safeEmployeeName,
      action: action,
      targetType: 'customer',
      targetId: targetId,
      targetName: name,
      timestamp: AppHelpers.nowStr(),
      details: details,
    );
    await SyncService.write(
      'activity_logs',
      log.id,
      log.toMap(),
      'activity_logs',
      log.toSql(),
    );
  }
}
