import 'package:flutter/material.dart';
import '../../../core/theme/app_palette.dart';
import '../../dashboard/dashboard_controller.dart';

class DashboardOverviewSection extends StatelessWidget {
  final DashboardController controller;
  final void Function(int) changeTab;

  const DashboardOverviewSection({
    super.key,
    required this.controller,
    required this.changeTab,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            final items = [
              _OverviewItem(
                value: '${controller.products.length}',
                label: 'Total Products',
                icon: Icons.inventory_2_outlined,
                color: cs.primary,
                onTap: () => changeTab(1),
              ),
              _OverviewItem(
                value: '${controller.totalStock} pcs',
                label: 'Total Stock',
                icon: Icons.warehouse_outlined,
                color: cs.primary,
                onTap: () => changeTab(2),
              ),
              _OverviewItem(
                value: '${controller.lowStockCount}',
                label: 'Low Stock',
                icon: Icons.warning_amber_outlined,
                color: controller.lowStockCount > 0
                    ? (isDark ? PaletteDark.warning : PaletteLight.warning)
                    : (isDark ? PaletteDark.success : PaletteLight.success),
                onTap: () => changeTab(2),
              ),
              _OverviewItem(
                value: '${controller.expiringCount}',
                label: 'Expiry Alerts',
                icon: Icons.event_busy_outlined,
                color: controller.expiringCount > 0
                    ? (isDark ? PaletteDark.error : PaletteLight.error)
                    : (isDark ? PaletteDark.success : PaletteLight.success),
                onTap: () => changeTab(3),
              ),
            ];

            if (isWide) {
              return Row(
                children: items
                    .map((item) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: items.indexOf(item) > 0 ? 12 : 0,
                            ),
                            child: item,
                          ),
                        ))
                    .toList(),
              );
            }

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: items[0]),
                    const SizedBox(width: 12),
                    Expanded(child: items[1]),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: items[2]),
                    const SizedBox(width: 12),
                    Expanded(child: items[3]),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _OverviewItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _OverviewItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
