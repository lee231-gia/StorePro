import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:storepro/widgets/sale_widgets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/app_helpers.dart';
import '../../models/customer_model.dart';
import '../../models/product_model.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/product_card.dart';

part 'cart_sheet.dart';
part 'payment_sheet.dart';

// ── DRAG HANDLE ───────────────────────────────────────────────
Widget _handle(BuildContext context) => Column(
  children: [
    const SizedBox(height: 12),
    Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
    const SizedBox(height: 8),
  ],
);

// ══════════════════════════════════════════════════════════════
// 1. VARIANT PICKER SHEET
// ══════════════════════════════════════════════════════════════
void showVariantPickerSheet({
  required BuildContext context,
  required ProductModel product,
  required void Function(CartItem) onAdd,
}) {
  final variants = product.variants;
  final catColor =
      kCategoryColors[product.colorIndex.clamp(0, kCategoryColors.length - 1)];
  final icon = AppIcons.get(product.iconIndex);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, ctrl) => Column(
        children: [
          _handle(context),

          // Product header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: catColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '${variants.length} variant'
                        '${variants.length == 1 ? '' : 's'} available',
                        style: TextStyle(color: catColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(),

          // Variant list
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.all(14),
              children: variants.map<Widget>((v) {
                final cs = Theme.of(context).colorScheme;
                final stock = v.totalStock;
                final conditions = v.conditions;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      // Variant info
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    v.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '${v.unit} · '
                                    '${v.pcsPerUnit} pcs/unit',
                                    style: TextStyle(
                                      color: cs.onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    AppHelpers.peso(v.price),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: cs.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Stock badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppHelpers.stockColor(
                                  stock,
                                ).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$stock pcs',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppHelpers.stockColor(stock),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 1),

                      // Conditions or simple add
                      if (conditions.isNotEmpty)
                        ...conditions.map<Widget>(
                          (c) => ListTile(
                            dense: true,
                            title: Text(
                              c.name,
                              style: const TextStyle(fontSize: 13),
                            ),
                            trailing: Text(
                              AppHelpers.peso(c.price),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              ),
                            ),
                            onTap: stock > 0
                                ? () {
                                    Navigator.pop(context);
                                    onAdd(
                                      CartItem(
                                        productId: product.id,
                                        variantId: v.id,
                                        productName: product.name,
                                        variantName: v.name,
                                        conditionName: c.name,
                                        imageUrl: v.imageUrl.isNotEmpty
                                            ? v.imageUrl
                                            : product.imageUrl,
                                        iconIndex: product.iconIndex,
                                        colorIndex: product.colorIndex,
                                        price: c.price,
                                        costPrice: v.costPrice,
                                      ),
                                    );
                                  }
                                : null,
                          ),
                        )
                      else
                        ListTile(
                          dense: true,
                          title: Text(
                            'Add to Cart',
                            style: TextStyle(fontSize: 13, color: cs.primary),
                          ),
                          trailing: Text(
                            AppHelpers.peso(v.price),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                          ),
                          onTap: stock > 0
                              ? () {
                                  Navigator.pop(context);
                                  onAdd(
                                    CartItem(
                                      productId: product.id,
                                      variantId: v.id,
                                      productName: product.name,
                                      variantName: v.name,
                                      imageUrl: v.imageUrl.isNotEmpty
                                          ? v.imageUrl
                                          : product.imageUrl,
                                      iconIndex: product.iconIndex,
                                      colorIndex: product.colorIndex,
                                      price: v.price,
                                      costPrice: v.costPrice,
                                    ),
                                  );
                                }
                              : null,
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════
// 2. CART SHEET
// ══════════════════════════════════════════════════════════════
