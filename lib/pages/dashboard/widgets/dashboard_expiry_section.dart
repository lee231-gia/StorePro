import 'package:flutter/material.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../../../widgets/dashboard_cards.dart';
import '../../dashboard/dashboard_controller.dart';

class DashboardExpirySection extends StatelessWidget {
  final DashboardController controller;
  final void Function(String productId) openProductDetail;
  final VoidCallback? onSeeAll;

  const DashboardExpirySection({
    super.key,
    required this.controller,
    required this.openProductDetail,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? PaletteDark.primary : PaletteLight.primary;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Expiry Alerts',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                'See all',
                style: TextStyle(color: primary, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (controller.loading)
          const AppSkeletonList(itemCount: 3)
        else if (controller.expiryAlerts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'No expiry alerts',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
              ),
            ),
          )
        else
          ...controller.expiryAlerts
              .take(5)
              .map(
                (item) => DashboardExpiryRow(
                  item: item,
                  onTap: () =>
                      openProductDetail(item['productId'] as String),
                ),
              ),
        const SizedBox(height: 20),
      ],
    );
  }
}
