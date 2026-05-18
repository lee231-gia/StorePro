import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_icons.dart';
import '../core/utils/app_helpers.dart';
import '../models/product_model.dart';

class ProductDisplayItem {
  final ProductModel product;
  final VariantModel? variant;

  const ProductDisplayItem({required this.product, this.variant});

  factory ProductDisplayItem.grouped(ProductModel product) =>
      ProductDisplayItem(product: product);

  String get id {
    final selectedVariant = variant;
    return selectedVariant == null
        ? product.id
        : '${product.id}:${selectedVariant.id}';
  }

  String get productId => product.id;
  String get variantId => variant?.id ?? '';
  String get name {
    final selectedVariant = variant;
    return selectedVariant == null
        ? product.name
        : '${product.name} - ${selectedVariant.name}';
  }

  String get categoryName => product.categoryName;
  int get colorIndex => product.colorIndex;
  int get iconIndex => product.iconIndex;
  String get imageUrl {
    final selectedVariant = variant;
    return selectedVariant != null && selectedVariant.imageUrl.isNotEmpty
        ? selectedVariant.imageUrl
        : product.imageUrl;
  }

  int get totalStock => variant?.totalStock ?? product.totalStock;
  double get price => variant?.price ?? product.lowestPrice;
  String get nearestExpiry => variant?.nearestExpiry ?? product.nearestExpiry;
  bool get isVariant => variant != null;
  int get variantCount => product.variants.length;

  static List<ProductDisplayItem> fromProducts(
    Iterable<ProductModel> products, {
    required bool groupVariants,
  }) {
    final items = <ProductDisplayItem>[];
    for (final product in products) {
      if (groupVariants || product.variants.length <= 1) {
        items.add(ProductDisplayItem.grouped(product));
      } else {
        items.addAll(
          product.variants.map(
            (variant) => ProductDisplayItem(product: product, variant: variant),
          ),
        );
      }
    }
    return items;
  }
}

class ProductImage extends StatelessWidget {
  final ProductDisplayItem item;
  final double size;
  final double? height;
  final double? width;
  final BorderRadius borderRadius;

  const ProductImage({
    super.key,
    required this.item,
    required this.size,
    this.height,
    this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
  });

  @override
  Widget build(BuildContext context) {
    final color =
        kCategoryColors[item.colorIndex.clamp(0, kCategoryColors.length - 1)];
    final h = height ?? size;
    final w = width ?? size;
    if (item.imageUrl.isEmpty) return _iconBox(w, h, color);

    return Container(
      width: w,
      height: h,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: borderRadius,
      ),
      child: CachedNetworkImage(
        imageUrl: item.imageUrl,
        fit: BoxFit.contain,
        placeholder: (_, _) => _iconBox(w, h, color),
        errorWidget: (_, _, _) => _iconBox(w, h, color),
      ),
    );
  }

  Widget _iconBox(double width, double height, Color color) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: borderRadius,
    ),
    child: Icon(
      AppIcons.get(item.iconIndex),
      color: color,
      size: height * 0.46,
    ),
  );
}

class ProductBadge extends StatelessWidget {
  final String label;
  final Color color;

  const ProductBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
    ),
  );
}

class VariantToggleButton extends StatelessWidget {
  final bool grouped;
  final ValueChanged<bool> onChanged;

  const VariantToggleButton({
    super.key,
    required this.grouped,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: () => onChanged(!grouped),
    icon: Icon(
      grouped ? Icons.account_tree_outlined : Icons.view_agenda_outlined,
      size: 18,
    ),
    label: Text(grouped ? 'Grouped' : 'Ungrouped'),
    style: TextButton.styleFrom(foregroundColor: kRed),
  );
}

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VariantModel? variant;
  final VoidCallback onTap;
  final bool compact;
  final Widget? trailing;
  final List<Widget> extraBadges;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.compact = false,
    this.variant,
    this.trailing,
    this.extraBadges = const [],
  });

  @override
  Widget build(BuildContext context) {
    final item = ProductDisplayItem(product: product, variant: variant);
    final expiry = item.nearestExpiry;
    final status = AppHelpers.expiryStatus(expiry);
    final stock = item.totalStock;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.all(compact ? 10 : 12),
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
            ProductImage(item: item, size: compact ? 40 : 48),
            SizedBox(width: compact ? 10 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: compact ? 13 : 14,
                      color: kDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: 5,
                    runSpacing: 3,
                    children: [
                      ProductBadge(
                        label: item.categoryName,
                        color:
                            kCategoryColors[item.colorIndex.clamp(
                              0,
                              kCategoryColors.length - 1,
                            )],
                      ),
                      if (item.isVariant)
                        const ProductBadge(label: 'VARIANT', color: kGrey),
                      if (status == 'expiring')
                        ProductBadge(
                          label: '${AppHelpers.daysLeft(expiry)}d',
                          color: kOrange,
                        ),
                      if (status == 'expired')
                        const ProductBadge(label: 'EXPIRED', color: kRed),
                      ...extraBadges,
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$stock pcs',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppHelpers.stockColor(stock),
                    ),
                  ),
                ],
              ),
            ),
            trailing ??
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppHelpers.peso(item.price),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: kDark,
                      ),
                    ),
                    if (!item.isVariant && item.variantCount > 1)
                      Text(
                        '${item.variantCount} variants',
                        style: const TextStyle(fontSize: 10, color: kGrey),
                      ),
                  ],
                ),
            if (trailing == null) ...[
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: kGrey, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}

class ProductGridCard extends StatelessWidget {
  final ProductModel product;
  final VariantModel? variant;
  final VoidCallback onTap;

  const ProductGridCard({
    super.key,
    required this.product,
    required this.onTap,
    this.variant,
  });

  @override
  Widget build(BuildContext context) {
    final item = ProductDisplayItem(product: product, variant: variant);
    final stock = item.totalStock;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductImage(
              item: item,
              size: 90,
              height: 90,
              width: double.infinity,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: kDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppHelpers.peso(item.price),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: kRed,
                        ),
                      ),
                      Text(
                        '$stock pcs',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppHelpers.stockColor(stock),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? activeColor;

  const FilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? kRed;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          border: Border.all(color: isSelected ? color : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isSelected ? Colors.white : kGrey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
