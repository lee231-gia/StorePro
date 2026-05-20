import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/enums/product_browser_enums.dart';
import '../../core/services/sync_service.dart';
import '../../core/utils/app_helpers.dart';
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
  late final ProductBrowserController _browser;
  final _searchCtrl = TextEditingController();
  StreamSubscription<String>? _changeSub;

  List<ProductModel> _products = [];
  List<String> _categories = ['All'];
  bool _loading = true;

  List<ProductDisplayItem> get _items => _browser.displayItems(_products);

  @override
  void initState() {
    super.initState();
    _browser = ProductBrowserController(statusFilter: widget.initialFilter)
      ..addListener(_refreshBrowser);
    _changeSub = SyncService.changes.listen((collection) {
      if (collection == 'products' || collection == 'categories') _load();
    });
    _load();
  }

  @override
  void dispose() {
    _changeSub?.cancel();
    _browser
      ..removeListener(_refreshBrowser)
      ..dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _refreshBrowser() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    List<ProductModel> products = [];
    List<String> categories = ['All'];
    try {
      final results = await Future.wait([
        ProductRepository.getAll(),
        CategoryRepository.getAll(),
      ]).timeout(const Duration(seconds: 3));
      products = results[0] as List<ProductModel>;
      categories = [
        'All',
        ...(results[1] as List).map((category) => category.name as String),
      ];
    } catch (_) {}

    if (mounted) {
      setState(() {
        _products = products;
        _categories = categories;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: buildAppBar(title: 'Products', context: context),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: ProductBrowserToolbar(
              controller: _browser,
              searchController: _searchCtrl,
              categories: _categories,
              statusFilters: const [
                'All',
                'Available',
                'Low Stock',
                'No Stock',
                'Expiring',
                'Expired',
              ],
              itemCount: _items.length,
              sortOptions: const [
                ProductSortOption.recent,
                ProductSortOption.nameAsc,
                ProductSortOption.nameDesc,
                ProductSortOption.categoryAsc,
                ProductSortOption.categoryDesc,
                ProductSortOption.stockAsc,
                ProductSortOption.stockDesc,
                ProductSortOption.expiryAsc,
                ProductSortOption.expiryDesc,
                ProductSortOption.priceAsc,
                ProductSortOption.priceDesc,
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: kRed,
              onRefresh: _load,
              child: ProductBrowserView(
                items: _items,
                viewMode: _browser.viewMode,
                physics: const AlwaysScrollableScrollPhysics(),
                onTap: (item) => _goDetail(item.productId),
                trailingBuilder: (item) => Text(
                  AppHelpers.peso(item.price),
                  style: const TextStyle(
                    color: kRed,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                detailTrailingBuilder: (item) => Text(
                  AppHelpers.peso(item.price),
                  style: const TextStyle(
                    color: kRed,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
