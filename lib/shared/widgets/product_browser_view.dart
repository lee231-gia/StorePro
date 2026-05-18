import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/enums/product_browser_enums.dart';
import '../../core/utils/app_helpers.dart';
import '../../widgets/product_card.dart';

class ProductBrowserView extends StatelessWidget {
  final List<ProductDisplayItem> items;
  final ProductViewMode viewMode;
  final ValueChanged<ProductDisplayItem> onTap;
  final ScrollPhysics? physics;
  final EdgeInsets padding;
  final bool shrinkWrap;
  final Widget Function(ProductDisplayItem item)? trailingBuilder;
  final String emptyText;

  const ProductBrowserView({
    super.key,
    required this.items,
    required this.viewMode,
    required this.onTap,
    this.physics,
    this.padding = const EdgeInsets.all(16),
    this.shrinkWrap = false,
    this.trailingBuilder,
    this.emptyText = 'No products found.',
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(emptyText, style: const TextStyle(color: kGrey)),
        ),
      );
    }
    switch (viewMode) {
      case ProductViewMode.grid:
        return GridView.builder(
          shrinkWrap: shrinkWrap,
          physics: physics,
          padding: padding,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.82,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => ProductGridCard(
            product: items[i].product,
            variant: items[i].variant,
            onTap: () => onTap(items[i]),
          ),
        );
      case ProductViewMode.details:
        return ListView.separated(
          shrinkWrap: shrinkWrap,
          physics: physics,
          padding: padding,
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, i) =>
              _ProductDetailTile(item: items[i], onTap: () => onTap(items[i])),
        );
      case ProductViewMode.compact:
      case ProductViewMode.list:
        return ListView.builder(
          shrinkWrap: shrinkWrap,
          physics: physics,
          padding: padding,
          itemCount: items.length,
          itemBuilder: (_, i) => ProductCard(
            product: items[i].product,
            variant: items[i].variant,
            compact: viewMode == ProductViewMode.compact,
            onTap: () => onTap(items[i]),
            trailing: trailingBuilder?.call(items[i]),
          ),
        );
    }
  }
}

class _ProductDetailTile extends StatelessWidget {
  final ProductDisplayItem item;
  final VoidCallback onTap;

  const _ProductDetailTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: kDark,
                    ),
                  ),
                ),
                Text(
                  '${item.totalStock} pcs',
                  style: TextStyle(
                    color: AppHelpers.stockColor(item.totalStock),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(Icons.category_outlined, item.categoryName),
                _chip(Icons.payments_outlined, AppHelpers.peso(item.price)),
                _chip(
                  Icons.event_outlined,
                  item.nearestExpiry.isEmpty ? 'No Expiry' : item.nearestExpiry,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: kGrey),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: kGrey)),
        ],
      ),
    );
  }
}
