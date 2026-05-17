// Checks stock levels and expiry dates across all products
// and fires local notifications when thresholds are crossed.
// Call this on app start and after every sale / stock change.

import '../utils/app_helpers.dart';
import '../utils/session.dart';
import 'notification_service.dart';
import 'sqlite_service.dart';
import '../../models/product_model.dart';

class AlertService {
  AlertService._();

  // Notification ID ranges so they never collide:
  // Low stock  : 10000 + index
  // Expiring   : 20000 + index
  // Expired    : 30000 + index
  static const _lowStockBase = 10000;
  static const _expiringBase = 20000;
  static const _expiredBase = 30000;

  // ── RUN ALL ALERTS ────────────────────────────────────────
  // Loads products from SQLite (fast, works offline),
  // cancels stale alerts, fires new ones.
  // REMOVE this line at the bottom of alert_service.dart:
  // final session = Session;

  // And fix the guard at the top of runAll():
  static Future<void> runAll() async {
    if (Session.storeId.isEmpty) return;
    // ... rest of method unchanged

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
      // Silent fail — alerts are non-critical
    }
  }

  // ── LOW STOCK ─────────────────────────────────────────────
  static Future<void> _checkLowStock(List<ProductModel> products) async {
    int idx = 0;
    for (final product in products) {
      for (final variant in product.variants) {
        final stock = variant.totalStock;
        if (stock > 0 && stock <= 10) {
          await NotificationService.show(
            id: _lowStockBase + idx,
            title: '⚠️ Low Stock Alert',
            body:
                '${product.name} — ${variant.name}: '
                'only $stock pcs left.',
          );
          idx++;
        } else if (stock == 0) {
          await NotificationService.show(
            id: _lowStockBase + idx,
            title: '🚫 Out of Stock',
            body:
                '${product.name} — ${variant.name} '
                'is out of stock.',
          );
          idx++;
        }
      }
    }
  }

  // ── EXPIRY ────────────────────────────────────────────────
  static Future<void> _checkExpiry(List<ProductModel> products) async {
    int expIdx = 0;
    int xprdIdx = 0;

    for (final product in products) {
      for (final variant in product.variants) {
        final expiry = variant.nearestExpiry;
        if (expiry.isEmpty) continue;

        final status = AppHelpers.expiryStatus(expiry);
        final days = AppHelpers.daysLeft(expiry);

        if (status == 'expiring') {
          await NotificationService.show(
            id: _expiringBase + expIdx,
            title: '📅 Expiring Soon',
            body:
                '${product.name} — ${variant.name} '
                'expires in $days day'
                '${days != 1 ? 's' : ''}.',
          );
          expIdx++;
        } else if (status == 'expired') {
          await NotificationService.show(
            id: _expiredBase + xprdIdx,
            title: '❌ Expired Product',
            body:
                '${product.name} — ${variant.name} '
                'has expired.',
          );
          xprdIdx++;
        }
      }
    }
  }
}

// Alias to avoid Session import conflict
final session = Session;
