import 'dart:async';

import '../core/services/sqlite_service.dart';
import '../core/services/sync_service.dart';
import '../core/utils/app_helpers.dart';
import '../core/utils/session.dart';
import '../models/employee_model.dart';

class EmployeeRepository {
  EmployeeRepository._();
  static const _col = 'employees';
  static const _table = 'employees';
  static final StreamController<List<EmployeeModel>> _controller =
      StreamController<List<EmployeeModel>>.broadcast();
  static List<EmployeeModel>? _cache;
  static StreamSubscription<String>? _changeSub;
  static bool _syncStarted = false;

  static Stream<List<EmployeeModel>> get stream {
    _ensureListening();
    return _controller.stream;
  }

  static List<EmployeeModel> get cached =>
      List.unmodifiable(_cache ?? const []);

  static void _ensureListening() {
    _changeSub ??= SyncService.changes.listen((collection) {
      if (collection == _col) refresh().ignore();
    });
  }

  static Future<List<EmployeeModel>> getAll() async {
    _ensureListening();
    if (Session.storeId.isEmpty) {
      _cache = const [];
      return const [];
    }
    final cachedEmployees = _cache;
    if (cachedEmployees != null) return List.unmodifiable(cachedEmployees);
    return refresh();
  }

  static Future<List<EmployeeModel>> refresh() async {
    if (Session.storeId.isEmpty) {
      _cache = const [];
      _emit();
      return const [];
    }
    final rows = await SQLiteService.query(
      _table,
      where: 'storeId = ?',
      whereArgs: [Session.storeId],
      orderBy: 'name COLLATE NOCASE ASC',
    );
    _cache = rows
        .map(EmployeeModel.fromSql)
        .where((employee) => employee.name.trim().isNotEmpty)
        .toList(growable: false);
    _emit();
    syncInBackground();
    return List.unmodifiable(_cache ?? const []);
  }

  static void syncInBackground([void Function(List<EmployeeModel>)? onSync]) {
    if (_syncStarted) return;
    _syncStarted = true;
    SyncService.syncFromFirebase(
      _col,
      _table,
      (r) => EmployeeModel.fromMap(r).toSql(),
      (rows) {
        _cache =
            rows
                .map(EmployeeModel.fromSql)
                .where((employee) => employee.name.trim().isNotEmpty)
                .toList(growable: false)
              ..sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
              );
        _emit();
        onSync?.call(List.unmodifiable(_cache ?? const []));
      },
    );
    Future<void>.delayed(const Duration(seconds: 46), () {
      _syncStarted = false;
    }).ignore();
  }

  static Future<EmployeeModel> save(EmployeeModel emp) async {
    final now = AppHelpers.nowStr();
    final updated = EmployeeModel(
      id: emp.id.isEmpty ? AppHelpers.newId() : emp.id,
      storeId: Session.storeId,
      name: emp.name.trim(),
      pin: emp.pin,
      createdAt: emp.createdAt.isEmpty ? now : emp.createdAt,
      updatedAt: now,
    );
    if (updated.name.isEmpty) return updated;
    await SyncService.write(
      _col,
      updated.id,
      updated.toMap(),
      _table,
      updated.toSql(),
    );
    await refresh();
    return updated;
  }

  static Future<EmployeeModel> findOrCreateByName(String rawName) async {
    final name = rawName.trim();
    if (name.isEmpty) {
      final now = AppHelpers.nowStr();
      return EmployeeModel(
        id: 'owner',
        storeId: Session.storeId,
        name: Session.ownerName.isNotEmpty ? Session.ownerName : 'Owner',
        createdAt: now,
        updatedAt: now,
      );
    }
    final employees = await getAll();
    for (final employee in employees) {
      if (employee.name.toLowerCase() == name.toLowerCase()) {
        return employee;
      }
    }
    final now = AppHelpers.nowStr();
    return save(
      EmployeeModel(
        id: '',
        storeId: Session.storeId,
        name: name,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  static Future<void> delete(String id, String name) async {
    await SQLiteService.delete(_table, id);
    SyncService.deleteInBackground(_col, id);
    _cache = (_cache ?? const [])
        .where((employee) => employee.id != id)
        .toList(growable: false);
    _emit();
    if (Session.activeEmployeeId == id) {
      Session.activeEmployeeId = 'owner';
      Session.activeEmployeeName = Session.ownerName.isNotEmpty
          ? Session.ownerName
          : 'Owner';
      Session.employeeSelected = true;
    }
  }

  static void _emit() {
    if (!_controller.isClosed) {
      _controller.add(List.unmodifiable(_cache ?? const []));
    }
  }
}
