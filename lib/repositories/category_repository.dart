import '../core/services/sqlite_service.dart';
import '../core/services/sync_service.dart';
import '../core/utils/app_helpers.dart';
import '../core/utils/session.dart';
import '../models/category_model.dart';
import '../models/activity_log_model.dart';

class CategoryRepository {
  CategoryRepository._();
  static const _col = 'categories';
  static const _table = 'categories';

  // ── GET ALL ───────────────────────────────────────────────
  static Future<List<CategoryModel>> getAll() async {
    final rows = await SQLiteService.query(
      _table,
      where: 'storeId = ?',
      whereArgs: [Session.storeId],
    );
    return rows.map(CategoryModel.fromMap).toList();
  }

  static void syncInBackground(void Function(List<CategoryModel>) onSync) {
    SyncService.syncFromFirebase(
      _col,
      _table,
      (r) => CategoryModel.fromMap(r).toSql(),
      (rows) => onSync(rows.map(CategoryModel.fromMap).toList()),
    );
  }

  // ── SAVE ──────────────────────────────────────────────────
  static Future<CategoryModel> save(CategoryModel cat) async {
    final now = AppHelpers.nowStr();
    final updated = CategoryModel(
      id: cat.id.isEmpty ? AppHelpers.newId() : cat.id,
      storeId: Session.storeId,
      name: cat.name,
      details: cat.details,
      iconIndex: cat.iconIndex,
      colorIndex: cat.colorIndex,
      imageUrl: cat.imageUrl,
      updatedAt: now,
    );

    await SyncService.write(
      _col,
      updated.id,
      updated.toMap(),
      _table,
      updated.toSql(),
    );
    await _log(
      cat.id.isEmpty ? 'add_category' : 'edit_category',
      updated.id,
      updated.name,
    );
    return updated;
  }

  // ── DELETE ────────────────────────────────────────────────
  static Future<void> delete(String id, String name) async {
    await SQLiteService.delete(_table, id);
    SyncService.deleteInBackground(_col, id);
    await _log('delete_category', id, name);
  }

  // ── ACTIVITY LOG ──────────────────────────────────────────
  static Future<void> _log(String action, String targetId, String name) async {
    if (!Session.trackActivity) return;
    final log = ActivityLogModel(
      id: AppHelpers.newId(),
      storeId: Session.storeId,
      employeeId: Session.safeEmployeeId,
      employeeName: Session.safeEmployeeName,
      action: action,
      targetType: 'category',
      targetId: targetId,
      targetName: name,
      timestamp: AppHelpers.nowStr(),
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
