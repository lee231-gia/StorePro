import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/utils/app_helpers.dart';
import '../../core/utils/session.dart';
import '../../core/services/alert_service.dart';
import '../../core/services/sync_service.dart';
import '../../models/product_model.dart';
import '../../models/sale_model.dart';
import '../../repositories/product_repository.dart';
import '../../repositories/sale_repository.dart';
import '../../repositories/report_repository.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/dashboard_cards.dart';
import '../products/add_product_page.dart';
import '../products/product_detail_page.dart';
import '../reports/reports_page.dart';

class DashboardPage extends StatefulWidget {
  final Function(int) changeTab;
  final int currentIndex;

  const DashboardPage({
    super.key,
    required this.changeTab,
    required this.currentIndex,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // ── DATA ──────────────────────────────────────────────────
  List<ProductModel> _products = [];
  List<Map<String, dynamic>> _expiryAlerts = [];
  List<Map<String, dynamic>> _lowStockList = [];
  List<Map<String, dynamic>> _activityLogs = [];
  double _todayRevenue = 0.0;
  double _todayProfit = 0.0;
  bool _loading = true;
  StreamSubscription<String>? _changeSub;

  @override
  void initState() {
    super.initState();
    _changeSub = SyncService.changes.listen((collection) {
      if (collection == 'products' ||
          collection == 'sales' ||
          collection == 'activity_logs') {
        _load();
      }
    });
    _load();
  }

  @override
  void dispose() {
    _changeSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    // ── INSTANT FROM SQLITE ──────────────────────────────────
    try {
      final results = await Future.wait([
        ProductRepository.getAll(),
        SaleRepository.getAll(),
        ReportRepository.getActivityLogs(limit: 10),
      ]).timeout(const Duration(seconds: 3));

      _buildState(
        results[0] as List<ProductModel>,
        results[1] as List<SaleModel>,
        results[2] as List<Map<String, dynamic>>,
      );
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }

    // ── BACKGROUND FIREBASE SYNC ──────────────────────────────
    ProductRepository.syncInBackground((fresh) {
      if (!mounted) return;
      SaleRepository.getAll().then((s) {
        ReportRepository.getActivityLogs(limit: 10).then((l) {
          _buildState(fresh, s, l);
        });
      });
    });
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

    // Expiry alerts
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

    // Low stock
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

    if (mounted) {
      setState(() {
        _products = products;
        _expiryAlerts = expiry;
        _lowStockList = lowStock;
        _activityLogs = logs;
        _todayRevenue = todayRev;
        _todayProfit = todayProfit;
        _loading = false;
      });
    }
  }

  // Computed stats
  int get _totalStock => _products.fold(0, (s, p) => s + p.totalStock);
  int get _lowStockCount => _lowStockList
      .where((i) => (i['stock'] as int) > 0 && (i['stock'] as int) <= 10)
      .length;
  int get _expiringCount => _expiryAlerts.length;

  // ── BUILD ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: buildAppBar(
        title: '',
        context: context,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await AlertService.runAll();
              if (mounted) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Alerts refreshed.')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.settings,
            ).then((_) => _load()),
          ),
        ],
      ),
      drawer: AppDrawer(
        changeTab: widget.changeTab,
        currentIndex: widget.currentIndex,
      ),
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(color: kRed),
          Expanded(
            child: RefreshIndicator(
              color: kRed,
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcome(),
                    const SizedBox(height: 20),
                    _buildTodaySales(),
                    const SizedBox(height: 20),
                    _buildOverview(),
                    const SizedBox(height: 20),
                    _buildQuickActions(),
                    const SizedBox(height: 20),
                    if (_expiryAlerts.isNotEmpty) _buildExpirySection(),
                    if (_lowStockList.isNotEmpty) _buildLowStockSection(),
                    if (_activityLogs.isNotEmpty) _buildActivitySection(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── WELCOME CARD ──────────────────────────────────────────
  Widget _buildWelcome() {
    return DashboardWelcomeCard(
      firstName: Session.ownerName.isNotEmpty
          ? Session.ownerName.split(' ').first
          : 'Owner',
      storeName: Session.storeName,
    );
  }

  // ── TODAY SALES ───────────────────────────────────────────
  Widget _buildTodaySales() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's Revenue",
                  style: TextStyle(color: kGrey, fontSize: 11),
                ),
                Text(
                  AppHelpers.peso(_todayRevenue),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: kRed,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's Profit",
                  style: TextStyle(color: kGrey, fontSize: 11),
                ),
                Text(
                  AppHelpers.peso(_todayProfit),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: kGreen,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── OVERVIEW ──────────────────────────────────────────────
  Widget _buildOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: kDark,
          ),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            DashboardOverviewCard(
              value: '${_products.length}',
              label: 'Total Products',
              icon: Icons.inventory_2_outlined,
              onTap: () => widget.changeTab(1),
            ),
            const SizedBox(width: 12),
            DashboardOverviewCard(
              value: '$_totalStock pcs',
              label: 'Total Stock',
              icon: Icons.warehouse_outlined,
              onTap: () => widget.changeTab(2),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            DashboardOverviewCard(
              value: '$_lowStockCount',
              label: 'Low Stock',
              icon: Icons.warning_amber_outlined,
              onTap: () => widget.changeTab(2),
              valueColor: _lowStockCount > 0 ? kOrange : kGreen,
            ),
            const SizedBox(width: 12),
            DashboardOverviewCard(
              value: '$_expiringCount',
              label: 'Expiry Alerts',
              icon: Icons.event_busy_outlined,
              onTap: () => widget.changeTab(3),
              valueColor: _expiringCount > 0 ? kRed : kGreen,
            ),
          ],
        ),
      ],
    );
  }

  // ── QUICK ACTIONS ─────────────────────────────────────────
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: kDark,
          ),
        ),
        const SizedBox(height: 10),

        // Row 1
        Row(
          children: [
            DashboardActionBtn(
              icon: Icons.point_of_sale_outlined,
              label: 'New Sale',
              onTap: () => widget.changeTab(4),
            ),
            const SizedBox(width: 8),
            DashboardActionBtn(
              icon: Icons.add_box_outlined,
              label: 'Add Product',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddProductPage()),
              ).then((_) => _load()),
            ),
            const SizedBox(width: 8),
            DashboardActionBtn(
              icon: Icons.inventory_outlined,
              label: 'Restock',
              onTap: () => widget.changeTab(2),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Row 2
        Row(
          children: [
            DashboardActionBtn(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Utang',
              onTap: () => widget.changeTab(5),
            ),
            const SizedBox(width: 8),
            DashboardActionBtn(
              icon: Icons.bar_chart_outlined,
              label: 'Reports',
              onTap: () => widget.changeTab(9),
            ),
            const SizedBox(width: 8),
            DashboardActionBtn(
              icon: Icons.people_outline,
              label: 'Customers',
              onTap: () => widget.changeTab(8),
            ),
          ],
        ),
      ],
    );
  }

  // ── EXPIRY SECTION ────────────────────────────────────────
  Widget _buildExpirySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Expiry Alerts',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: kDark,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => widget.changeTab(3),
              child: const Text(
                'See all',
                style: TextStyle(color: kRed, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._expiryAlerts
            .take(5)
            .map(
              (item) => DashboardExpiryRow(
                item: item,
                onTap: () => _openProductDetail(item['productId'] as String),
              ),
            ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── LOW STOCK SECTION ─────────────────────────────────────
  Widget _buildLowStockSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Low Inventory',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: kDark,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => widget.changeTab(2),
              child: const Text(
                'See all',
                style: TextStyle(color: kRed, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._lowStockList
            .take(5)
            .map(
              (item) => DashboardLowStockRow(
                item: item,
                onTap: () => _openProductDetail(item['productId'] as String),
              ),
            ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── ACTIVITY SECTION ──────────────────────────────────────
  Widget _buildActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: kDark,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                ReportsPage.pendingTab = 3;
                widget.changeTab(9);
              },
              child: const Text(
                'See all',
                style: TextStyle(color: kRed, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            children: _activityLogs
                .take(5)
                .map((log) => _DashboardActivityRow(log: log))
                .toList(),
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  void _openProductDetail(String productId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(productId: productId),
      ),
    ).then((_) => _load());
  }
}

class _DashboardActivityRow extends StatelessWidget {
  final Map<String, dynamic> log;

  const _DashboardActivityRow({required this.log});

  @override
  Widget build(BuildContext context) {
    final action = _actionName(log);
    final timestamp = (log['timestamp'] ?? '').toString();
    final total = _overviewTotal(log);
    final lower = action.toLowerCase();
    var color = kGrey;
    if (lower.contains('add') || lower.contains('new')) color = kGreen;
    if (lower.contains('delete')) color = kRed;
    if (lower.contains('sale')) color = kOrange;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              Container(width: 1, height: 28, color: Colors.grey.shade200),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$action$total',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  AppHelpers.formatDateTime(
                    DateTime.tryParse(timestamp) ?? DateTime.now(),
                  ),
                  style: const TextStyle(color: kGrey, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _actionName(Map<String, dynamic> log) {
    final action = (log['action'] as String? ?? '').toLowerCase();
    final details = log['details'];
    final productName = details is Map
        ? (details['productName'] ?? log['targetName'] ?? '').toString()
        : (log['targetName'] ?? '').toString();
    if (action == 'new_sale') return 'New Sale Completed';
    if (action == 'add_product') {
      return productName.isEmpty
          ? 'Added New Product'
          : 'Added New Product: "$productName"';
    }
    if (action == 'edit_product') {
      return productName.isEmpty
          ? 'Edited Existing Product'
          : 'Edited Product: "$productName"';
    }
    if (action == 'delete_product') return 'Deleted Product';
    final text = action.replaceAll('_', ' ');
    return text.isEmpty
        ? 'Activity'
        : '${text[0].toUpperCase()}${text.substring(1)}';
  }

  String _overviewTotal(Map<String, dynamic> log) {
    if ((log['action'] as String? ?? '').toLowerCase() != 'new_sale') return '';
    final details = log['details'];
    if (details is! Map) return '';
    final total = (details['grandTotal'] as num?)?.toDouble();
    return total == null ? '' : ' (Grand Total: ${AppHelpers.peso(total)})';
  }
}
