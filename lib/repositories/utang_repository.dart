import '../core/services/sqlite_service.dart';
import '../core/services/sync_service.dart';
import '../core/utils/app_helpers.dart';
import '../core/utils/session.dart';
import '../models/utang_model.dart';

class UtangRepository {
  UtangRepository._();
  static const _col = 'utang';
  static const _table = 'utang';

  static Future<List<UtangModel>> getAll() async {
    final rows = await SQLiteService.query(
      _table,
      where: 'storeId = ?',
      whereArgs: [Session.storeId],
    );
    return rows.map(UtangModel.fromSql).toList();
  }

  static void syncInBackground(void Function(List<UtangModel>) onSync) {
    SyncService.syncFromFirebase(
      _col,
      _table,
      (r) => UtangModel.fromMap(r).toSql(),
      (rows) => onSync(rows.map(UtangModel.fromSql).toList()),
    );
  }

  static Future<UtangModel> save(UtangModel utang) async {
    final updated = UtangModel(
      id: utang.id.isEmpty ? AppHelpers.newId() : utang.id,
      storeId: Session.storeId,
      customerId: utang.customerId,
      customerName: utang.customerName,
      customerPhone: utang.customerPhone,
      saleId: utang.saleId,
      items: utang.items,
      totalAmount: utang.totalAmount,
      amountPaid: utang.amountPaid,
      startDate: utang.startDate.isEmpty
          ? AppHelpers.todayStr()
          : utang.startDate,
      dueDate: utang.dueDate,
      status: utang.status,
      payments: utang.payments,
      notes: utang.notes,
      updatedAt: AppHelpers.nowStr(),
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

  static Future<UtangModel> addPayment(
    UtangModel utang,
    UtangPaymentModel payment,
  ) async {
    final newPaid = utang.amountPaid + payment.amount;
    final newStatus = newPaid >= utang.totalAmount
        ? 'paid'
        : newPaid > 0
        ? 'partial'
        : 'pending';

    final updated = UtangModel(
      id: utang.id,
      storeId: utang.storeId,
      customerId: utang.customerId,
      customerName: utang.customerName,
      customerPhone: utang.customerPhone,
      saleId: utang.saleId,
      items: utang.items,
      totalAmount: utang.totalAmount,
      amountPaid: newPaid,
      startDate: utang.startDate,
      dueDate: utang.dueDate,
      status: newStatus,
      payments: [...utang.payments, payment],
      notes: utang.notes,
      updatedAt: AppHelpers.nowStr(),
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
}
