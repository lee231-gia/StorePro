import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/enums/product_browser_enums.dart';
import '../../core/utils/app_helpers.dart';
import '../../models/product_model.dart';
import '../../widgets/product_card.dart';

class ProductBrowserView extends StatelessWidget {
  final List<ProductDisplayItem> items;
  final ProductViewMode viewMode;
  final ValueChanged<ProductDisplayItem> onTap;
  final ScrollPhysics? physics;
  final EdgeInsets padding;
  final bool shrinkWrap;
  final Widget Function(ProductDisplayItem item)? trailingBuilder;
  final Widget Function(ProductDisplayItem item)? detailTrailingBuilder;
  final List<Widget> Function(ProductDisplayItem item)? badgeBuilder;
  final Widget Function(ProductDisplayItem item)? gridFooterBuilder;
  final Widget Function(ProductDisplayItem item)? actionBuilder;
  final bool Function(ProductDisplayItem item)? enabledBuilder;
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
    this.detailTrailingBuilder,
    this.badgeBuilder,
    this.gridFooterBuilder,
    this.actionBuilder,
    this.enabledBuilder,
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
            childAspectRatio: 0.78,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => ProductGridCard(
            product: items[i].product,
            variant: items[i].variant,
            badges: badgeBuilder?.call(items[i]) ?? const [],
            footer: gridFooterBuilder?.call(items[i]),
            action: actionBuilder?.call(items[i]),
            enabled: enabledBuilder?.call(items[i]) ?? true,
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
          itemBuilder: (_, i) => _ProductDetailTile(
            item: items[i],
            badges: badgeBuilder?.call(items[i]) ?? const [],
            trailing: detailTrailingBuilder?.call(items[i]),
            onTap: () => onTap(items[i]),
          ),
        );
      case ProductViewMode.compact:
        return ListView.builder(
          shrinkWrap: shrinkWrap,
          physics: physics,
          padding: padding,
          itemCount: items.length,
          itemBuilder: (_, i) => _ProductCompactTile(
            item: items[i],
            badges: badgeBuilder?.call(items[i]) ?? const [],
            trailing: trailingBuilder?.call(items[i]),
            enabled: enabledBuilder?.call(items[i]) ?? true,
            onTap: () => onTap(items[i]),
          ),
        );
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
            extraBadges: badgeBuilder?.call(items[i]) ?? const [],
            enabled: enabledBuilder?.call(items[i]) ?? true,
          ),
        );
    }
  }
}

class _ProductDetailTile extends StatelessWidget {
  final ProductDisplayItem item;
  final List<Widget> badges;
  final Widget? trailing;
  final VoidCallback onTap;

  const _ProductDetailTile({
    required this.item,
    required this.badges,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(12),
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
                trailing ??
                    Text(
                      AppHelpers.peso(item.price),
                      style: const TextStyle(
                        color: kRed,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                ProductDetailInfoChip(
                  icon: Icons.inventory_2_outlined,
                  label: '${item.totalStock} pcs',
                ),
                ProductDetailInfoChip(
                  icon: Icons.event_outlined,
                  label: item.nearestExpiry.isEmpty
                      ? 'No Expiry'
                      : item.nearestExpiry,
                ),
                ...badges,
              ],
            ),
            if (item.variant == null && item.variantCount > 1) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),
              ...item.product.variants.map(_variantRow),
            ],
          ],
        ),
      ),
    );
  }

  Widget _variantRow(VariantModel variant) {
    final expiry = variant.nearestExpiry;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.subdirectory_arrow_right, size: 14, color: kGrey),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              variant.name,
              style: const TextStyle(fontSize: 12, color: kDark),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 118,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppHelpers.peso(variant.price),
                  style: const TextStyle(
                    fontSize: 11,
                    color: kRed,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  expiry.isEmpty
                      ? '${variant.totalStock} pcs'
                      : '${variant.totalStock} pcs | ${AppHelpers.formatDate(expiry)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppHelpers.stockColor(variant.totalStock),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCompactTile extends StatelessWidget {
  final ProductDisplayItem item;
  final List<Widget> badges;
  final Widget? trailing;
  final bool enabled;
  final VoidCallback onTap;

  const _ProductCompactTile({
    required this.item,
    required this.badges,
    required this.trailing,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.62,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: enabled ? onTap : null,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              ProductImage(
                item: item,
                size: 44,
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: kDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    ProductInlineInfo(
                      fontSize: 10,
                      entries: [
                        ProductInlineEntry(
                          Icons.inventory_2_outlined,
                          '${item.totalStock} pcs',
                          AppHelpers.stockColor(item.totalStock),
                        ),
                        if (!item.isVariant && item.variantCount > 1)
                          ProductInlineEntry(
                            Icons.account_tree_outlined,
                            '${item.variantCount} variants',
                            kGrey,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (badges.isNotEmpty) ...[
                const SizedBox(width: 6),
                Flexible(
                  flex: 0,
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    children: badges.take(1).toList(),
                  ),
                ),
              ],
              if (trailing != null) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 72,
                  height: 42,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: trailing!,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
