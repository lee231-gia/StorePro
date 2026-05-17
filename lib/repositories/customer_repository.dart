import '../core/services/sqlite_service.dart';
import '../core/services/sync_service.dart';
import '../core/utils/app_helpers.dart';
import '../core/utils/session.dart';
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

  static Future<CustomerModel> save(CustomerModel customer) async {
    final now = AppHelpers.nowStr();
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
    return updated;
  }

  static Future<void> delete(String id) async {
    await SQLiteService.delete(_table, id);
    SyncService.deleteInBackground(_col, id);
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
    await save(updated);
  }
}
