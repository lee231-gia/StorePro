import '../core/services/sqlite_service.dart';
import '../core/services/sync_service.dart';
import '../core/utils/app_helpers.dart';
import '../core/utils/session.dart';
import '../models/product_model.dart';
import '../models/activity_log_model.dart';

class ProductRepository {
  ProductRepository._();
  static const _col = 'products';
  static const _table = 'products';

  // ── GET ALL: SQLite first, Firebase background ────────────
  static Future<List<ProductModel>> getAll() async {
    // 1. Return SQLite immediately (fast)
    final rows = await SQLiteService.query(
      _table,
      where: 'storeId = ?',
      whereArgs: [Session.storeId],
    );
    return rows.map(ProductModel.fromSql).toList();
  }

  // Call this after UI is shown to refresh from Firebase
  static void syncInBackground(void Function(List<ProductModel>) onSync) {
    SyncService.syncFromFirebase(
      _col,
      _table,
      (r) => ProductModel.fromMap(r).toSql(),
      (rows) => onSync(rows.map(ProductModel.fromSql).toList()),
    );
  }

  // ── GET ONE: SQLite first ─────────────────────────────────
  static Future<ProductModel?> getOne(String id) async {
    final rows = await SQLiteService.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return ProductModel.fromSql(rows.first);
  }

  // ── SAVE: SQLite → background Firebase ───────────────────
  static Future<ProductModel> save(ProductModel product) async {
    final now = AppHelpers.nowStr();
    final existing = product.id.isEmpty ? null : await getOne(product.id);
    final updated = ProductModel(
      id: product.id.isEmpty ? AppHelpers.newId() : product.id,
      storeId: Session.storeId,
      name: product.name,
      description: product.description,
      categoryId: product.categoryId,
      categoryName: product.categoryName,
      hasVariants: product.hasVariants,
      iconIndex: product.iconIndex,
      colorIndex: product.colorIndex,
      imageUrl: product.imageUrl,
      variants: product.variants,
      addedOn: product.addedOn.isEmpty
          ? AppHelpers.todayStr()
          : product.addedOn,
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
      product.id.isEmpty ? 'add_product' : 'edit_product',
      updated.id,
      updated.name,
      details: product.id.isEmpty
          ? _addedProductDetails(updated)
          : _editedProductDetails(existing, updated),
    );
    return updated;
  }

  // ── DELETE ────────────────────────────────────────────────
  static Future<void> delete(String id, String name) async {
    await SQLiteService.delete(_table, id);
    SyncService.deleteInBackground(_col, id);
    await _log('delete_product', id, name);
  }

  // ── DEDUCT FIFO ───────────────────────────────────────────
  static Future<ProductModel?> deductFifo(
    String productId,
    String variantId,
    int qtyPcs,
  ) async {
    final product = await getOne(productId);
    if (product == null) return null;

    final variantIndex = product.variants.indexWhere((v) => v.id == variantId);
    if (variantIndex < 0) return null;

    final variant = product.variants[variantIndex];
    final batches = List<BatchModel>.from(variant.batches);

    batches.sort((a, b) {
      if (a.primaryExpiry.isEmpty) return 1;
      if (b.primaryExpiry.isEmpty) return -1;
      return a.primaryExpiry.compareTo(b.primaryExpiry);
    });

    int remaining = qtyPcs;
    final updated = <BatchModel>[];
    for (final batch in batches) {
      if (remaining <= 0) {
        updated.add(batch);
        continue;
      }
      if (batch.qty <= remaining) {
        remaining -= batch.qty;
      } else {
        updated.add(
          BatchModel(
            id: batch.id,
            batchNumber: batch.batchNumber,
            qty: batch.qty - remaining,
            costPrice: batch.costPrice,
            indicators: batch.indicators,
            addedOn: batch.addedOn,
          ),
        );
        remaining = 0;
      }
    }

    final newVariants = List<VariantModel>.from(product.variants);
    newVariants[variantIndex] = variant.copyWith(batches: updated);

    final newProduct = product.copyWith(variants: newVariants);
    await SyncService.write(
      _col,
      newProduct.id,
      newProduct.toMap(),
      _table,
      newProduct.toSql(),
    );
    return newProduct;
  }

  // Fire and forget — never blocks UI
  static Future<void> _log(
    String action,
    String targetId,
    String name, {
    Map<String, dynamic> details = const {},
  }) async {
    if (!Session.trackActivity) return;
    final log = ActivityLogModel(
      id: AppHelpers.newId(),
      storeId: Session.storeId,
      employeeId: Session.safeEmployeeId,
      employeeName: Session.safeEmployeeName,
      action: action,
      targetType: 'product',
      targetId: targetId,
      targetName: name,
      timestamp: AppHelpers.nowStr(),
      details: details,
    );
    await SyncService.write(
      'activity_logs',
      log.id,
      log.toMap(),
      'activity_logs',
      log.toSql(),
    );
  }

  static Map<String, dynamic> _addedProductDetails(ProductModel product) => {
    'productName': product.name,
    'variantCount': product.variants.length,
    'variants': product.variants
        .map(
          (v) => {
            'name': v.name,
            'stock': v.totalStock,
            'price': v.price,
            'costPrice': v.costPrice,
          },
        )
        .toList(),
  };

  static Map<String, dynamic> _editedProductDetails(
    ProductModel? before,
    ProductModel after,
  ) {
    if (before == null) return _addedProductDetails(after);
    final changes = <Map<String, dynamic>>[];
    void addChange(String field, Object? oldValue, Object? newValue) {
      if (oldValue == newValue) return;
      changes.add({'field': field, 'old': oldValue, 'new': newValue});
    }

    addChange('Product Name', before.name, after.name);
    addChange('Category', before.categoryName, after.categoryName);
    addChange('Description', before.description, after.description);

    final beforeVariants = {for (final v in before.variants) v.id: v};
    for (final variant in after.variants) {
      final old = beforeVariants[variant.id];
      if (old == null) {
        changes.add({
          'field': 'Variant Added',
          'old': '',
          'new': '${variant.name} (${variant.totalStock} units)',
        });
        continue;
      }
      addChange('${variant.name} Name', old.name, variant.name);
      addChange(
        '${variant.name} Wholesale Cost',
        old.costPrice,
        variant.costPrice,
      );
      addChange('${variant.name} Retail Price', old.price, variant.price);
      addChange('${variant.name} Stock', old.totalStock, variant.totalStock);
    }
    final afterIds = after.variants.map((v) => v.id).toSet();
    for (final old in before.variants.where((v) => !afterIds.contains(v.id))) {
      changes.add({
        'field': 'Variant Removed',
        'old': '${old.name} (${old.totalStock} units)',
        'new': '',
      });
    }

    return {'productName': after.name, 'changes': changes};
  }
}
