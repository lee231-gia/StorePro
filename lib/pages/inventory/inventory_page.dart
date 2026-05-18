import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/utils/app_helpers.dart';
import '../../core/utils/session.dart';
import '../../core/services/alert_service.dart';
import '../../core/services/sync_service.dart';
import '../../models/product_model.dart';
import '../../models/inventory_model.dart';
import '../../repositories/product_repository.dart';
import '../../repositories/inventory_repository.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/employee_picker.dart';
import '../../widgets/product_card.dart';

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

  List<ProductModel> _products = [];
  List<InventoryLogModel> _logs = [];
  bool _loading = true;

  // ── FILTER / SORT / VIEW ──────────────────────────────────
  String _search = '';
  String _sortBy = 'recent';
  String _catFilter = 'All';
  String _viewMode = 'list'; // list | compact | grid | details
  bool _groupVariants = true;
  List<String> _categories = ['All'];

  final _searchCtrl = TextEditingController();
  StreamSubscription<String>? _changeSub;

  void _update(VoidCallback fn) => setState(fn);

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _changeSub = SyncService.changes.listen((collection) {
      if (collection == 'products' || collection == 'inventory_logs') _load();
    });
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _changeSub?.cancel();
    _searchCtrl.dispose();
    super.dispose();
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
    var list = List<ProductModel>.from(_products);

    if (_search.isNotEmpty) {
      list = list
          .where((p) => p.name.toLowerCase().contains(_search.toLowerCase()))
          .toList();
    }
    if (_catFilter != 'All') {
      list = list.where((p) => p.categoryName == _catFilter).toList();
    }

    switch (_sortBy) {
      case 'a-z':
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'z-a':
        list.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'cat-a-z':
        list.sort((a, b) => a.categoryName.compareTo(b.categoryName));
        break;
      case 'cat-z-a':
        list.sort((a, b) => b.categoryName.compareTo(a.categoryName));
        break;
      case 'stock-low':
        list.sort((a, b) => a.totalStock.compareTo(b.totalStock));
        break;
      case 'stock-high':
        list.sort((a, b) => b.totalStock.compareTo(a.totalStock));
        break;
      case 'expiry-asc':
        list.sort((a, b) {
          if (a.nearestExpiry.isEmpty) return 1;
          if (b.nearestExpiry.isEmpty) return -1;
          return a.nearestExpiry.compareTo(b.nearestExpiry);
        });
        break;
      case 'expiry-desc':
        list.sort((a, b) {
          if (a.nearestExpiry.isEmpty) return 1;
          if (b.nearestExpiry.isEmpty) return -1;
          return b.nearestExpiry.compareTo(a.nearestExpiry);
        });
        break;
      default: // recent
        list.sort((a, b) => b.addedOn.compareTo(a.addedOn));
    }
    return list;
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
