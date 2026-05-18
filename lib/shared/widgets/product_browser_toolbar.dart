import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/enums/product_browser_enums.dart';
import '../../widgets/product_card.dart';
import '../../widgets/shared_widgets.dart';
import '../controllers/product_browser_controller.dart';

class ProductBrowserToolbar extends StatelessWidget {
  final ProductBrowserController controller;
  final TextEditingController searchController;
  final List<String> categories;
  final List<String> statusFilters;
  final String searchHint;
  final bool showViewMode;
  final bool showGroupToggle;
  final List<ProductSortOption> sortOptions;

  const ProductBrowserToolbar({
    super.key,
    required this.controller,
    required this.searchController,
    required this.categories,
    this.statusFilters = const [],
    this.searchHint = 'Search products...',
    this.showViewMode = true,
    this.showGroupToggle = true,
    this.sortOptions = ProductSortOption.values,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  onChanged: (value) => controller.search = value,
                  decoration: AppInput.field(searchHint, icon: Icons.search),
                ),
              ),
              if (showViewMode) _viewMenu(),
              _sortMenu(),
            ],
          ),
          const SizedBox(height: 8),
          _chipList(
            values: categories,
            selected: controller.categoryFilter,
            onSelected: (value) => controller.categoryFilter = value,
          ),
          if (statusFilters.isNotEmpty) ...[
            const SizedBox(height: 8),
            _chipList(
              values: statusFilters,
              selected: controller.statusFilter,
              onSelected: (value) => controller.statusFilter = value,
            ),
          ],
          if (showGroupToggle)
            Row(
              children: [
                VariantToggleButton(
                  grouped: controller.groupVariants,
                  onChanged: (value) => controller.groupVariants = value,
                ),
                const Spacer(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _viewMenu() {
    return PopupMenuButton<ProductViewMode>(
      icon: const Icon(Icons.view_module, color: kGrey),
      initialValue: controller.viewMode,
      onSelected: (value) => controller.viewMode = value,
      itemBuilder: (_) => ProductViewMode.values
          .map((mode) => PopupMenuItem(value: mode, child: Text(mode.label)))
          .toList(),
    );
  }

  Widget _sortMenu() {
    return PopupMenuButton<ProductSortOption>(
      icon: const Icon(Icons.sort, color: kGrey),
      initialValue: controller.sortOption,
      onSelected: (value) => controller.sortOption = value,
      itemBuilder: (_) => sortOptions
          .map(
            (option) => PopupMenuItem(value: option, child: Text(option.label)),
          )
          .toList(),
    );
  }

  Widget _chipList({
    required List<String> values,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final value = values[i];
          final active = selected == value;
          return GestureDetector(
            onTap: () => onSelected(value),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: active ? kRed : kCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: active ? kRed : Colors.grey.shade300),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  color: active ? Colors.white : kGrey,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
