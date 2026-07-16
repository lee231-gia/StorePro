import 'package:flutter/material.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../../dashboard/dashboard_controller.dart';

class DashboardTodaySales extends StatelessWidget {
  final DashboardController controller;

  const DashboardTodaySales({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? PaletteDark.primary : PaletteLight.primary;
    final success = isDark ? PaletteDark.success : PaletteLight.success;
    final cs = Theme.of(context).colorScheme;

    if (controller.loading) {
      return Row(
        children: [
          Expanded(
            child: AppSkeletonCard(height: 72, margin: EdgeInsets.zero),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AppSkeletonCard(height: 72, margin: EdgeInsets.zero),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withValues(alpha: 0.04),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Revenue",
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                ),
                Text(
                  AppHelpers.peso(controller.todayRevenue),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withValues(alpha: 0.04),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Profit",
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                ),
                Text(
                  AppHelpers.peso(controller.todayProfit),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: success,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
