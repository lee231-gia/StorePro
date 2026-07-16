part of 'inventory_page.dart';

extension _InventoryProductViews on _InventoryPageState {
  Widget _buildTopFilters({
    bool showSearch = true,
    EdgeInsets padding = const EdgeInsets.fromLTRB(16, 12, 16, 0),
  }) {
    return Padding(
      padding: padding,
      child: ProductBrowserToolbar(
        controller: _browser,
        searchController: _searchCtrl,
        categories: _categories,
        searchHint: showSearch ? 'Search products...' : 'Search...',
        itemCount: _browser.displayItems(_products).length,
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
        ],
      ),
    );
  }

  Widget _buildProductView(List<ProductModel> items, {bool showStock = false}) {
    final displayItems = ProductDisplayItem.fromProducts(
      items,
      groupVariants: _browser.groupVariants,
    );

    return ProductBrowserView(
      items: displayItems,
      viewMode: _browser.viewMode,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      onTap: (item) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailPage(productId: item.productId),
        ),
      ).then((_) => _load()),
      trailingBuilder: showStock ? _stockTrailing : null,
      showInlineInfo: !showStock,
      gridFooterBuilder: showStock
          ? (item) => _stockTrailing(item, alignRight: false)
          : null,
    );
  }

  Widget _buildReplenishProductView() {
    final displayItems = ProductDisplayItem.fromProducts(
      _filtered,
      groupVariants: _browser.groupVariants,
    );

    return ProductBrowserView(
      items: displayItems,
      viewMode: _browser.viewMode,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      emptyText: 'No products found.',
      onTap: _showVariantAdjustSheet,
      trailingBuilder: _replenishTrailing,
      detailTrailingBuilder: _replenishTrailing,
      gridFooterBuilder: (item) => _stockTrailing(item, alignRight: false),
      actionBuilder: _replenishActionPair,
    );
  }

  Widget _stockTrailing(ProductDisplayItem item, {bool alignRight = true}) {
    return Text(
      '${item.totalStock} pcs',
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 12,
        color: AppHelpers.stockColor(item.totalStock),
      ),
    );
  }

  Widget _replenishTrailing(ProductDisplayItem item) {
    final cs = Theme.of(context).colorScheme;
    final variant = item.variant;
    if (variant == null) return _stockTrailing(item);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _iconAction(
          Icons.add_circle_outline,
          cs.brightness == Brightness.dark ? PaletteDark.success : PaletteLight.success,
          () => _showAdjustDialog(
            product: item.product,
            variant: variant,
            isAdding: true,
          ),
        ),
        const SizedBox(width: 4),
        _iconAction(
          Icons.remove_circle_outline,
          cs.error,
          () => _showAdjustDialog(
            product: item.product,
            variant: variant,
            isAdding: false,
          ),
        ),
      ],
    );
  }

  Widget _replenishActionPair(ProductDisplayItem item) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.onPrimary.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(9),
        boxShadow: [
          BoxShadow(color: cs.shadow.withValues(alpha: 0.08), blurRadius: 6),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _iconAction(
            Icons.add,
            cs.brightness == Brightness.dark ? PaletteDark.success : PaletteLight.success,
            () => _showAdjustForItem(item, isAdding: true),
          ),
          Container(width: 1, height: 22, color: cs.outlineVariant),
          _iconAction(
            Icons.remove,
            cs.error,
            () => _showAdjustForItem(item, isAdding: false),
          ),
        ],
      ),
    );
  }

  Widget _iconAction(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  void _showVariantAdjustSheet(ProductDisplayItem item) {
    _showAdjustForItem(item, isAdding: true);
  }

  void _showAdjustForItem(ProductDisplayItem item, {required bool isAdding}) {
    final cs = Theme.of(context).colorScheme;
    if (item.variant != null) {
      _showAdjustDialog(
        product: item.product,
        variant: item.variant!,
        isAdding: isAdding,
      );
      return;
    }
    if (item.product.variants.length == 1) {
      final variant = item.product.variants.first;
      _showAdjustDialog(
        product: item.product,
        variant: variant,
        isAdding: isAdding,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                item.product.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              ...item.product.variants.map(
                (variant) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(variant.name),
                  subtitle: Text(
                    '${variant.totalStock} pcs | Cost: ${AppHelpers.peso(variant.avgCostPrice)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _iconAction(Icons.add_circle_outline, cs.brightness == Brightness.dark ? PaletteDark.success : PaletteLight.success, () {
                        Navigator.pop(context);
                        _showAdjustDialog(
                          product: item.product,
                          variant: variant,
                          isAdding: true,
                        );
                      }),
                      _iconAction(Icons.remove_circle_outline, cs.error, () {
                        Navigator.pop(context);
                        _showAdjustDialog(
                          product: item.product,
                          variant: variant,
                          isAdding: false,
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}
