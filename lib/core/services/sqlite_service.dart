import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../utils/session.dart';

class SQLiteService {
  SQLiteService._();
  static Database? _db;
  static Future<Database>? _dbFuture;
  static final Map<String, Set<String>> _columnCache = {};
  static final Map<String, List<Map<String, dynamic>>> _tableInfoCache = {};

  static const Duration timeout = Duration(seconds: 5);

  static Future<Database> get db async {
    if (_db != null) return _db!;
    _dbFuture ??= _init();
    try {
      _db = await _dbFuture!.timeout(timeout);
      return _db!;
    } catch (_) {
      _dbFuture = null;
      rethrow;
    }
  }

  static Future<void> init() async {
    await db;
  }

  static void warmUp() {
    db.ignore();
  }

  // ── INITIALIZE ────────────────────────────────────────────
  static Future<Database> _init() async {
    final path = join(await getDatabasesPath(), 'storepro.db');
    return openDatabase(path, version: 1, onCreate: _create, onOpen: _onOpen);
  }

  static Future<void> _onOpen(Database db) async {
    await _create(db, 1);
    await _ensureTables(db);
    await _ensureColumns(db);
    await _backfillLegacyColumns(db);
    await _ensureIndexes(db);
  }

  // ── CREATE TABLES ─────────────────────────────────────────
  static Future<void> _create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id TEXT PRIMARY KEY, storeId TEXT, name TEXT,
        categoryId TEXT, categoryName TEXT,
        description TEXT, hasVariants INTEGER,
        iconIndex INTEGER, colorIndex INTEGER, colorHex TEXT, imageUrl TEXT,
        costPrice REAL, addedOn TEXT, updatedAt TEXT,
        dataJson TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id TEXT PRIMARY KEY, storeId TEXT, name TEXT,
        details TEXT, iconIndex INTEGER, colorIndex INTEGER, colorHex TEXT,
        imageUrl TEXT, updatedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sales (
        id TEXT PRIMARY KEY, storeId TEXT, customerId TEXT,
        customerName TEXT, employeeId TEXT, employeeName TEXT,
        date TEXT, status TEXT, total REAL,
        amountPaid REAL, change REAL, paymentType TEXT,
        notes TEXT, updatedAt TEXT, dataJson TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS utang (
        id TEXT PRIMARY KEY, storeId TEXT, customerId TEXT,
        customerName TEXT, saleId TEXT, totalAmount REAL,
        amountPaid REAL, balance REAL, startDate TEXT,
        dueDate TEXT, status TEXT, updatedAt TEXT, dataJson TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS customers (
        id TEXT PRIMARY KEY, storeId TEXT, name TEXT,
        phone TEXT, address TEXT, notes TEXT,
        totalPurchases REAL, createdAt TEXT, updatedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS employees (
        id TEXT PRIMARY KEY, storeId TEXT, name TEXT,
        pin TEXT, createdAt TEXT, updatedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS notes (
        id TEXT PRIMARY KEY, storeId TEXT, type TEXT,
        title TEXT, content TEXT, date TEXT,
        reminderAt TEXT, done INTEGER, updatedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS store_options (
        id TEXT PRIMARY KEY, storeId TEXT, type TEXT,
        value TEXT, pcsPerUnit INTEGER, updatedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS inventory_logs (
        id TEXT PRIMARY KEY, storeId TEXT, productId TEXT,
        productName TEXT, variantId TEXT, variantName TEXT,
        type TEXT, qty INTEGER, costPrice REAL, reason TEXT,
        employeeId TEXT, employeeName TEXT,
        date TEXT, updatedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS activity_logs (
        id TEXT PRIMARY KEY, storeId TEXT, employeeId TEXT,
        employeeName TEXT, action TEXT, targetType TEXT,
        targetId TEXT, targetName TEXT, timestamp TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id TEXT PRIMARY KEY, collection TEXT,
        docId TEXT, action TEXT, dataJson TEXT,
        createdAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS store_profiles (
        id TEXT PRIMARY KEY, dataJson TEXT, updatedAt TEXT
      )
    ''');
  }

  static Future<void> _ensureTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS store_profiles (
        id TEXT PRIMARY KEY, dataJson TEXT, updatedAt TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id TEXT PRIMARY KEY, collection TEXT,
        docId TEXT, action TEXT, dataJson TEXT,
        createdAt TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS store_options (
        id TEXT PRIMARY KEY, storeId TEXT, type TEXT,
        value TEXT, pcsPerUnit INTEGER, updatedAt TEXT
      )
    ''');
  }

  static Future<void> _ensureColumns(Database db) async {
    await _ensureTableColumns(db, 'products', const {
      'storeId': 'TEXT',
      'name': 'TEXT',
      'categoryId': 'TEXT',
      'categoryName': 'TEXT',
      'description': 'TEXT',
      'hasVariants': 'INTEGER',
      'iconIndex': 'INTEGER',
      'colorIndex': 'INTEGER',
      'colorHex': 'TEXT',
      'imageUrl': 'TEXT',
      'costPrice': 'REAL',
      'addedOn': 'TEXT',
      'updatedAt': 'TEXT',
      'dataJson': 'TEXT',
    });
    await _ensureTableColumns(db, 'categories', const {
      'storeId': 'TEXT',
      'name': 'TEXT',
      'details': 'TEXT',
      'iconIndex': 'INTEGER',
      'colorIndex': 'INTEGER',
      'colorHex': 'TEXT',
      'imageUrl': 'TEXT',
      'updatedAt': 'TEXT',
    });
    await _ensureTableColumns(db, 'sales', const {
      'storeId': 'TEXT',
      'customerId': 'TEXT',
      'customerName': 'TEXT',
      'employeeId': 'TEXT',
      'employeeName': 'TEXT',
      'date': 'TEXT',
      'status': 'TEXT',
      'total': 'REAL',
      'amountPaid': 'REAL',
      'change': 'REAL',
      'paymentType': 'TEXT',
      'notes': 'TEXT',
      'updatedAt': 'TEXT',
      'dataJson': 'TEXT',
    });
    await _ensureTableColumns(db, 'utang', const {
      'storeId': 'TEXT',
      'customerId': 'TEXT',
      'customerName': 'TEXT',
      'saleId': 'TEXT',
      'totalAmount': 'REAL',
      'amountPaid': 'REAL',
      'balance': 'REAL',
      'startDate': 'TEXT',
      'dueDate': 'TEXT',
      'status': 'TEXT',
      'updatedAt': 'TEXT',
      'dataJson': 'TEXT',
    });
    await _ensureTableColumns(db, 'customers', const {
      'storeId': 'TEXT',
      'name': 'TEXT',
      'phone': 'TEXT',
      'address': 'TEXT',
      'notes': 'TEXT',
      'totalPurchases': 'REAL',
      'createdAt': 'TEXT',
      'updatedAt': 'TEXT',
    });
    await _ensureTableColumns(db, 'employees', const {
      'storeId': 'TEXT',
      'name': 'TEXT',
      'pin': 'TEXT',
      'createdAt': 'TEXT',
      'updatedAt': 'TEXT',
    });
    await _ensureTableColumns(db, 'notes', const {
      'storeId': 'TEXT',
      'type': 'TEXT',
      'title': 'TEXT',
      'content': 'TEXT',
      'date': 'TEXT',
      'reminderAt': 'TEXT',
      'done': 'INTEGER',
      'updatedAt': 'TEXT',
    });
    await _ensureTableColumns(db, 'store_options', const {
      'storeId': 'TEXT',
      'type': 'TEXT',
      'value': 'TEXT',
      'pcsPerUnit': 'INTEGER',
      'updatedAt': 'TEXT',
    });
    await _ensureTableColumns(db, 'inventory_logs', const {
      'storeId': 'TEXT',
      'productId': 'TEXT',
      'productName': 'TEXT',
      'variantId': 'TEXT',
      'variantName': 'TEXT',
      'type': 'TEXT',
      'qty': 'INTEGER',
      'costPrice': 'REAL',
      'reason': 'TEXT',
      'employeeId': 'TEXT',
      'employeeName': 'TEXT',
      'date': 'TEXT',
      'updatedAt': 'TEXT',
    });
    await _ensureTableColumns(db, 'activity_logs', const {
      'storeId': 'TEXT',
      'employeeId': 'TEXT',
      'employeeName': 'TEXT',
      'action': 'TEXT',
      'targetType': 'TEXT',
      'targetId': 'TEXT',
      'targetName': 'TEXT',
      'timestamp': 'TEXT',
    });
    await _ensureTableColumns(db, 'sync_queue', const {
      'collection': 'TEXT',
      'docId': 'TEXT',
      'action': 'TEXT',
      'dataJson': 'TEXT',
      'createdAt': 'TEXT',
    });
    await _ensureTableColumns(db, 'store_profiles', const {
      'dataJson': 'TEXT',
      'updatedAt': 'TEXT',
    });
  }

  static Future<void> _ensureTableColumns(
    Database db,
    String table,
    Map<String, String> columns,
  ) async {
    for (final entry in columns.entries) {
      await _addColumn(db, table, entry.key, entry.value);
    }
  }

  static Future<void> _addColumn(
    Database db,
    String table,
    String column,
    String type,
  ) async {
    try {
      final info = await db.rawQuery('PRAGMA table_info($table)');
      if (info.isEmpty) return;
      final exists = info.any((row) => row['name'] == column);
      if (!exists) {
        await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
        _columnCache.remove(table);
        _tableInfoCache.remove(table);
      }
    } catch (_) {
      // A malformed local DB must not prevent the app from opening.
    }
  }

  // ── GENERIC CRUD ──────────────────────────────────────────
  static Future<void> _ensureIndexes(Database db) async {
    await _createIndex(db, 'idx_products_store', 'products', const ['storeId']);
    await _createIndex(db, 'idx_categories_store', 'categories', const [
      'storeId',
    ]);
    await _createIndex(db, 'idx_sales_store_date', 'sales', const [
      'storeId',
      'date',
    ]);
    await _createIndex(db, 'idx_customers_store', 'customers', const [
      'storeId',
    ]);
    await _createIndex(db, 'idx_employees_store', 'employees', const [
      'storeId',
    ]);
    await _createIndex(db, 'idx_notes_store', 'notes', const ['storeId']);
    await _createIndex(
      db,
      'idx_store_options_store_type',
      'store_options',
      const ['storeId', 'type'],
    );
    await _createIndex(db, 'idx_utang_store', 'utang', const ['storeId']);
    await _createIndex(
      db,
      'idx_inventory_logs_store_date',
      'inventory_logs',
      const ['storeId', 'date'],
    );
    await _createIndex(
      db,
      'idx_activity_logs_store_time',
      'activity_logs',
      const ['storeId', 'timestamp'],
    );
  }

  static Future<void> _createIndex(
    Database db,
    String indexName,
    String table,
    List<String> columns,
  ) async {
    try {
      final info = await db.rawQuery('PRAGMA table_info($table)');
      if (info.isEmpty) return;
      final existingColumns = info.map((row) => row['name']).toSet();
      if (!columns.every(existingColumns.contains)) return;
      await db.execute(
        'CREATE INDEX IF NOT EXISTS $indexName ON $table(${columns.join(', ')})',
      );
    } catch (_) {
      // Local indexes are an optimization only. A bad index must not block open.
    }
  }

  static Future<void> _backfillLegacyColumns(Database db) async {
    for (final table in const [
      'products',
      'categories',
      'sales',
      'utang',
      'customers',
      'employees',
      'notes',
      'inventory_logs',
      'activity_logs',
      'store_options',
    ]) {
      try {
        final columns = await _columnsFor(db, table);
        if (columns.contains('storeId') && columns.contains('store_id')) {
          await db.execute(
            "UPDATE $table SET storeId = store_id "
            "WHERE (storeId IS NULL OR storeId = '') "
            "AND store_id IS NOT NULL",
          );
        }
      } catch (_) {}
    }
  }

  static Future<Set<String>> _columnsFor(Database db, String table) async {
    final cached = _columnCache[table];
    if (cached != null) return cached;
    final info = await _tableInfoFor(db, table);
    final columns = info.map((row) => row['name'].toString()).toSet();
    _columnCache[table] = columns;
    return columns;
  }

  static Future<List<Map<String, dynamic>>> _tableInfoFor(
    Database db,
    String table,
  ) async {
    final cached = _tableInfoCache[table];
    if (cached != null) return cached;
    final info = await db.rawQuery('PRAGMA table_info($table)');
    _tableInfoCache[table] = info;
    return info;
  }

  static Future<Map<String, dynamic>> _prepareRow(
    Database db,
    String table,
    Map<String, dynamic> data,
  ) async {
    final info = await _tableInfoFor(db, table);
    final columns = info.map((row) => row['name'].toString()).toSet();
    final expanded = Map<String, dynamic>.from(data);

    for (final entry in data.entries) {
      final snake = _camelToSnake(entry.key);
      if (columns.contains(snake)) expanded[snake] = entry.value;
    }

    final now = DateTime.now().toIso8601String();
    final storeId =
        expanded['storeId'] ?? expanded['store_id'] ?? Session.storeId;
    if (columns.contains('storeId')) expanded['storeId'] = storeId;
    if (columns.contains('store_id')) expanded['store_id'] = storeId;

    if (columns.contains('createdAt') && !expanded.containsKey('createdAt')) {
      expanded['createdAt'] =
          expanded['created_at'] ??
          expanded['addedOn'] ??
          expanded['updatedAt'] ??
          now;
    }
    if (columns.contains('created_at') && !expanded.containsKey('created_at')) {
      expanded['created_at'] =
          expanded['createdAt'] ??
          expanded['added_on'] ??
          expanded['updated_at'] ??
          expanded['updatedAt'] ??
          now;
    }
    if (columns.contains('updated_at') && !expanded.containsKey('updated_at')) {
      expanded['updated_at'] = expanded['updatedAt'] ?? now;
    }
    if (columns.contains('updatedAt') && !expanded.containsKey('updatedAt')) {
      expanded['updatedAt'] = expanded['updated_at'] ?? now;
    }

    for (final column in info) {
      final name = column['name'].toString();
      final isRequired = column['notnull'] == 1 && column['dflt_value'] == null;
      if (isRequired &&
          (!expanded.containsKey(name) || expanded[name] == null)) {
        expanded[name] = _fallbackValue(name, column['type']?.toString(), now);
      }
    }

    return Map.fromEntries(
      expanded.entries.where((entry) => columns.contains(entry.key)),
    );
  }

  static String _camelToSnake(String value) => value
      .replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'),
        (match) => '${match.group(1)}_${match.group(2)}',
      )
      .toLowerCase();

  static dynamic _fallbackValue(String column, String? type, String now) {
    final lower = column.toLowerCase();
    if (lower.contains('created') ||
        lower.contains('updated') ||
        lower.contains('date') ||
        lower.contains('time')) {
      return now;
    }
    if (lower.contains('store')) return Session.storeId;
    if (lower.endsWith('json')) return '{}';
    final normalizedType = (type ?? '').toUpperCase();
    if (normalizedType.contains('INT')) return 0;
    if (normalizedType.contains('REAL') ||
        normalizedType.contains('FLOA') ||
        normalizedType.contains('DOUB')) {
      return 0.0;
    }
    return '';
  }

  static Future<void> upsert(String table, Map<String, dynamic> data) async {
    final d = await db.timeout(timeout);
    final row = await _prepareRow(d, table, data);
    await d
        .insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace)
        .timeout(timeout);
  }

  static Future<void> upsertAll(
    String table,
    Iterable<Map<String, dynamic>> rows,
  ) async {
    final d = await db.timeout(timeout);
    final prepared = <Map<String, dynamic>>[];
    for (final row in rows) {
      prepared.add(await _prepareRow(d, table, row));
    }
    await d
        .transaction((txn) async {
          for (final row in prepared) {
            await txn.insert(
              table,
              row,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        })
        .timeout(timeout);
  }

  static Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    final d = await db.timeout(timeout);
    return d
        .query(
          table,
          where: where,
          whereArgs: whereArgs,
          orderBy: orderBy,
          limit: limit,
        )
        .timeout(timeout);
  }

  static Future<void> delete(String table, String id) async {
    final d = await db.timeout(timeout);
    await d.delete(table, where: 'id = ?', whereArgs: [id]).timeout(timeout);
  }

  static Future<void> deleteWhere(
    String table,
    String where,
    List<dynamic> args,
  ) async {
    final d = await db.timeout(timeout);
    await d.delete(table, where: where, whereArgs: args).timeout(timeout);
  }
}
