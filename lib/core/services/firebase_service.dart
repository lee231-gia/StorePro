import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../firebase_options.dart';
import '../utils/session.dart';

// Base Firestore helper — all repositories use this.
class FirebaseService {
  FirebaseService._();
  static Future<void>? _initFuture;
  static const Duration timeout = Duration(seconds: 6);

  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static Future<void> ensureInitialized() {
    _initFuture ??= _initialize();
    return _initFuture!;
  }

  static Future<void> _initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(timeout);
      }
    } catch (_) {
      _initFuture = null;
      rethrow;
    }
  }

  // ── STORE COLLECTION ROOT ─────────────────────────────────
  // All store data lives under: stores/{storeId}/{collection}
  // static CollectionReference storeCol(String collection) {
  //   return _db.collection('stores').doc(Session.storeId).collection(collection);
  // }

  static CollectionReference storeCol(String collection) {
    return _db.collection('stores').doc(Session.storeId).collection(collection);
  }

  // ── CREATE ────────────────────────────────────────────────
  static Future<void> set(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    await ensureInitialized().timeout(timeout);
    final remoteData = Map<String, dynamic>.from(data)
      ..['updatedAt'] = FieldValue.serverTimestamp();
    await storeCol(
      collection,
    ).doc(docId).set(remoteData, SetOptions(merge: true)).timeout(timeout);
  }

  // ── READ ALL ──────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getAll(String collection) async {
    await ensureInitialized().timeout(timeout);
    final snap = await storeCol(collection).get().timeout(timeout);
    return snap.docs
        .map(
          (d) => _normalizeMap({
            'id': d.id,
            ...(d.data() as Map<String, dynamic>),
          }),
        )
        .toList();
  }

  // ── READ ONE ──────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getOne(
    String collection,
    String docId,
  ) async {
    await ensureInitialized().timeout(timeout);
    final doc = await storeCol(collection).doc(docId).get().timeout(timeout);
    if (!doc.exists) return null;
    return _normalizeMap({
      'id': doc.id,
      ...(doc.data() as Map<String, dynamic>),
    });
  }

  // ── UPDATE ────────────────────────────────────────────────
  static Future<void> update(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    await ensureInitialized().timeout(timeout);
    final remoteData = Map<String, dynamic>.from(data)
      ..['updatedAt'] = FieldValue.serverTimestamp();
    await storeCol(collection).doc(docId).update(remoteData).timeout(timeout);
  }

  // ── DELETE ────────────────────────────────────────────────
  static Future<void> delete(String collection, String docId) async {
    await ensureInitialized().timeout(timeout);
    await storeCol(collection).doc(docId).delete().timeout(timeout);
  }

  // ── STORE PROFILE ─────────────────────────────────────────
  static DocumentReference get storeDoc =>
      _db.collection('stores').doc(Session.storeId);

  // ── GLOBAL (outside store) ────────────────────────────────
  static Future<void> setGlobal(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    await ensureInitialized().timeout(timeout);
    await _db
        .collection(collection)
        .doc(docId)
        .set(data, SetOptions(merge: true))
        .timeout(timeout);
  }

  static Future<Map<String, dynamic>?> getGlobal(
    String collection,
    String docId,
  ) async {
    await ensureInitialized().timeout(timeout);
    final doc = await _db
        .collection(collection)
        .doc(docId)
        .get()
        .timeout(timeout);
    if (!doc.exists) return null;
    return _normalizeMap({
      'id': doc.id,
      ...(doc.data() as Map<String, dynamic>),
    });
  }

  static Map<String, dynamic> _normalizeMap(Map<String, dynamic> data) =>
      data.map((key, value) => MapEntry(key, _normalizeValue(value)));

  static dynamic _normalizeValue(dynamic value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is Map) {
      return value.map(
        (key, nested) => MapEntry(key.toString(), _normalizeValue(nested)),
      );
    }
    if (value is List) return value.map(_normalizeValue).toList();
    return value;
  }
}
