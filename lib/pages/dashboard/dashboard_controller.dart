import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/services/data_sync_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/utils/app_helpers.dart';
import '../../models/product_model.dart';
import '../../models/sale_model.dart';
import '../../repositories/product_repository.dart';
import '../../repositories/report_repository.dart';
import '../../repositories/sale_repository.dart';

class DashboardController extends ChangeNotifier {
  List<ProductModel> _products = [];
  List<Map<String, dynamic>> _expiryAlerts = [];
  List<Map<String, dynamic>> _lowStockList = [];
  List<Map<String, dynamic>> _activityLogs = [];
  List<SaleModel> _salesSnapshot = [];
  double _todayRevenue = 0.0;
  double _todayProfit = 0.0;
  double _totalRevenue = 0.0;
  int _salesCount = 0;
  String _lastSynced = '';
  bool _loading = true;
  bool _loadingNow = false;
  bool _reloadAfterLoad = false;
  StreamSubscription<String>? _changeSub;

  List<ProductModel> get products => _products;
  List<Map<String, dynamic>> get expiryAlerts => _expiryAlerts;
  List<Map<String, dynamic>> get lowStockList => _lowStockList;
  List<Map<String, dynamic>> get activityLogs => _activityLogs;
  List<SaleModel> get salesSnapshot => _salesSnapshot;
  double get todayRevenue => _todayRevenue;
  double get todayProfit => _todayProfit;
  double get totalRevenue => _totalRevenue;
  int get salesCount => _salesCount;
  String get lastSynced => _lastSynced;
  bool get loading => _loading;

  int get totalStock => _products.fold(0, (s, p) => s + p.totalStock);
  int get lowStockCount => _lowStockList
      .where((i) => (i['stock'] as int) > 0 && (i['stock'] as int) <= 10)
      .length;
  int get expiringCount => _expiryAlerts.length;

  void init() {
    _changeSub = SyncService.changes.listen((collection) {
      if (collection == 'products' ||
          collection == 'sales' ||
          collection == 'activity_logs' ||
          collection == 'utang' ||
          collection == 'inventory_logs' ||
          collection == 'customers' ||
          collection == 'categories' ||
          collection == 'notes') {
        if (_loadingNow) {
          _reloadAfterLoad = true;
        } else {
          load();
        }
      }
    });
  }

  @override
  void dispose() {
    _changeSub?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    if (_loadingNow) return;
    _loadingNow = true;
    _loading = true;
    notifyListeners();
    DataSyncService.syncAllInBackground();

    Future<T> safe<T>(Future<T> future, T fallback) async {
      try {
        return await future.timeout(const Duration(seconds: 10));
      } catch (_) {
        return fallback;
      }
    }

    try {
      final results = await Future.wait([
        safe(ProductRepository.getAll(), _products),
        safe(SaleRepository.getAll(), _salesSnapshot),
        safe(ReportRepository.getActivityLogs(limit: 10), _activityLogs),
      ]);

      _buildState(
        results[0] as List<ProductModel>,
        results[1] as List<SaleModel>,
        results[2] as List<Map<String, dynamic>>,
      );
    } finally {
      _loading = false;
      _loadingNow = false;
      notifyListeners();
      if (_reloadAfterLoad) {
        _reloadAfterLoad = false;
        load();
      }
    }
  }

  void _buildState(
    List<ProductModel> products,
    List<SaleModel> sales,
    List<Map<String, dynamic>> logs,
  ) {
    final today = AppHelpers.todayStr();
    final todaySales = sales.where((s) => s.date == today).toList();
    final todayRev = todaySales.fold(0.0, (s, sale) => s + sale.total);
    final todayProfit = todaySales.fold(0.0, (s, sale) => s + sale.profit);
    final totalRevenue = sales.fold(0.0, (s, sale) => s + sale.total);

    final expiry = <Map<String, dynamic>>[];
    for (final p in products) {
      for (final v in p.variants) {
        final exp = v.nearestExpiry;
        final status = AppHelpers.expiryStatus(exp);
        if (status == 'expired' || status == 'expiring') {
          expiry.add({
            'productId': p.id,
            'variantId': v.id,
            'productName': p.name,
            'variantName': v.name,
            'expiry': exp,
            'status': status,
          });
        }
      }
    }
    expiry.sort((a, b) {
      if (a['status'] == 'expired' && b['status'] != 'expired') return -1;
      if (b['status'] == 'expired' && a['status'] != 'expired') return 1;
      return (a['expiry'] as String).compareTo(b['expiry'] as String);
    });

    final lowStock = <Map<String, dynamic>>[];
    for (final p in products) {
      for (final v in p.variants) {
        if (v.totalStock <= 10) {
          lowStock.add({
            'productId': p.id,
            'variantId': v.id,
            'productName': p.name,
            'variantName': v.name,
            'stock': v.totalStock,
          });
        }
      }
    }
    lowStock.sort((a, b) => (a['stock'] as int).compareTo(b['stock'] as int));

    _products = products;
    _salesSnapshot = sales;
    _expiryAlerts = expiry;
    _lowStockList = lowStock;
    _activityLogs = logs;
    _todayRevenue = todayRev;
    _todayProfit = todayProfit;
    _totalRevenue = totalRevenue;
    _salesCount = sales.length;
    _lastSynced = AppHelpers.nowStr();
    _loading = false;
    notifyListeners();
  }
}
