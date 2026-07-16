import 'package:flutter/material.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../core/utils/session.dart';
import '../../../models/utang_model.dart';
import '../../../repositories/sale_repository.dart';
import '../../../repositories/utang_repository.dart';
import '../../../widgets/shared_widgets.dart';

// ── HELPERS ───────────────────────────────────────────────────

String utangItemName(Map<String, dynamic> item) {
  final product = '${item['productName'] ?? ''}'.trim();
  final variant = '${item['variantName'] ?? ''}'.trim();
  if (variant.isEmpty || variant == product) return product;
  return '$product - $variant';
}

String paymentDateTime(String iso) {
  final dt = DateTime.tryParse(iso);
  if (dt == null) return AppHelpers.formatDate(iso);
  return AppHelpers.formatDateTime(dt);
}

Future<void> _syncLinkedSale(UtangModel utang) async {
  if (utang.saleId.isEmpty) return;
  final sales = await SaleRepository.getAll();
  final matches = sales.where((sale) => sale.id == utang.saleId);
  if (matches.isEmpty) return;
  final sale = matches.first;
  final paid = utang.amountPaid.clamp(0, sale.total).toDouble();
  await SaleRepository.updateEdited(
    sale.copyWith(
      amountPaid: paid,
      change: 0,
      status: paid >= sale.total ? 'completed' : 'partial',
    ),
    action: 'edit_sale',
  );
}

// ── FORM DIALOG ───────────────────────────────────────────────

void showUtangFormDialog(
  BuildContext context, {
  UtangModel? existing,
  required VoidCallback onChanged,
}) {
  final nameCtrl = TextEditingController(text: existing?.customerName ?? '');
  final phoneCtrl = TextEditingController(
    text: existing?.customerPhone ?? '',
  );
  final totalCtrl = TextEditingController(
    text: existing?.totalAmount.toStringAsFixed(2) ?? '',
  );
  final paidCtrl = TextEditingController(
    text: existing?.amountPaid.toStringAsFixed(2) ?? '0.00',
  );
  final dueCtrl = TextEditingController(text: existing?.dueDate ?? '');
  final notesCtrl = TextEditingController(text: existing?.notes ?? '');
  const validStatuses = {'pending', 'partial', 'paid'};
  final existingStatus = existing?.status ?? 'pending';
  var status = validStatuses.contains(existingStatus)
      ? existingStatus
      : ((existing?.amountPaid ?? 0) > 0 ? 'partial' : 'pending');

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: Text(existing == null ? 'Add Utang' : 'Edit Utang'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: AppInput.dialog(context, 'Customer name *'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: AppInput.dialog(context, 'Phone'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: totalCtrl,
                  keyboardType: TextInputType.number,
                  decoration: AppInput.dialog(context, 'Total amount *'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: paidCtrl,
                  keyboardType: TextInputType.number,
                  decoration: AppInput.dialog(context, 'Amount paid'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: dueCtrl,
                  decoration: AppInput.dialog(context, 'Due date (YYYY-MM-DD)'),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Status',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _statusChoice(
                      ctx,
                      label: 'Pending',
                      value: 'pending',
                      selected: status,
                      onTap: () => setD(() => status = 'pending'),
                    ),
                    const SizedBox(width: 6),
                    _statusChoice(
                      ctx,
                      label: 'Partial',
                      value: 'partial',
                      selected: status,
                      onTap: () => setD(() => status = 'partial'),
                    ),
                    const SizedBox(width: 6),
                    _statusChoice(
                      ctx,
                      label: 'Paid',
                      value: 'paid',
                      selected: status,
                      onTap: () => setD(() => status = 'paid'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: AppInput.dialog(context, 'Notes'),
                ),
                const SizedBox(height: 10),
                _editIndicatorRow(
                  ctx,
                  existing == null ? 'Date and time' : 'Date modified',
                  existing == null
                      ? AppHelpers.formatDateTime(DateTime.now())
                      : paymentDateTime(existing.updatedAt),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
              ),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final total = double.tryParse(totalCtrl.text.trim()) ?? 0;
                final paid = double.tryParse(paidCtrl.text.trim()) ?? 0;
                if (name.isEmpty || total <= 0) return;

                final inferredStatus = paid >= total
                    ? 'paid'
                    : paid > 0
                        ? 'partial'
                        : status;
                final saved = await UtangRepository.save(
                  UtangModel(
                    id: existing?.id ?? '',
                    storeId: Session.storeId,
                    customerId: existing?.customerId ?? '',
                    customerName: name,
                    customerPhone: phoneCtrl.text.trim(),
                    saleId: existing?.saleId ?? '',
                    items: existing?.items ?? const [],
                    totalAmount: total,
                    amountPaid: paid.clamp(0, total).toDouble(),
                    startDate: existing?.startDate ?? AppHelpers.todayStr(),
                    dueDate: dueCtrl.text.trim(),
                    status: inferredStatus,
                    payments: existing?.payments ?? const [],
                    notes: notesCtrl.text.trim(),
                    updatedAt: AppHelpers.nowStr(),
                  ),
                );
                await _syncLinkedSale(saved);
                if (ctx.mounted) Navigator.pop(ctx);
                onChanged();
              },
              child: Text(existing == null ? 'Add' : 'Save'),
            ),
          ],
        );
      },
    ),
  );
}

// ── DELETE DIALOG ─────────────────────────────────────────────

Future<void> showUtangDeleteDialog(
  BuildContext context,
  UtangModel u, {
  required VoidCallback onChanged,
}) async {
  final cs = Theme.of(context).colorScheme;
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Delete Utang?'),
      content: Text('Remove ${u.customerName} debt record?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (ok == true) {
    await UtangRepository.delete(u.id);
    onChanged();
  }
}

// ── PAYMENT DIALOG ────────────────────────────────────────────

void showPaymentDialog(
  BuildContext context,
  UtangModel u, {
  required VoidCallback onChanged,
}) {
  String payMode = 'full';
  final amtCtrl = TextEditingController(text: u.balance.toStringAsFixed(2));
  String? selectedItemKey;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Pay — ${u.customerName}',
            style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Balance: ${AppHelpers.peso(u.balance)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 12),

                const Text(
                  'Payment Mode',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (final m in ['full', 'partial', 'item'])
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: GestureDetector(
                            onTap: () => setD(() => payMode = m),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: payMode == m ? cs.primary : cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                m[0].toUpperCase() + m.substring(1),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: payMode == m ? Colors.white : cs.onSurfaceVariant,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                if (payMode == 'partial') ...[
                  fieldLabel('Amount to Pay'),
                  TextField(
                    controller: amtCtrl,
                    keyboardType: TextInputType.number,
                    decoration: AppInput.dialog(context, '0.00'),
                  ),
                ],

                if (payMode == 'item') ...[
                  const Text(
                    'Select Item to Pay Off',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  ...u.items.map((item) {
                    final key = '${item['variantId']}';
                    final price =
                        ((item['price'] as num?)?.toDouble() ?? 0.0) *
                        ((item['qty'] as num?)?.toInt() ?? 0);
                    return GestureDetector(
                      onTap: () => setD(() => selectedItemKey = key),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: selectedItemKey == key
                              ? cs.primaryContainer
                              : cs.surfaceContainerLowest,
                          border: Border.all(
                            color: selectedItemKey == key
                                ? cs.primary
                                : cs.outlineVariant,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${utangItemName(item)} ×${item['qty']}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Text(
                              AppHelpers.peso(price),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
              ),
              onPressed: () async {
                double payAmount = 0;
                String paidItemId = '';
                String paidItemName = '';
                int paidQty = 0;

                if (payMode == 'full') {
                  payAmount = u.balance;
                } else if (payMode == 'partial') {
                  payAmount = double.tryParse(amtCtrl.text) ?? 0;
                } else if (payMode == 'item' && selectedItemKey != null) {
                  final item = u.items.firstWhere(
                    (i) => i['variantId'] == selectedItemKey,
                    orElse: () => {},
                  );
                  if (item.isNotEmpty) {
                    paidItemId = item['variantId'] ?? '';
                    paidItemName = utangItemName(item);
                    paidQty = (item['qty'] as num?)?.toInt() ?? 0;
                    payAmount =
                        ((item['price'] as num?)?.toDouble() ?? 0.0) * paidQty;
                  }
                }

                payAmount = payAmount.clamp(0, u.balance).toDouble();
                if (payAmount <= 0) return;

                final payment = UtangPaymentModel(
                  id: AppHelpers.newId(),
                  amount: payAmount,
                  method: payMode == 'item' ? 'item' : 'cash',
                  paidItemId: paidItemId,
                  paidItemName: paidItemName,
                  paidQty: paidQty,
                  date: AppHelpers.nowStr(),
                );

                final updated = await UtangRepository.addPayment(u, payment);
                await _syncLinkedSale(updated);
                if (ctx.mounted) Navigator.pop(ctx);
                onChanged();
              },
              child: const Text('Record'),
            ),
          ],
        );
      },
    ),
  );
}

// ── INTERNAL WIDGETS ──────────────────────────────────────────

Widget _editIndicatorRow(BuildContext context, String label, String value) {
  final cs = Theme.of(context).colorScheme;
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        Icon(Icons.schedule_outlined, size: 16, color: cs.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _statusChoice(
  BuildContext context, {
  required String label,
  required String value,
  required String selected,
  required VoidCallback onTap,
}) {
  final cs = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final active = selected == value;
  final color = value == 'paid'
      ? (isDark ? PaletteDark.success : PaletteLight.success)
      : value == 'partial'
          ? (isDark ? PaletteDark.warning : PaletteLight.warning)
          : cs.error;
  return Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? color : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? color : cs.outlineVariant),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : cs.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );
}
