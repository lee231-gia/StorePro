part of 'inventory_page.dart';

extension _InventoryProductViews on _InventoryPageState {
  Widget _buildTopFilters({
    bool showSearch = true,
    EdgeInsets padding = const EdgeInsets.fromLTRB(16, 12, 16, 0),
  }) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search + view toggle + sort row
          Row(
            children: [
              if (showSearch)
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => _update(() => _search = v),
                    decoration: AppInput.field('Search...', icon: Icons.search),
                  ),
                ),
              const SizedBox(width: 8),
              // View mode
              PopupMenuButton<String>(
                icon: const Icon(Icons.view_module, color: kGrey),
                onSelected: (v) => _update(() => _viewMode = v),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'list', child: Text('List')),
                  PopupMenuItem(value: 'compact', child: Text('Compact')),
                  PopupMenuItem(value: 'grid', child: Text('Grid')),
                  PopupMenuItem(value: 'details', child: Text('Details')),
                ],
              ),
              // Sort
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort, color: kGrey),
                onSelected: (v) => _update(() => _sortBy = v),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'recent', child: Text('Recently Added')),
                  PopupMenuItem(value: 'a-z', child: Text('Name A → Z')),
                  PopupMenuItem(value: 'z-a', child: Text('Name Z → A')),
                  PopupMenuItem(
                    value: 'cat-a-z',
                    child: Text('Category A → Z'),
                  ),
                  PopupMenuItem(
                    value: 'cat-z-a',
                    child: Text('Category Z → A'),
                  ),
                  PopupMenuItem(
                    value: 'stock-low',
                    child: Text('Stock: Low → High'),
                  ),
                  PopupMenuItem(
                    value: 'stock-high',
                    child: Text('Stock: High → Low'),
                  ),
                  PopupMenuItem(
                    value: 'expiry-asc',
                    child: Text('Expiry: Nearest First'),
                  ),
                  PopupMenuItem(
                    value: 'expiry-desc',
                    child: Text('Expiry: Furthest First'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Category chips
          SizedBox(
            height: 30,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final active = _catFilter == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => _update(() => _catFilter = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
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
                          fontSize: 11,
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
        ],
      ),
    );
  }

  // ── PRODUCT VIEW (4 modes) ────────────────────────────────
  Widget _buildProductView(List<ProductModel> items, {bool showStock = false}) {
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No products found.', style: TextStyle(color: kGrey)),
        ),
      );
    }

    switch (_viewMode) {
      case 'grid':
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.9,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => _gridCard(items[i]),
        );
      case 'compact':
        return Column(children: items.map((p) => _compactRow(p)).toList());
      case 'details':
        return Column(children: items.map((p) => _detailCard(p)).toList());
      default: // list
        return Column(children: items.map((p) => _listCard(p)).toList());
    }
  }

  Widget _listCard(ProductModel p) {
    final color =
        kCategoryColors[p.colorIndex.clamp(0, kCategoryColors.length - 1)];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(AppIcons.get(p.iconIndex), color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: kDark,
                  ),
                ),
                Text(
                  p.categoryName,
                  style: const TextStyle(color: kGrey, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            '${p.totalStock} pcs',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: AppHelpers.stockColor(p.totalStock),
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactRow(ProductModel p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              p.name,
              style: const TextStyle(fontSize: 12, color: kDark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            p.categoryName,
            style: const TextStyle(color: kGrey, fontSize: 11),
          ),
          const SizedBox(width: 12),
          Text(
            '${p.totalStock} pcs',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: AppHelpers.stockColor(p.totalStock),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gridCard(ProductModel p) {
    final color =
        kCategoryColors[p.colorIndex.clamp(0, kCategoryColors.length - 1)];
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(AppIcons.get(p.iconIndex), color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            p.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: kDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            p.categoryName,
            style: const TextStyle(color: kGrey, fontSize: 10),
          ),
          const Spacer(),
          Text(
            '${p.totalStock} pcs',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: AppHelpers.stockColor(p.totalStock),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailCard(ProductModel p) {
    final color =
        kCategoryColors[p.colorIndex.clamp(0, kCategoryColors.length - 1)];
    return appCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(AppIcons.get(p.iconIndex), color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: kDark,
                      ),
                    ),
                    Text(
                      p.categoryName,
                      style: TextStyle(color: color, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 12),
          ...p.variants.map(
            (v) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.subdirectory_arrow_right,
                    size: 13,
                    color: kGrey,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${v.name}'
                      '${v.sku.isNotEmpty ? ' (${v.sku})' : ''}',
                      style: const TextStyle(fontSize: 12, color: kGrey),
                    ),
                  ),
                  Text(
                    '${v.totalStock} pcs',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppHelpers.stockColor(v.totalStock),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) =>
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
                      style: const TextStyle(fontSize: 10, color: kGrey),
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
