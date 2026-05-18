import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/enums/product_browser_enums.dart';
import '../../models/category_model.dart';
import '../../models/product_model.dart';
import '../../repositories/category_repository.dart';
import '../../repositories/product_repository.dart';
import '../../shared/controllers/product_browser_controller.dart';
import '../../shared/widgets/product_browser_view.dart';
import '../../widgets/shared_widgets.dart';
import '../products/add_product_page.dart';
import '../products/product_detail_page.dart';

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
  late final ProductBrowserController _browser;

  @override
  void initState() {
    super.initState();
    _browser = ProductBrowserController()
      ..addListener(() {
        if (mounted) setState(() {});
      });
    _load();
  }

  @override
  void dispose() {
    _browser.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);

    // Instant SQLite
    var all = <ProductModel>[];
    var cats = <CategoryModel>[];
    try {
      final results = await Future.wait([
        ProductRepository.getAll(),
        CategoryRepository.getAll(),
      ]).timeout(const Duration(seconds: 3));
      all = results[0] as List<ProductModel>;
      cats = results[1] as List<CategoryModel>;
    } catch (_) {}

    final products = _productsForCategory(all);
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
      if (mounted) setState(() => _products = _productsForCategory(fresh));
    });
  }

  List<ProductModel> _productsForCategory(List<ProductModel> products) {
    return products.where((p) => p.categoryId == widget.categoryId).toList();
  }

  @override
  Widget build(BuildContext context) {
    final color = _category != null
        ? kCategoryColors[_category!.colorIndex.clamp(
            0,
            kCategoryColors.length - 1,
          )]
        : kRed;
    final icon = _category != null
        ? AppIcons.get(_category!.iconIndex)
        : Icons.category_outlined;

    return Scaffold(
      backgroundColor: kBg,
      appBar: buildAppBar(
        title: widget.categoryName,
        context: context,
        showMenu: false,
        showBack: true,
        actions: [
          PopupMenuButton<ProductViewMode>(
            icon: const Icon(Icons.view_module),
            onSelected: (value) => _browser.viewMode = value,
            itemBuilder: (_) => ProductViewMode.values
                .map(
                  (mode) => PopupMenuItem(value: mode, child: Text(mode.label)),
                )
                .toList(),
          ),
          PopupMenuButton<ProductSortOption>(
            icon: const Icon(Icons.sort),
            onSelected: (value) => _browser.sortOption = value,
            itemBuilder: (_) => ProductSortOption.values
                .where((option) => option != ProductSortOption.priceAsc)
                .map(
                  (option) =>
                      PopupMenuItem(value: option, child: Text(option.label)),
                )
                .toList(),
          ),
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
          if (_loading) const LinearProgressIndicator(color: kRed),
          _headerCard(color, icon),
          Expanded(child: _productBrowser(icon)),
        ],
      ),
    );
  }

  Widget _headerCard(Color color, IconData icon) {
    return Padding(
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: kDark,
                    ),
                  ),
                  if (_category?.details.isNotEmpty == true)
                    Text(
                      _category!.details,
                      style: const TextStyle(color: kGrey, fontSize: 12),
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
    );
  }

  Widget _productBrowser(IconData icon) {
    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.grey.shade300, size: 60),
            const SizedBox(height: 12),
            const Text('No products here yet.', style: TextStyle(color: kGrey)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: kRed,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddProductPage()),
              ).then((_) => _load()),
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: kRed,
      onRefresh: _load,
      child: ProductBrowserView(
        items: _browser.displayItems(_products),
        viewMode: _browser.viewMode,
        onTap: (item) => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailPage(productId: item.productId),
          ),
        ).then((_) => _load()),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
