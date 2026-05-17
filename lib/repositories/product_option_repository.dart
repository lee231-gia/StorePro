import '../core/constants/app_icons.dart';
import '../core/services/sqlite_service.dart';
import '../core/services/sync_service.dart';
import '../core/utils/app_helpers.dart';
import '../core/utils/session.dart';
import '../models/product_option_model.dart';

class ProductOptionRepository {
  ProductOptionRepository._();

  static const _col = 'store_options';
  static const _table = 'store_options';
  static const uom = 'uom';
  static const packaging = 'packaging';

  static const List<String> defaultPackaging = [
    'Solo',
    'Case',
    'Pack',
    'Bundle',
    'Box',
    'Dozen',
  ];

  static List<ProductOptionModel> defaultOptions(String type) {
    final now = AppHelpers.nowStr();
    if (type == uom) {
      return AppIcons.unitDefaults.entries
          .map(
            (entry) => ProductOptionModel(
              id: 'default_uom_${entry.key}',
              storeId: Session.storeId,
              type: uom,
              value: entry.key,
              pcsPerUnit: entry.value,
              updatedAt: now,
            ),
          )
          .toList();
    }
    return defaultPackaging
        .map(
          (value) => ProductOptionModel(
            id: 'default_packaging_$value',
            storeId: Session.storeId,
            type: packaging,
            value: value,
            updatedAt: now,
          ),
        )
        .toList();
  }

  static Future<List<ProductOptionModel>> getByType(String type) async {
    final rows = await SQLiteService.query(
      _table,
      where: 'storeId = ? AND type = ?',
      whereArgs: [Session.storeId, type],
      orderBy: 'value COLLATE NOCASE ASC',
    );
    final saved = rows.map(ProductOptionModel.fromMap).toList();
    return _mergeDefaults(type, saved);
  }

  static void syncInBackground(
    void Function(List<ProductOptionModel>) onSync,
  ) {
    SyncService.syncFromFirebase(
      _col,
      _table,
      (r) => ProductOptionModel.fromMap(r).toSql(),
      (rows) {
        final saved = rows.map(ProductOptionModel.fromMap).toList();
        onSync(saved);
      },
    );
  }

  static Future<ProductOptionModel> save(ProductOptionModel option) async {
    final updated = ProductOptionModel(
      id: option.id.isEmpty ? AppHelpers.newId() : option.id,
      storeId: Session.storeId,
      type: option.type,
      value: option.value.trim(),
      pcsPerUnit: option.pcsPerUnit <= 0 ? 1 : option.pcsPerUnit,
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

  static List<ProductOptionModel> _mergeDefaults(
    String type,
    List<ProductOptionModel> saved,
  ) {
    final byValue = <String, ProductOptionModel>{};
    for (final option in defaultOptions(type)) {
      byValue[option.value.toLowerCase()] = option;
    }
    for (final option in saved) {
      byValue[option.value.toLowerCase()] = option;
    }
    final merged = byValue.values.toList()
      ..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));
    return merged;
  }
}
