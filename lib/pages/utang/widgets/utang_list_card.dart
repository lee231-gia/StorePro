import 'package:flutter/material.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../models/utang_model.dart';
import '../../../widgets/shared_widgets.dart';

class UtangListCard extends StatelessWidget {
  final UtangModel utang;
  final VoidCallback onTap;

  const UtangListCard({
    super.key,
    required this.utang,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = utang.status == 'paid'
        ? (isDark ? PaletteDark.success : PaletteLight.success)
        : utang.status == 'partial'
            ? (isDark ? PaletteDark.warning : PaletteLight.warning)
            : cs.error;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        utang.customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Since ${AppHelpers.formatDate(utang.startDate)}'
                        '${utang.dueDate.isNotEmpty ? '  ·  Due ${AppHelpers.formatDate(utang.dueDate)}' : ''}',
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppHelpers.peso(utang.totalAmount),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: cs.onSurface,
                      ),
                    ),
                    statusBadge(utang.status.toUpperCase(), statusColor),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: utang.totalAmount > 0
                    ? (utang.amountPaid / utang.totalAmount).clamp(0.0, 1.0)
                    : 0,
                backgroundColor: cs.outlineVariant,
                color: statusColor,
                minHeight: 6,
              ),
            ),

            const SizedBox(height: 4),

            Row(
              children: [
                _amountMetric(context, 'Total', utang.totalAmount, cs.onSurface),
                _amountMetric(context, 'Paid', utang.amountPaid, (isDark ? PaletteDark.success : PaletteLight.success)),
                _amountMetric(context, 'Balance', utang.balance, statusColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _amountMetric(BuildContext context, String label, double amount, Color color) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10)),
          Text(
            AppHelpers.peso(amount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
