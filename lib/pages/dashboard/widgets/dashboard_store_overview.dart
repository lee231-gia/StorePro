import 'package:flutter/material.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../core/utils/session.dart';
import '../../dashboard/dashboard_controller.dart';

class DashboardStoreOverview extends StatelessWidget {
  final DashboardController controller;

  const DashboardStoreOverview({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? PaletteDark.primary : PaletteLight.primary;
    final cs = Theme.of(context).colorScheme;
    final lastActivity = controller.activityLogs.isEmpty
        ? 'No activity yet'
        : _actionLabel(controller.activityLogs.first);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storefront_outlined, color: primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  Session.storeName.isEmpty
                      ? 'Store Overview'
                      : Session.storeName,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            [
              '${controller.products.length} products',
              '${controller.salesCount} sales',
              '${AppHelpers.peso(controller.totalRevenue)} lifetime revenue',
            ].join('  •  '),
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11, height: 1.5),
          ),
          const SizedBox(height: 6),
          Text(
            'Latest: $lastActivity',
            style: TextStyle(color: cs.onSurface, fontSize: 11),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (controller.lastSynced.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Synced from local app data: ${AppHelpers.formatDateTime(DateTime.tryParse(controller.lastSynced) ?? DateTime.now())}',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  static String _actionLabel(Map<String, dynamic> log) {
    final action = (log['action'] as String? ?? '').toLowerCase();
    final details = log['details'];
    final productName = details is Map
        ? (details['productName'] ?? log['targetName'] ?? '').toString()
        : (log['targetName'] ?? '').toString();
    if (action == 'new_sale') return 'New Sale Completed';
    if (action == 'add_product') {
      return productName.isEmpty
          ? 'Added New Product'
          : 'Added New Product: "$productName"';
    }
    if (action == 'edit_product') {
      return productName.isEmpty
          ? 'Edited Existing Product'
          : 'Edited Product: "$productName"';
    }
    if (action == 'delete_product') return 'Deleted Product';
    if (action == 'add_customer') {
      return productName.isEmpty
          ? 'Added Customer'
          : 'Added Customer: "$productName"';
    }
    if (action == 'edit_customer') {
      return productName.isEmpty
          ? 'Updated Customer'
          : 'Updated Customer: "$productName"';
    }
    if (action == 'delete_customer') return 'Deleted Customer';
    final text = action.replaceAll('_', ' ');
    return text.isEmpty
        ? 'Activity'
        : '${text[0].toUpperCase()}${text.substring(1)}';
  }
}
