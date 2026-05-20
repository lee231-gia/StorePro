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

  static Future<void> runAll() async {
    if (Session.storeId.isEmpty) return;

    try {
      final rows = await SQLiteService.query(
        'products',
        where: 'storeId = ?',
        whereArgs: [Session.storeId],
      );
      final products = rows.map(ProductModel.fromSql).toList();

      await _checkLowStock(products);
      await _checkExpiry(products);
    } catch (_) {
      // Alerts must never block the app from opening.
    }
  }

  static Future<void> _checkLowStock(List<ProductModel> products) async {
    int idx = 0;
    for (final product in products) {
      for (final variant in product.variants) {
        final stock = variant.totalStock;
        if (stock > 0 && stock <= 10) {
          await NotificationService.show(
            id: _lowStockBase + idx,
            title: 'Low Stock Alert',
            body:
                '${product.name} - ${variant.name}: '
                'only $stock pcs left.',
          );
          idx++;
        } else if (stock == 0) {
          await NotificationService.show(
            id: _lowStockBase + idx,
            title: 'Out of Stock',
            body: '${product.name} - ${variant.name} is out of stock.',
          );
          idx++;
        }
      }
    }
  }

  static Future<void> _checkExpiry(List<ProductModel> products) async {
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
          await NotificationService.show(
            id: _expiringBase + dueSoonIdx,
            title: isHardExpiry ? 'Expiring Soon' : 'Product Date Due Soon',
            body:
                '${product.name} - ${variant.name}: '
                '${due.shortLabel} in $days day${days != 1 ? 's' : ''}.',
          );
          dueSoonIdx++;
        } else if (status == 'expired') {
          await NotificationService.show(
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
}
