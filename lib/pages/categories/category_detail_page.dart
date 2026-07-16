import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/constants/app_icons.dart';
import '../../core/enums/product_browser_enums.dart';
import '../../models/product_model.dart';
import '../../models/category_model.dart';
import '../../repositories/product_repository.dart';
import '../../repositories/category_repository.dart';
import '../../shared/controllers/product_browser_controller.dart';
import '../../shared/widgets/product_browser_toolbar.dart';
import '../../shared/widgets/product_browser_view.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/product_card.dart';
import '../products/product_detail_page.dart';
import '../products/add_product_page.dart';

class CategoryDetailPage extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryDetailPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryDetailPage> createState() => _CategoryDetailPageState();
}

class _CategoryDetailPageState extends State<CategoryDetailPage> {
  List<ProductModel> _products = [];
  CategoryModel? _category;
  bool _loading = true;
  String _sort = 'recent';
  String _view = 'list';
  late final ProductBrowserController _browser;
  final _searchCtrl = TextEditingController();

  List<ProductDisplayItem> get _items => _browser.displayItems(_products);
  bool get _showLegacyCategoryList => false;

  @override
  void initState() {
    super.initState();
    _browser = ProductBrowserController(
      sortOption: ProductSortOption.recent,
      categoryFilter: widget.categoryName,
    )..addListener(_onBrowserChanged);
    _load();
  }

  @override
  void dispose() {
    _browser
      ..removeListener(_onBrowserChanged)
      ..dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onBrowserChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    // Instant SQLite
    Future<T> safe<T>(Future<T> future, T fallback) async {
      try {
        return await future.timeout(const Duration(seconds: 5));
      } catch (_) {
        return fallback;
      }
    }
    final all = await safe(ProductRepository.getAll(), <ProductModel>[]);
    final cats = await safe(CategoryRepository.getAll(), <CategoryModel>[]);

    final products = all
        .where((p) => p.categoryId == widget.categoryId)
        .toList();
    final cat = cats.where((c) => c.id == widget.categoryId).isNotEmpty
        ? cats.firstWhere((c) => c.id == widget.categoryId)
        : null;

    if (mounted) {
      setState(() {
        _products = products;
        _category = cat;
        _loading = false;
      });
    }

    // Background sync
    ProductRepository.syncInBackground((fresh) {
      if (!mounted) return;
      setState(() {
        _products = fresh
            .where((p) => p.categoryId == widget.categoryId)
            .toList();
      });
    });
  }

  List<ProductModel> get _sorted {
    final list = List<ProductModel>.from(_products);
    switch (_sort) {
      case 'a-z':
        list.sort((a, b) => a.name.compareTo(b.name));
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _category != null
        ? kCategoryColors[_category!.colorIndex.clamp(
            0,
            kCategoryColors.length - 1,
          )]
        : cs.primary;
    final icon = _category != null
        ? AppIcons.get(_category!.iconIndex)
        : Icons.category_outlined;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: buildAppBar(
        title: widget.categoryName,
        context: context,
        showMenu: false,
        showBack: true,
        actions: [
          if (_showLegacyCategoryList) ...[
            // View toggle
            IconButton(
              icon: Icon(
                _view == 'grid'
                    ? Icons.view_list_outlined
                    : Icons.grid_view_outlined,
              ),
              onPressed: () =>
                  setState(() => _view = _view == 'grid' ? 'list' : 'grid'),
            ),
            // Sort
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort),
              onSelected: (v) => setState(() => _sort = v),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'recent', child: Text('Recently Added')),
                PopupMenuItem(value: 'a-z', child: Text('Name A → Z')),
                PopupMenuItem(
                  value: 'stock-low',
                  child: Text('Stock Low → High'),
                ),
                PopupMenuItem(value: 'expiry', child: Text('Expiry Date')),
              ],
            ),
          ],
          // Add product
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddProductPage()),
            ).then((_) => _load()),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_loading) LinearProgressIndicator(color: Theme.of(context).colorScheme.primary),
          // ── HEADER CARD ──────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: appCard(
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.categoryName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        if (_category?.details.isNotEmpty == true)
                          Text(
                            _category!.details,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                          ),
                        const SizedBox(height: 2),
                        Text(
                          '${_products.length} product'
                          '${_products.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── PRODUCTS ─────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: ProductBrowserToolbar(
              controller: _browser,
              searchController: _searchCtrl,
              categories: [widget.categoryName],
              searchHint: 'Search products...',
              itemCount: _items.length,
              sortOptions: const [
                ProductSortOption.recent,
                ProductSortOption.nameAsc,
                ProductSortOption.nameDesc,
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
            child: ProductBrowserView(
              items: _items,
              viewMode: _browser.viewMode,
              onTap: (item) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailPage(productId: item.productId),
                ),
              ).then((_) => _load()),
            ),
          ),
          if (_showLegacyCategoryList)
            Expanded(
              child: _products.isEmpty
                  ?                     Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, color: Theme.of(context).colorScheme.outlineVariant, size: 60),
                          const SizedBox(height: 12),
                          Text(
                            'No products here yet.',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddProductPage(),
                              ),
                            ).then((_) => _load()),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Product'),
                          ),
                        ],
                      ),
                    )
                  : _view == 'grid'
                  ? GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.8,
                          ),
                      itemCount: _sorted.length,
                      itemBuilder: (_, i) => ProductGridCard(
                        product: _sorted[i],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProductDetailPage(productId: _sorted[i].id),
                          ),
                        ).then((_) => _load()),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _sorted.length,
                      itemBuilder: (_, i) => ProductCard(
                        product: _sorted[i],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProductDetailPage(productId: _sorted[i].id),
                          ),
                        ).then((_) => _load()),
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}
