import '../core/services/sqlite_service.dart';
import '../core/services/sync_service.dart';
import '../core/utils/app_helpers.dart';
import '../core/utils/session.dart';
import '../models/employee_model.dart';

class EmployeeRepository {
  EmployeeRepository._();
  static const _col = 'employees';
  static const _table = 'employees';

  static Future<List<EmployeeModel>> getAll() async {
    final rows = await SQLiteService.query(
      _table,
      where: 'storeId = ?',
      whereArgs: [Session.storeId],
    );
    return rows.map(EmployeeModel.fromSql).toList();
  }

  static void syncInBackground(void Function(List<EmployeeModel>) onSync) {
    SyncService.syncFromFirebase(
      _col,
      _table,
      (r) => EmployeeModel.fromMap(r).toSql(),
      (rows) => onSync(rows.map(EmployeeModel.fromSql).toList()),
    );
  }

  static Future<void> save(EmployeeModel emp) async {
    final now = AppHelpers.nowStr();
    final updated = EmployeeModel(
      id: emp.id.isEmpty ? AppHelpers.newId() : emp.id,
      storeId: Session.storeId,
      name: emp.name,
      pin: emp.pin,
      isActive: emp.isActive,
      createdAt: emp.createdAt.isEmpty ? now : emp.createdAt,
      updatedAt: now,
    );
    await SyncService.write(
      _col,
      updated.id,
      updated.toMap(),
      _table,
      updated.toSql(),
    );
  }

  static Future<void> delete(String id, String name) async {
    await SQLiteService.delete(_table, id);
    SyncService.deleteInBackground(_col, id);
  }
}
