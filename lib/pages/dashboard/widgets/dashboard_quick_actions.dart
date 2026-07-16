import 'package:flutter/material.dart';
import '../../../core/theme/app_palette.dart';
import '../../dashboard/dashboard_controller.dart';

class DashboardQuickActions extends StatelessWidget {
  final DashboardController controller;
  final void Function(int) changeTab;
  final VoidCallback? onAddProduct;

  const DashboardQuickActions({
    super.key,
    required this.controller,
    required this.changeTab,
    this.onAddProduct,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? PaletteDark.accent : PaletteLight.accent;
    final cs = Theme.of(context).colorScheme;

    final actions = [
      _ActionItem(
        icon: Icons.point_of_sale_outlined,
        label: 'New Sale',
        onTap: () => changeTab(4),
      ),
      _ActionItem(
        icon: Icons.add_box_outlined,
        label: 'Add Product',
        onTap: onAddProduct ?? () {},
      ),
      _ActionItem(
        icon: Icons.inventory_outlined,
        label: 'Restock',
        onTap: () => changeTab(2),
      ),
      _ActionItem(
        icon: Icons.account_balance_wallet_outlined,
        label: 'Utang',
        onTap: () => changeTab(5),
      ),
      _ActionItem(
        icon: Icons.bar_chart_outlined,
        label: 'Reports',
        onTap: () => changeTab(9),
      ),
      _ActionItem(
        icon: Icons.people_outline,
        label: 'Customers',
        onTap: () => changeTab(8),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final perRow = constraints.maxWidth > 500 ? 6 : 3;
            final rows = <List<_ActionItem>>[];
            for (var i = 0; i < actions.length; i += perRow) {
              rows.add(actions.sublist(
                i,
                i + perRow > actions.length
                    ? actions.length
                    : i + perRow,
              ));
            }
            return Column(
              children: rows
                  .map((row) => Padding(
                        padding: EdgeInsets.only(
                          bottom: row == rows.last ? 0 : 8,
                        ),
                        child: Row(
                          children: row
                              .map((item) => Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        left: row.indexOf(item) > 0 ? 8 : 0,
                                      ),
                                      child: _buildActionBtn(item, cs, accent),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionBtn(_ActionItem item, ColorScheme cs, Color accent) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(item.icon, color: accent, size: 22),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                color: cs.onSurface,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}
