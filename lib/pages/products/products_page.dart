import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/enums/product_browser_enums.dart';
import '../../core/services/sync_service.dart';
import '../../models/product_model.dart';
import '../../repositories/category_repository.dart';
import '../../repositories/product_repository.dart';
import '../../shared/controllers/product_browser_controller.dart';
import '../../shared/widgets/product_browser_toolbar.dart';
import '../../shared/widgets/product_browser_view.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/product_card.dart';
import '../../widgets/shared_widgets.dart';
import 'add_product_page.dart';
import 'product_detail_page.dart';

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
  // â”€â”€ STATE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  List<ProductModel> _products = [];
  List<String> _categories = ['All'];
  bool _loading = true;

  final _searchCtrl = TextEditingController();
  late final ProductBrowserController _browser;
  StreamSubscription<String>? _changeSub;

  @override
  void initState() {
    super.initState();
    _browser = ProductBrowserController(statusFilter: widget.initialFilter)
      ..addListener(() {
        if (mounted) setState(() {});
      });
    _changeSub = SyncService.changes.listen((collection) {
      if (collection == 'products' || collection == 'categories') _load();
    });
    _load();
  }

  @override
  void dispose() {
    _changeSub?.cancel();
    _browser.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // â”€â”€ LOAD â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    List<ProductModel> products = [];
    List<String> catNames = ['All'];

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

    ProductRepository.syncInBackground((fresh) {
      if (mounted) setState(() => _products = fresh);
    });
    CategoryRepository.syncInBackground((fresh) {
      if (mounted) {
        setState(() => _categories = ['All', ...fresh.map((c) => c.name)]);
      }
    });
  }

  // â”€â”€ FILTERED + SORTED â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  List<ProductDisplayItem> get _displayItems =>
      _browser.displayItems(_products);

  // â”€â”€ BUILD â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: buildAppBar(
        title: 'Products',
        context: context,
        actions: [
          PopupMenuButton<ProductViewMode>(
            icon: const Icon(Icons.view_list_outlined),
            onSelected: (value) => _browser.viewMode = value,
            itemBuilder: (_) => ProductViewMode.values
                .map(
                  (mode) => PopupMenuItem(value: mode, child: Text(mode.label)),
                )
                .toList(),
          ),
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

  // â”€â”€ FILTERS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProductBrowserToolbar(
            controller: _browser,
            searchController: _searchCtrl,
            categories: _categories,
            statusFilters: const [
              'All',
              'Expiring',
              'Expired',
              'Low Stock',
              'No Stock',
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_displayItems.length} item'
              '${_displayItems.length != 1 ? 's' : ''}',
              style: const TextStyle(color: kGrey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ PRODUCT LIST â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildList() {
    return RefreshIndicator(
      color: kRed,
      onRefresh: _load,
      child: ProductBrowserView(
        items: _displayItems,
        viewMode: _browser.viewMode,
        onTap: (item) => _goDetail(item.productId),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  // â”€â”€ SORT SHEET â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
          for (final option in ProductSortOption.values.where(
            (option) => option != ProductSortOption.priceAsc,
          ))
            ListTile(
              title: Text(option.label),
              trailing: _browser.sortOption == option
                  ? const Icon(Icons.check, color: kRed)
                  : null,
              onTap: () {
                _browser.sortOption = option;
                Navigator.pop(context);
              },
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // â”€â”€ NAVIGATION â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _goDetail(String id) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailPage(productId: id)),
    ).then((_) => _load());
  }

  void _goAdd() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddProductPage()),
    ).then((_) => _load());
  }
}
