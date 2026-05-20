import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/enums/product_browser_enums.dart';
import '../../core/utils/app_helpers.dart';
import '../../core/utils/session.dart';
import '../../core/services/alert_service.dart';
import '../../core/services/sync_service.dart';
import '../../models/product_model.dart';
import '../../models/inventory_model.dart';
import '../../repositories/product_repository.dart';
import '../../repositories/inventory_repository.dart';
import '../../shared/controllers/product_browser_controller.dart';
import '../../shared/widgets/product_browser_toolbar.dart';
import '../../shared/widgets/product_browser_view.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/employee_picker.dart';
import '../../widgets/product_card.dart';
import '../products/product_detail_page.dart';

part 'inventory_overview.dart';
part 'inventory_replenish.dart';
part 'inventory_logs.dart';
part 'inventory_product_views.dart';

class InventoryPage extends StatefulWidget {
  final Function(int) changeTab;
  final int currentIndex;

  const InventoryPage({
    super.key,
    required this.changeTab,
    required this.currentIndex,
  });

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  late final ProductBrowserController _browser;

  List<ProductModel> _products = [];
  List<InventoryLogModel> _logs = [];
  final List<String> _removeReasons = [
    'adjustment',
    'personal_use',
    'waste_damage',
    'stock_loss',
  ];
  bool _loading = true;

  // ── FILTER / SORT / VIEW ──────────────────────────────────
  List<String> _categories = ['All'];

  final _searchCtrl = TextEditingController();
  StreamSubscription<String>? _changeSub;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _browser = ProductBrowserController()..addListener(_onBrowserChanged);
    _changeSub = SyncService.changes.listen((collection) {
      if (collection == 'products' || collection == 'inventory_logs') _load();
    });
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _browser
      ..removeListener(_onBrowserChanged)
      ..dispose();
    _changeSub?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onBrowserChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    List<ProductModel> products = [];
    List<InventoryLogModel> logs = [];

    try {
      final results = await Future.wait([
        ProductRepository.getAll(),
        InventoryRepository.getAll(),
      ]).timeout(const Duration(seconds: 3));

      products = results[0] as List<ProductModel>;
      logs = results[1] as List<InventoryLogModel>;
    } catch (_) {}

    final cats = <String>{'All'};
    for (final p in products) {
      cats.add(p.categoryName);
    }

    if (mounted) {
      setState(() {
        _products = products;
        _logs = logs;
        _categories = cats.toList();
        _loading = false;
      });
    }
    ProductRepository.syncInBackground((fresh) {
      if (mounted) setState(() => _products = fresh);
    });
  }

  // ── SORTED + FILTERED ─────────────────────────────────────
  List<ProductModel> get _filtered {
    return _browser.apply(_products);
  }

  // ── BUILD ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: buildAppBar(
        title: 'Inventory',
        context: context,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Replenish'),
            Tab(text: 'Logs'),
          ],
        ),
      ),
      drawer: AppDrawer(
        changeTab: widget.changeTab,
        currentIndex: widget.currentIndex,
      ),
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(color: kRed),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [_buildOverview(), _buildReplenish(), _buildLogs()],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // TAB 0 — OVERVIEW
  // ══════════════════════════════════════════════════════════
}
