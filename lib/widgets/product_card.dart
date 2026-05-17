import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_icons.dart';
import '../core/utils/app_helpers.dart';
import '../models/product_model.dart';

// ── PRODUCT CARD (list / compact view) ────────────────────────
class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final bool compact;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final expiry = product.nearestExpiry;
    final status = AppHelpers.expiryStatus(expiry);
    final stock = product.totalStock;

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
            // ── IMAGE / ICON ───────────────────────────────
            _buildImage(product, compact ? 36 : 44),
            SizedBox(width: compact ? 10 : 12),

            // ── PRODUCT INFO ───────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: compact ? 13 : 14,
                      color: kDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 3),

                  // Category + status badges
                  Wrap(
                    spacing: 5,
                    runSpacing: 3,
                    children: [
                      _badge(
                        product.categoryName,
                        kCategoryColors[product.colorIndex.clamp(
                          0,
                          kCategoryColors.length - 1,
                        )],
                      ),
                      if (status == 'expiring')
                        _badge('${AppHelpers.daysLeft(expiry)}d', kOrange),
                      if (status == 'expired') _badge('EXPIRED', kRed),
                    ],
                  ),

                  const SizedBox(height: 2),
                  // Stock count
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

            // ── PRICE ─────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppHelpers.peso(product.lowestPrice),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: kDark,
                  ),
                ),
                if (product.variants.length > 1)
                  Text(
                    '${product.variants.length} variants',
                    style: const TextStyle(fontSize: 10, color: kGrey),
                  ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: kGrey, size: 18),
          ],
        ),
      ),
    );
  }

  // ── BADGE ─────────────────────────────────────────────────
  Widget _badge(String label, Color color) => Container(
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

// ── IMAGE / ICON BUILDER (shared) ─────────────────────────────
Widget _buildImage(ProductModel p, double size) {
  final color =
      kCategoryColors[p.colorIndex.clamp(0, kCategoryColors.length - 1)];

  if (p.imageUrl.isNotEmpty) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: CachedNetworkImage(
        imageUrl: p.imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, _) => _iconBox(p, size, color),
        errorWidget: (_, _, _) => _iconBox(p, size, color),
      ),
    );
  }
  return _iconBox(p, size, color);
}

Widget _iconBox(ProductModel p, double size, Color color) => Container(
  width: size,
  height: size,
  decoration: BoxDecoration(
    color: color.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(10),
  ),
    child: Icon(AppIcons.get(p.iconIndex), color: color, size: size * 0.46),
);

// ── PRODUCT GRID CARD ─────────────────────────────────────────
class ProductGridCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const ProductGridCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        kCategoryColors[product.colorIndex.clamp(
          0,
          kCategoryColors.length - 1,
        )];
    final stock = product.totalStock;

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
            // Image / icon area
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: product.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      height: 90,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) =>
                          _gridIconBox(color, product.iconIndex),
                    )
                  : _gridIconBox(color, product.iconIndex),
            ),

            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
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
                        AppHelpers.peso(product.lowestPrice),
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

  Widget _gridIconBox(Color color, int iconIndex) => Container(
    height: 90,
    width: double.infinity,
    color: color.withValues(alpha: 0.12),
    child: Icon(AppIcons.get(iconIndex), color: color, size: 32),
  );
}

// ── FILTER CHIP ───────────────────────────────────────────────
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
