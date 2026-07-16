import 'package:flutter/material.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../models/utang_model.dart';
import '../../../widgets/shared_widgets.dart';
import 'utang_dialogs.dart';

void showUtangDetailSheet(
  BuildContext context,
  UtangModel u, {
  required VoidCallback onChanged,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (_, ctrl) => _DetailSheetContent(
        utang: u,
        scrollController: ctrl,
        onChanged: onChanged,
      ),
    ),
  );
}

class _DetailSheetContent extends StatelessWidget {
  final UtangModel utang;
  final ScrollController scrollController;
  final VoidCallback onChanged;

  const _DetailSheetContent({
    required this.utang,
    required this.scrollController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final u = utang;

    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: cs.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),

        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                u.customerName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: cs.onSurface,
                ),
              ),
              if (u.customerPhone.isNotEmpty)
                Text(
                  u.customerPhone,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                ),

              const SizedBox(height: 12),

              appCard(
                color: cs.primaryContainer,
                child: Column(
                  children: [
                    infoRow('Total', AppHelpers.peso(u.totalAmount)),
                    infoRow('Paid', AppHelpers.peso(u.amountPaid)),
                    infoRow('Balance', AppHelpers.peso(u.balance)),
                    infoRow('Status', u.status.toUpperCase()),
                    infoRow(
                      'Start Date',
                      AppHelpers.formatDate(u.startDate),
                    ),
                    if (u.dueDate.isNotEmpty)
                      infoRow('Due Date', AppHelpers.formatDate(u.dueDate)),
                  ],
                ),
              ),

              Text(
                'Items',
                style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface),
              ),
              const SizedBox(height: 6),
              ...u.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              utangItemName(item),
                              style: TextStyle(
                                fontSize: 13,
                                color: cs.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${item['qty']} × ${AppHelpers.peso((item['price'] as num?)?.toDouble() ?? 0.0)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppHelpers.peso(
                          ((item['price'] as num?)?.toDouble() ?? 0.0) *
                              ((item['qty'] as num?)?.toInt() ?? 0),
                        ),
                        style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),

              if (u.payments.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Payment History',
                  style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface),
                ),
                const SizedBox(height: 6),
                ...u.payments.map(
                  (p) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              paymentDateTime(p.date),
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurface,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          AppHelpers.peso(p.amount),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: (isDark ? PaletteDark.success : PaletteLight.success),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                      onPressed: () {
                        Navigator.pop(context);
                        showUtangFormDialog(
                          context,
                          existing: u,
                          onChanged: onChanged,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cs.primary,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        showUtangDeleteDialog(context, u, onChanged: onChanged);
                      },
                    ),
                  ),
                ],
              ),
              if (u.status != 'paid') ...[
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'Record Payment',
                  icon: Icons.payments_outlined,
                  onTap: () {
                    Navigator.pop(context);
                    showPaymentDialog(context, u, onChanged: onChanged);
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
