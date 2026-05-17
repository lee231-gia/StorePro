import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/sync_service.dart';
import '../../core/utils/app_helpers.dart';
import '../../models/product_model.dart';
import '../../repositories/product_repository.dart';
import '../../repositories/category_repository.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/product_card.dart' hide FilterChip;
import '../../widgets/product_card.dart' as pc;
import 'product_detail_page.dart';
import 'add_product_page.dart';

class ProductsPage extends StatefulWidget {
  final Function(int) changeTab;
  final int currentIndex;
  final String initialFilter;

  const ProductsPage({
    super.key,
    required this.changeTab,
    required this.currentIndex,
    this.initialFilter = 'All',
  });

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  // ── STATE ─────────────────────────────────────────────────
  List<ProductModel> _products = [];
  List<String> _categories = ['All'];
  bool _loading = true;
  String _search = '';
  String _catFilter = 'All';
  late String _statusFilter;
  String _viewMode = 'list'; // list|compact|grid
  String _sortBy = 'recent';
  final _searchCtrl = TextEditingController();
  StreamSubscription<String>? _changeSub;

  @override
  void initState() {
    super.initState();
    _statusFilter = widget.initialFilter;
    _changeSub = SyncService.changes.listen((collection) {
      if (collection == 'products' || collection == 'categories') _load();
    });
    _load();
  }

  @override
  void dispose() {
    _changeSub?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── LOAD ──────────────────────────────────────────────────
  Future<void> _load() async {
    setState(() => _loading = true);

    List<ProductModel> products = [];
    var catNames = <String>['All'];

    try {
      final results = await Future.wait([
        ProductRepository.getAll(),
        CategoryRepository.getAll(),
      ]).timeout(const Duration(seconds: 3));

      products = results[0] as List<ProductModel>;
      final categories = results[1] as List;
      catNames = ['All', ...categories.map((c) => c.name as String)];
    } catch (_) {}

    if (mounted) {
      setState(() {
        _products = products;
        _categories = catNames;
        _loading = false;
      });
    }

    // 2. Firebase in background — updates UI silently
    ProductRepository.syncInBackground((fresh) {
      if (mounted) setState(() => _products = fresh);
    });
    CategoryRepository.syncInBackground((fresh) {
      if (mounted) {
        setState(() => _categories = ['All', ...fresh.map((c) => c.name)]);
      }
    });
  }

  // ── FILTERED + SORTED LIST ────────────────────────────────
  List<ProductModel> get _filtered {
    var list = List<ProductModel>.from(_products);

    // Search
    if (_search.isNotEmpty) {
      list = list
          .where((p) => p.name.toLowerCase().contains(_search.toLowerCase()))
          .toList();
    }

    // Category
    if (_catFilter != 'All') {
      list = list.where((p) => p.categoryName == _catFilter).toList();
    }

    // Status filter
    switch (_statusFilter) {
      case 'Expiring':
        list = list
            .where(
              (p) => AppHelpers.expiryStatus(p.nearestExpiry) == 'expiring',
            )
            .toList();
        break;
      case 'Expired':
        list = list
            .where((p) => AppHelpers.expiryStatus(p.nearestExpiry) == 'expired')
            .toList();
        break;
      case 'Low Stock':
        list = list
            .where((p) => p.totalStock > 0 && p.totalStock <= 10)
            .toList();
        break;
      case 'No Stock':
        list = list.where((p) => p.totalStock == 0).toList();
        break;
    }

    // Sort
    switch (_sortBy) {
      case 'a-z':
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'z-a':
        list.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'stock-low':
        list.sort((a, b) => a.totalStock.compareTo(b.totalStock));
        break;
      case 'expiry':
        list.sort((a, b) {
          if (a.nearestExpiry.isEmpty) return 1;
          if (b.nearestExpiry.isEmpty) return -1;
          return a.nearestExpiry.compareTo(b.nearestExpiry);
        });
        break;
      default:
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
        title: 'Products',
        context: context,
        actions: [
          // View mode toggle
          PopupMenuButton<String>(
            icon: const Icon(Icons.view_list_outlined),
            onSelected: (v) => setState(() => _viewMode = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'list', child: Text('List')),
              PopupMenuItem(value: 'compact', child: Text('Compact')),
              PopupMenuItem(value: 'grid', child: Text('Grid')),
            ],
          ),
          // Sort
          IconButton(icon: const Icon(Icons.sort), onPressed: _showSortSheet),
        ],
      ),
      drawer: AppDrawer(
        changeTab: widget.changeTab,
        currentIndex: widget.currentIndex,
      ),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'products_add_fab',
        backgroundColor: kRed,
        foregroundColor: Colors.white,
        onPressed: _goAdd,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(color: kRed),
          _buildFilters(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  // ── FILTERS SECTION ───────────────────────────────────────
  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _search = v),
            decoration: AppInput.field(
              'Search products...',
              icon: Icons.search,
            ),
          ),
          const SizedBox(height: 10),

          // Category chips
          SizedBox(
            height: 32,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final active = _catFilter == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _catFilter = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: active ? kRed : kCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: active ? kRed : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 12,
                          color: active ? Colors.white : kGrey,
                          fontWeight: active
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Status filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final f in [
                  'All',
                  'Expiring',
                  'Expired',
                  'Low Stock',
                  'No Stock',
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: pc.FilterChip(
                      label: f,
                      isSelected: _statusFilter == f,
                      onTap: () => setState(() => _statusFilter = f),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 4),
          Text(
            '${_filtered.length} item'
            '${_filtered.length != 1 ? 's' : ''}',
            style: const TextStyle(color: kGrey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── PRODUCT LIST ──────────────────────────────────────────
  Widget _buildList() {
    final items = _filtered;
    if (items.isEmpty) {
      return const Center(
        child: Text('No products found.', style: TextStyle(color: kGrey)),
      );
    }

    if (_viewMode == 'grid') {
      return RefreshIndicator(
        color: kRed,
        onRefresh: _load,
        child: GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => ProductGridCard(
            product: items[i],
            onTap: () => _goDetail(items[i].id),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: kRed,
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (_, i) => ProductCard(
          product: items[i],
          onTap: () => _goDetail(items[i].id),
          compact: _viewMode == 'compact',
        ),
      ),
    );
  }

  // ── SORT SHEET ────────────────────────────────────────────
  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Sort By',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Divider(),
          for (final entry in {
            'recent': 'Recently Added',
            'a-z': 'Name A → Z',
            'z-a': 'Name Z → A',
            'stock-low': 'Stock: Low → High',
            'expiry': 'Expiry Date',
          }.entries)
            ListTile(
              title: Text(entry.value),
              trailing: _sortBy == entry.key
                  ? const Icon(Icons.check, color: kRed)
                  : null,
              onTap: () {
                setState(() => _sortBy = entry.key);
                Navigator.pop(context);
              },
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _goDetail(String id) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => ProductDetailPage(productId: id)),
  ).then((_) => _load());

  void _goAdd() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const AddProductPage()),
  ).then((_) => _load());
}
