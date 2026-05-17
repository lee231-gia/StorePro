import 'dart:convert';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'firebase_service.dart';
import 'sqlite_service.dart';
import '../utils/session.dart';

class SyncService {
  SyncService._();
  static final Map<String, DateTime> _lastSyncAt = {};
  static final StreamController<String> _changeController =
      StreamController<String>.broadcast();
  static const Duration _syncCooldown = Duration(seconds: 45);
  static const int _maxFlushBatch = 25;
  static bool _flushing = false;
  static final Set<String> _syncingCollections = {};

  static Stream<String> get changes => _changeController.stream;

  static void notifyChanged(String collection) {
    if (!_changeController.isClosed) _changeController.add(collection);
  }

  static Stream<bool> get onlineStream =>
      Connectivity().onConnectivityChanged.map(
        (results) =>
            results.isNotEmpty && !results.contains(ConnectivityResult.none),
      );

  static Future<bool> isOnline() async {
    try {
      final results = await Connectivity().checkConnectivity().timeout(
        const Duration(seconds: 2),
        onTimeout: () => [],
      );
      return results.isNotEmpty && !results.contains(ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }

  static void flushInBackground() {
    flush().timeout(const Duration(seconds: 8), onTimeout: () {}).ignore();
  }

  // Queue an offline write for later sync
  static Future<void> queue(
    String collection,
    String docId,
    String action,
    Map<String, dynamic> data,
  ) async {
    try {
      await SQLiteService.upsert('sync_queue', {
        'id': '${docId}_${DateTime.now().microsecondsSinceEpoch}',
        'collection': collection,
        'docId': docId,
        'action': action,
        'dataJson': jsonEncode(data),
        'createdAt': DateTime.now().toIso8601String(),
      }).timeout(SQLiteService.timeout);
    } catch (_) {}
  }

  // Flush queued writes to Firebase
  static Future<void> flush() async {
    if (_flushing) return;
    if (Session.storeId.isEmpty) return;
    if (!await isOnline()) return;
    _flushing = true;
    try {
      final rows = await SQLiteService.query(
        'sync_queue',
        orderBy: 'createdAt ASC',
        limit: _maxFlushBatch,
      ).timeout(SQLiteService.timeout);
      for (final row in rows) {
        try {
          final data =
              jsonDecode(row['dataJson'] as String) as Map<String, dynamic>;
          final col = row['collection'] as String;
          final docId = row['docId'] as String;
          final act = row['action'] as String;

          if (act == 'set') {
            await FirebaseService.set(col, docId, data);
          } else if (act == 'update') {
            await FirebaseService.update(col, docId, data);
          } else if (act == 'delete') {
            await FirebaseService.delete(col, docId);
          }

          await SQLiteService.delete('sync_queue', row['id'] as String);
        } catch (_) {}
      }
    } catch (_) {
    } finally {
      _flushing = false;
    }
  }

  // ── DUAL WRITE ─────────────────────────────────────────────
  // SQLite first (instant) → Firebase in background (non-blocking)
  static Future<void> write(
    String collection,
    String docId,
    Map<String, dynamic> firebaseData,
    String sqlTable,
    Map<String, dynamic> sqlData,
  ) async {
    // 1. SQLite immediately — never blocks UI
    await SQLiteService.upsert(sqlTable, sqlData);
    notifyChanged(collection);

    // 2. Firebase in background — never await this
    _firebaseWriteBackground(collection, docId, firebaseData);
  }

  static void _firebaseWriteBackground(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    try {
      if (!await isOnline()) {
        await queue(collection, docId, 'set', data);
        return;
      }
      try {
        await FirebaseService.set(collection, docId, data);
      } catch (_) {
        await queue(collection, docId, 'set', data);
      }
    } catch (_) {
      await queue(collection, docId, 'set', data);
    }
  }

  static void deleteInBackground(String collection, String docId) async {
    notifyChanged(collection);
    try {
      if (await isOnline()) {
        await FirebaseService.delete(collection, docId);
      } else {
        await queue(collection, docId, 'delete', const {});
      }
    } catch (_) {
      await queue(collection, docId, 'delete', const {});
    }
  }

  // ── BACKGROUND FIREBASE SYNC ──────────────────────────────
  // Call once after SQLite data is shown — never blocks UI
  static void syncFromFirebase(
    String collection,
    String sqlTable,
    Map<String, dynamic> Function(Map<String, dynamic>) toSql,
    void Function(List<Map<String, dynamic>>) onData,
  ) async {
    if (Session.storeId.isEmpty) return;
    if (_syncingCollections.contains(collection)) return;
    final lastSync = _lastSyncAt[collection];
    if (lastSync != null &&
        DateTime.now().difference(lastSync) < _syncCooldown) {
      return;
    }
    _lastSyncAt[collection] = DateTime.now();

    if (!await isOnline()) return;
    _syncingCollections.add(collection);
    try {
      final rows = await FirebaseService.getAll(
        collection,
      ).timeout(FirebaseService.timeout);
      final sqlRows = rows.map(toSql).toList();
      await SQLiteService.upsertAll(
        sqlTable,
        sqlRows,
      ).timeout(SQLiteService.timeout);
      notifyChanged(collection);
      onData(sqlRows);
    } catch (_) {
    } finally {
      _syncingCollections.remove(collection);
    }
  }
}
