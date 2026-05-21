// Checks stock levels and shelf-life dates across all products and fires local
// notifications when thresholds are crossed.

import '../utils/app_helpers.dart';
import '../utils/session.dart';
import 'notification_service.dart';
import 'sqlite_service.dart';
import '../../models/product_model.dart';

class AlertService {
  AlertService._();

  static const _lowStockBase = 10000;
  static const _expiringBase = 20000;
  static const _expiredBase = 30000;
  static final Set<String> _shownAlertKeys = {};

  static Future<void> runAll() async {
    if (Session.storeId.isEmpty || !Session.notificationsEnabled) return;

    try {
      final rows = await SQLiteService.query(
        'products',
        where: 'storeId = ?',
        whereArgs: [Session.storeId],
      );
      final products = rows.map(ProductModel.fromSql).toList();

      final activeKeys = <String>{};
      await _checkLowStock(products, activeKeys);
      await _checkExpiry(products, activeKeys);
      _shownAlertKeys.removeWhere((key) => !activeKeys.contains(key));
    } catch (_) {
      // Alerts must never block the app from opening.
    }
  }

  static Future<void> _checkLowStock(
    List<ProductModel> products,
    Set<String> activeKeys,
  ) async {
    int idx = 0;
    for (final product in products) {
      for (final variant in product.variants) {
        final stock = variant.totalStock;
        if (stock > 0 && stock <= 10) {
          await _showOnce(
            activeKeys,
            key: 'low:${product.id}:${variant.id}',
            id: _lowStockBase + idx,
            title: 'Low Stock Alert',
            body: '${product.name} - ${variant.name}: only $stock pcs left.',
          );
          idx++;
        } else if (stock == 0) {
          await _showOnce(
            activeKeys,
            key: 'out:${product.id}:${variant.id}',
            id: _lowStockBase + idx,
            title: 'Out of Stock',
            body: '${product.name} - ${variant.name} is out of stock.',
          );
          idx++;
        }
      }
    }
  }

  static Future<void> _checkExpiry(
    List<ProductModel> products,
    Set<String> activeKeys,
  ) async {
    int dueSoonIdx = 0;
    int pastDueIdx = 0;

    for (final product in products) {
      for (final variant in product.variants) {
        final due = variant.nearestExpiryIndicator;
        if (due == null) continue;

        final status = AppHelpers.expiryStatus(due.date);
        final days = AppHelpers.daysLeft(due.date);
        final isHardExpiry = due.type == 'Expiry Date' || due.type == 'Use-By';

        if (status == 'expiring') {
          await _showOnce(
            activeKeys,
            key: 'expiring:${product.id}:${variant.id}:${due.date}',
            id: _expiringBase + dueSoonIdx,
            title: isHardExpiry ? 'Expiring Soon' : 'Product Date Due Soon',
            body:
                '${product.name} - ${variant.name}: '
                '${due.shortLabel} in $days day${days != 1 ? 's' : ''}.',
          );
          dueSoonIdx++;
        } else if (status == 'expired') {
          await _showOnce(
            activeKeys,
            key: 'expired:${product.id}:${variant.id}:${due.date}',
            id: _expiredBase + pastDueIdx,
            title: isHardExpiry ? 'Expired Product' : 'Product Date Passed',
            body:
                '${product.name} - ${variant.name}: '
                '${due.shortLabel} has passed.',
          );
          pastDueIdx++;
        }
      }
    }
  }

  static Future<void> _showOnce(
    Set<String> activeKeys, {
    required String key,
    required int id,
    required String title,
    required String body,
  }) async {
    activeKeys.add(key);
    if (_shownAlertKeys.contains(key)) return;
    _shownAlertKeys.add(key);
    await NotificationService.show(id: id, title: title, body: body);
  }
}
