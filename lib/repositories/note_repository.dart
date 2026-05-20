import '../core/services/sqlite_service.dart';
import '../core/services/sync_service.dart';
import '../core/services/notification_service.dart';
import '../core/utils/app_helpers.dart';
import '../core/utils/session.dart';
import '../models/note_model.dart';

class NoteRepository {
  NoteRepository._();
  static const _col = 'notes';
  static const _table = 'notes';

  static Future<List<NoteModel>> getAll() async {
    final rows = await SQLiteService.query(
      _table,
      where: 'storeId = ?',
      whereArgs: [Session.storeId],
    );
    return rows.map(NoteModel.fromSql).toList();
  }

  static void syncInBackground(void Function(List<NoteModel>) onSync) {
    SyncService.syncFromFirebase(
      _col,
      _table,
      (r) => NoteModel.fromMap(r).toSql(),
      (rows) => onSync(rows.map(NoteModel.fromSql).toList()),
    );
  }

  static Future<NoteModel> save(NoteModel note) async {
    final updated = NoteModel(
      id: note.id.isEmpty ? AppHelpers.newId() : note.id,
      storeId: Session.storeId,
      type: note.type,
      title: note.title,
      content: note.content,
      date: note.date.isEmpty ? AppHelpers.nowStr() : note.date,
      reminderAt: note.reminderAt,
      done: note.done,
      updatedAt: AppHelpers.nowStr(),
    );
    await SyncService.write(
      _col,
      updated.id,
      updated.toMap(),
      _table,
      updated.toSql(),
    );

    await NotificationService.cancel(updated.id.hashCode);
    if (updated.reminderAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(updated.reminderAt);
        if (dt.isAfter(DateTime.now())) {
          final overview = updated.content
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
          final reminderBody = overview.isEmpty
              ? AppHelpers.formatDateTime(dt)
              : '${AppHelpers.formatDateTime(dt)} - $overview';
          await NotificationService.schedule(
            id: updated.id.hashCode,
            title: updated.title,
            body: reminderBody,
            scheduledTime: dt,
          );
        }
      } catch (_) {}
    }
    return updated;
  }

  static Future<void> delete(String id) async {
    await SQLiteService.delete(_table, id);
    SyncService.deleteInBackground(_col, id);
    NotificationService.cancel(id.hashCode);
  }
}
