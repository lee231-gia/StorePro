import '../../models/activity_log_model.dart';
import '../../models/category_model.dart';
import '../../models/customer_model.dart';
import '../../models/inventory_model.dart';
import '../../models/note_model.dart';
import '../../models/product_model.dart';
import '../../models/product_option_model.dart';
import '../../models/sale_model.dart';
import '../../models/utang_model.dart';
import '../../repositories/employee_repository.dart';
import 'sync_service.dart';

class DataSyncService {
  DataSyncService._();

  static void syncAllInBackground() {
    SyncService.flushInBackground();
    _syncProducts();
    _syncSales();
    _syncUtang();
    _syncCustomers();
    _syncCategories();
    _syncNotes();
    _syncInventoryLogs();
    _syncActivityLogs();
    _syncStoreOptions();
    EmployeeRepository.syncInBackground();
  }

  static void _syncProducts() {
    SyncService.syncFromFirebase(
      'products',
      'products',
      (row) => ProductModel.fromMap(row).toSql(),
      (_) {},
    );
  }

  static void _syncSales() {
    SyncService.syncFromFirebase(
      'sales',
      'sales',
      (row) => SaleModel.fromMap(row).toSql(),
      (_) {},
    );
  }

  static void _syncUtang() {
    SyncService.syncFromFirebase(
      'utang',
      'utang',
      (row) => UtangModel.fromMap(row).toSql(),
      (_) {},
    );
  }

  static void _syncCustomers() {
    SyncService.syncFromFirebase(
      'customers',
      'customers',
      (row) => CustomerModel.fromMap(row).toSql(),
      (_) {},
    );
  }

  static void _syncCategories() {
    SyncService.syncFromFirebase(
      'categories',
      'categories',
      (row) => CategoryModel.fromMap(row).toSql(),
      (_) {},
    );
  }

  static void _syncNotes() {
    SyncService.syncFromFirebase(
      'notes',
      'notes',
      (row) => NoteModel.fromMap(row).toSql(),
      (_) {},
    );
  }

  static void _syncInventoryLogs() {
    SyncService.syncFromFirebase(
      'inventory_logs',
      'inventory_logs',
      (row) => InventoryLogModel.fromMap(row).toSql(),
      (_) {},
    );
  }

  static void _syncActivityLogs() {
    SyncService.syncFromFirebase(
      'activity_logs',
      'activity_logs',
      (row) => ActivityLogModel.fromMap(row).toSql(),
      (_) {},
    );
  }

  static void _syncStoreOptions() {
    SyncService.syncFromFirebase(
      'store_options',
      'store_options',
      (row) => ProductOptionModel.fromMap(row).toSql(),
      (_) {},
    );
  }
}
