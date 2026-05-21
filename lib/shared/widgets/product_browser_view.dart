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
  final bool showInlineInfo;
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
    this.showInlineInfo = true,
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
            showInlineInfo: showInlineInfo,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProductImage(
                  item: item,
                  size: 48,
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: kDark,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      ProductInlineInfo(
                        entries: [
                          ProductInlineEntry(
                            Icons.inventory_2_outlined,
                            '${item.totalStock} pcs',
                            AppHelpers.stockColor(item.totalStock),
                          ),
                          ProductInlineEntry(
                            Icons.event_outlined,
                            item.nearestExpiry.isEmpty
                                ? 'No expiry'
                                : AppHelpers.formatDate(item.nearestExpiry),
                            kGrey,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 88,
                  child: Align(
                    alignment: Alignment.topRight,
                    child:
                        trailing ??
                        Text(
                          AppHelpers.peso(item.price),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: kRed,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                  ),
                ),
              ],
            ),
            if (badges.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 4, children: badges),
            ],
            if (item.variant == null && item.variantCount > 1) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),
              ...item.product.variants.map(
                (variant) => _variantRow(context, variant),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _variantRow(BuildContext context, VariantModel variant) {
    final expiry = variant.nearestExpiry;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          if (variant.imageUrl.isNotEmpty) ...[
            GestureDetector(
              onTap: () => _previewVariantImage(context, variant.imageUrl),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Image.network(
                  variant.imageUrl,
                  width: 28,
                  height: 28,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      const SizedBox(width: 28, height: 28),
                ),
              ),
            ),
            const SizedBox(width: 7),
          ],
          Expanded(
            child: Text(
              _variantDisplayName(variant),
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
                      : '${variant.totalStock} pcs \u2022 ${AppHelpers.formatDate(expiry)}',
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

  String _variantDisplayName(VariantModel variant) {
    final productName = item.product.name.trim();
    final variantName = variant.name.trim();
    if (variantName.isEmpty || variantName == productName) return productName;
    return '$productName - $variantName';
  }

  void _previewVariantImage(BuildContext context, String imageUrl) {
    if (imageUrl.isEmpty) return;
    showDialog(
      context: context,
      builder: (_) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          ),
        ),
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
