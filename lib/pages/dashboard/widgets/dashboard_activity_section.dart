import 'package:flutter/material.dart';
import '../../../core/utils/app_helpers.dart';
import '../../dashboard/dashboard_controller.dart';

class DashboardActivitySection extends StatelessWidget {
  final DashboardController controller;
  final void Function() onSeeAll;

  const DashboardActivitySection({
    super.key,
    required this.controller,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                'See all',
                style: TextStyle(color: cs.primary, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
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
          child: controller.activityLogs.isEmpty
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'No recent activity yet.',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                  ),
                )
              : Column(
                  children: controller.activityLogs
                      .take(5)
                      .map((log) => _DashboardActivityRow(log: log))
                      .toList(),
                ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _DashboardActivityRow extends StatelessWidget {
  final Map<String, dynamic> log;

  const _DashboardActivityRow({required this.log});

  @override
  Widget build(BuildContext context) {
    final action = actionLabel(log);
    final timestamp = (log['timestamp'] ?? '').toString();
    final total = _overviewTotal(log);
    final lower = action.toLowerCase();
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    var color = cs.onSurfaceVariant;
    if (lower.contains('add') || lower.contains('new')) {
      color = isDark ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32);
    }
    if (lower.contains('delete')) {
      color = isDark ? const Color(0xFFEF5350) : const Color(0xFFC62828);
    }
    if (lower.contains('sale')) {
      color = isDark ? const Color(0xFFFF7043) : const Color(0xFFE65100);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              Container(
                width: 1,
                height: 28,
                color: cs.outlineVariant,
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$action$total',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  AppHelpers.formatDateTime(
                    DateTime.tryParse(timestamp) ?? DateTime.now(),
                  ),
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String actionLabel(Map<String, dynamic> log) {
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

  String _overviewTotal(Map<String, dynamic> log) {
    if ((log['action'] as String? ?? '').toLowerCase() != 'new_sale') return '';
    final details = log['details'];
    if (details is! Map) return '';
    final total = (details['grandTotal'] as num?)?.toDouble();
    return total == null ? '' : ' (Grand Total: ${AppHelpers.peso(total)})';
  }
}
