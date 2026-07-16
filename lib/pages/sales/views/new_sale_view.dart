import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/enums/product_browser_enums.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../shared/widgets/product_browser_toolbar.dart';
import '../../../shared/widgets/product_browser_view.dart';
import '../../../widgets/product_card.dart';
import '../sales_controller.dart';

class NewSaleView extends StatelessWidget {
  final SalesController controller;

  const NewSaleView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: ProductBrowserToolbar(
            controller: controller.browser,
            searchController: controller.searchCtrl,
            categories: controller.categories,
            searchHint: 'Search products...',
            itemCount: controller.saleItems.length,
            sortOptions: const [
              ProductSortOption.nameAsc,
              ProductSortOption.nameDesc,
              ProductSortOption.categoryAsc,
              ProductSortOption.categoryDesc,
              ProductSortOption.stockDesc,
              ProductSortOption.stockAsc,
              ProductSortOption.priceAsc,
              ProductSortOption.priceDesc,
            ],
          ),
        ),

        if (controller.cart.isNotEmpty)
          GestureDetector(
            onTap: () => controller.openCart(context),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    color: cs.onPrimary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${controller.cartCount} item'
                      '${controller.cartCount != 1 ? 's' : ''} in cart',
                      style: TextStyle(color: cs.onPrimary, fontSize: 13),
                    ),
                  ),
                  Text(
                    AppHelpers.peso(controller.cartTotal),
                    style: TextStyle(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.keyboard_arrow_up,
                    color: cs.onPrimary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

        Expanded(
          child: ProductBrowserView(
            items: controller.saleItems,
            viewMode: controller.browser.viewMode,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            onTap: (item) => controller.selectProductItem(context, item),
            enabledBuilder: (item) => item.totalStock > 0,
            trailingBuilder: (item) => _saleTrailing(context, item),
            actionBuilder: (item) => _saleAction(context, item),
            gridFooterBuilder: (item) => _saleGridFooter(context, item),
          ),
        ),
        if (controller.showLegacySaleList)
          Expanded(
            child: controller.saleItems.isEmpty
                ? Center(
                    child: Text(
                      'No products found.',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: controller.saleItems.length,
                    itemBuilder: (_, i) {
                      final item = controller.saleItems[i];
                      final p = item.product;
                      final stock = item.totalStock;
                      final color = kCategoryColors[p.colorIndex.clamp(
                        0,
                        kCategoryColors.length - 1,
                      )];

                      return GestureDetector(
                        onTap: stock > 0
                            ? () => controller.selectProductItem(context, item)
                            : null,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: cs.shadow.withValues(alpha: 0.04),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  AppIcons.get(p.iconIndex),
                                  color: color,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                    Text(
                                      '${item.isVariant ? 'Variant' : '${p.variants.length} variant${p.variants.length != 1 ? 's' : ''}'}'
                                      '  \u2022  $stock pcs',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppHelpers.stockColor(stock),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              stock == 0
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: cs.primaryContainer,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'No Stock',
                                        style: TextStyle(
                                          color: cs.primary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      Icons.add_circle_outline,
                                      color: cs.primary,
                                      size: 22,
                                    ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
      ],
    );
  }

  Widget _saleTrailing(BuildContext context, ProductDisplayItem item) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppHelpers.peso(item.price),
          style: TextStyle(
            color: cs.primary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 2),
        item.totalStock == 0
            ? ProductActionPill(
                icon: Icons.block_outlined,
                label: 'No Stock',
                color: cs.primary,
              )
            : Icon(Icons.add_circle_outline, color: cs.primary, size: 22),
      ],
    );
  }

  Widget _saleAction(BuildContext context, ProductDisplayItem item) {
    final cs = Theme.of(context).colorScheme;
    return ProductActionPill(
      icon: item.totalStock == 0 ? Icons.block_outlined : Icons.add,
      label: item.totalStock == 0 ? 'No Stock' : 'Add',
      color: cs.primary,
    );
  }

  Widget _saleGridFooter(BuildContext context, ProductDisplayItem item) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            '${item.totalStock} pcs',
            style: TextStyle(
              color: AppHelpers.stockColor(item.totalStock),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          AppHelpers.peso(item.price),
          textAlign: TextAlign.right,
          style: TextStyle(
            color: cs.primary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
