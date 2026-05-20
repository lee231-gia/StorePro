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
      if (product.variants.length == 1) {
        items.add(
          ProductDisplayItem(product: product, variant: product.variants.first),
        );
      } else if (groupVariants) {
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
  final EdgeInsets padding;

  const ProductImage({
    super.key,
    required this.item,
    required this.size,
    this.height,
    this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
    this.padding = const EdgeInsets.all(6),
  });

  @override
  Widget build(BuildContext context) {
    final color =
        kCategoryColors[item.colorIndex.clamp(0, kCategoryColors.length - 1)];
    final h = height ?? size;
    final w = width ?? size;
    if (item.imageUrl.isEmpty) return _iconBox(w, h, color);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = (w * dpr).clamp(96, 720).round();
    final cacheHeight = (h * dpr).clamp(96, 720).round();

    return GestureDetector(
      onTap: () => _showImagePreview(context, item.imageUrl),
      child: Container(
        width: w,
        height: h,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: borderRadius,
        ),
        child: Padding(
          padding: padding,
          child: CachedNetworkImage(
            imageUrl: _optimizedImageUrl(item.imageUrl, cacheWidth),
            fit: BoxFit.cover,
            alignment: Alignment.center,
            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,
            memCacheWidth: cacheWidth,
            memCacheHeight: cacheHeight,
            maxWidthDiskCache: cacheWidth,
            maxHeightDiskCache: cacheHeight,
            placeholder: (_, _) => _iconBox(w, h, color),
            errorWidget: (_, _, _) => _iconBox(w, h, color),
          ),
        ),
      ),
    );
  }

  String _optimizedImageUrl(String url, int width) {
    if (!url.contains('/upload/') || url.contains('/upload/c_')) return url;
    final targetWidth = width.clamp(160, 900);
    return url.replaceFirst(
      '/upload/',
      '/upload/c_fill,g_auto,w_$targetWidth,q_auto,f_auto/',
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

  void _showImagePreview(BuildContext context, String url) {
    if (url.isEmpty) return;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.contain,
                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                    errorWidget: (_, _, _) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white70,
                      size: 48,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white24,
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
  final bool enabled;
  final bool showInlineInfo;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.compact = false,
    this.variant,
    this.trailing,
    this.extraBadges = const [],
    this.enabled = true,
    this.showInlineInfo = true,
  });

  @override
  Widget build(BuildContext context) {
    final item = ProductDisplayItem(product: product, variant: variant);
    final expiry = item.nearestExpiry;
    final status = AppHelpers.expiryStatus(expiry);
    final stock = item.totalStock;

    return Opacity(
      opacity: enabled ? 1 : 0.62,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
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
              ProductImage(
                item: item,
                size: compact ? 48 : 58,
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(10),
              ),
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
                    if (!compact)
                      Wrap(
                        spacing: 5,
                        runSpacing: 3,
                        children: [
                          if (!item.isVariant && item.variantCount > 1)
                            ProductBadge(
                              label: '${item.variantCount} variants',
                              color: kGrey,
                            ),
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
                    if (showInlineInfo)
                      ProductInlineInfo(
                        entries: [
                          ProductInlineEntry(
                            Icons.inventory_2_outlined,
                            '$stock pcs',
                            AppHelpers.stockColor(stock),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              if (trailing != null)
                SizedBox(
                  width: 82,
                  height: compact ? 42 : 48,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: trailing!,
                    ),
                  ),
                )
              else
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
                  ],
                ),
              if (trailing == null) ...[
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: kGrey, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ProductGridCard extends StatelessWidget {
  final ProductModel product;
  final VariantModel? variant;
  final VoidCallback onTap;
  final List<Widget> badges;
  final Widget? footer;
  final Widget? action;
  final bool enabled;

  const ProductGridCard({
    super.key,
    required this.product,
    required this.onTap,
    this.variant,
    this.badges = const [],
    this.footer,
    this.action,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final item = ProductDisplayItem(product: product, variant: variant);
    final stock = item.totalStock;

    return Opacity(
      opacity: enabled ? 1 : 0.62,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          clipBehavior: Clip.antiAlias,
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
              Expanded(
                flex: 7,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ProductImage(
                        item: item,
                        size: 112,
                        height: double.infinity,
                        width: double.infinity,
                        padding: EdgeInsets.zero,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(14),
                        ),
                      ),
                    ),
                    if (action != null)
                      Positioned(top: 8, right: 8, child: action!),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (badges.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Wrap(spacing: 4, runSpacing: 4, children: badges),
                      ],
                      const Spacer(),
                      footer ??
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  AppHelpers.peso(item.price),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: kRed,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$stock pcs',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppHelpers.stockColor(stock),
                                ),
                              ),
                            ],
                          ),
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
}

class ProductActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const ProductActionPill({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class BrowserFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color activeColor;

  const BrowserFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.activeColor = kRed,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      height: 32,
      constraints: const BoxConstraints(minWidth: 58),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isSelected ? activeColor : kCard,
        border: Border.all(
          color: isSelected ? activeColor : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : kGrey,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    ),
  );
}

class ProductDetailInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const ProductDetailInfoChip({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text('•', style: TextStyle(fontSize: 12, color: kGrey)),
      const SizedBox(width: 5),
      Flexible(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: kGrey),
        ),
      ),
    ],
  );
}

class ProductInlineEntry {
  final IconData icon;
  final String text;
  final Color color;

  const ProductInlineEntry(this.icon, this.text, this.color);
}

class ProductInlineInfo extends StatelessWidget {
  final List<ProductInlineEntry> entries;
  final double fontSize;

  const ProductInlineInfo({
    super.key,
    required this.entries,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 7,
    runSpacing: 2,
    children: [
      for (var i = 0; i < entries.length; i++)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (i > 0) ...[
              const Text('•', style: TextStyle(fontSize: 10, color: kGrey)),
              const SizedBox(width: 5),
            ],
            Text(
              entries[i].text,
              style: TextStyle(
                fontSize: fontSize,
                color: entries[i].color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
    ],
  );
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
    return BrowserFilterChip(
      label: label,
      isSelected: isSelected,
      onTap: onTap,
      activeColor: activeColor ?? kRed,
    );
  }
}
