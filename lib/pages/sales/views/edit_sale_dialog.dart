import 'package:flutter/material.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../models/sale_model.dart';
import '../../../widgets/shared_widgets.dart';
import '../../../features/sales/services/sale_operations_service.dart';

Future<SaleModel?> showEditSaleDialog(BuildContext context, SaleModel sale) async {
  final cs = Theme.of(context).colorScheme;
  final customerCtrl = TextEditingController(text: sale.customerName);
  final paidCtrl = TextEditingController(
    text: sale.amountPaid.toStringAsFixed(2),
  );
  final notesCtrl = TextEditingController(text: sale.notes);
  final reasonCtrl = TextEditingController(text: 'Sale correction');
  var paymentType = sale.paymentType;
  final editedItems = sale.items.toList();
  final qtyCtrls = sale.items
      .map((item) => TextEditingController(text: item.qty.toString()))
      .toList();
  final priceCtrls = sale.items
      .map(
        (item) => TextEditingController(text: item.price.toStringAsFixed(2)),
      )
      .toList();
  final discountCtrls = sale.items
      .map(
        (item) =>
            TextEditingController(text: item.discount.toStringAsFixed(2)),
      )
      .toList();

  SaleModel? result;
  await showDialog<void>(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (ctx, setD) {
        double subtotal = 0;
        double discount = 0;
        final currentItems = <SaleItemModel>[];
        for (var i = 0; i < editedItems.length; i++) {
          final qty = int.tryParse(qtyCtrls[i].text.trim()) ?? 0;
          final price = double.tryParse(priceCtrls[i].text.trim()) ?? 0;
          final disc = double.tryParse(discountCtrls[i].text.trim()) ?? 0;
          if (qty <= 0) continue;
          final item = editedItems[i].copyWith(
            qty: qty,
            price: price,
            discount: disc,
          );
          currentItems.add(item);
          subtotal += price * qty;
          discount += disc;
        }
        final total = (subtotal - discount)
            .clamp(0, double.infinity)
            .toDouble();

        return AlertDialog(
          title: const Text('Edit Sale'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: customerCtrl,
                    decoration: AppInput.dialog(context, 'Customer name'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: paymentType,
                    decoration: AppInput.dialog(context, 'Payment type'),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'utang', child: Text('Utang')),
                      DropdownMenuItem(value: 'multi', child: Text('Multi')),
                    ],
                    onChanged: (value) {
                      if (value != null) setD(() => paymentType = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: paidCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.right,
                    onChanged: (_) => setD(() {}),
                    decoration: AppInput.dialog(context, 'Amount paid'),
                  ),
                  const SizedBox(height: 12),
                  ...editedItems.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.productName} - ${item.variantName}'
                                  '${item.conditionName.isNotEmpty ? ' / ${item.conditionName}' : ''}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: cs.primary,
                                  size: 18,
                                ),
                                onPressed: () => setD(() {
                                  editedItems.removeAt(i);
                                  qtyCtrls.removeAt(i).dispose();
                                  priceCtrls.removeAt(i).dispose();
                                  discountCtrls.removeAt(i).dispose();
                                }),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: qtyCtrls[i],
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setD(() {}),
                                  decoration: AppInput.dialog(context, 'Qty'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: priceCtrls[i],
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setD(() {}),
                                  decoration: AppInput.dialog(context, 'Price'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: discountCtrls[i],
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setD(() {}),
                                  decoration: AppInput.dialog(context, 'Discount'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        infoRow('Subtotal', AppHelpers.peso(subtotal)),
                        infoRow('Discount', AppHelpers.peso(discount)),
                        infoRow('Total', AppHelpers.peso(total)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: AppInput.dialog(context, 'Notes'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: reasonCtrl,
                    decoration: AppInput.dialog(context, 'Edit reason'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: currentItems.isEmpty
                  ? null
                  : () {
                      final paid =
                          double.tryParse(paidCtrl.text.trim()) ??
                          sale.amountPaid;
                      result = sale.copyWith(
                        customerName: customerCtrl.text.trim().isEmpty
                            ? 'Walk-in'
                            : customerCtrl.text.trim(),
                        items: currentItems,
                        subtotal: subtotal,
                        totalDiscount: discount,
                        total: total,
                        amountPaid: paid,
                        change: paid > total ? paid - total : 0,
                        paymentType: paymentType,
                        notes: notesCtrl.text.trim(),
                      );
                      Navigator.pop(ctx);
                    },
              child: Text(
                'Save',
                style: TextStyle(color: cs.primary),
              ),
            ),
          ],
        );
      },
    ),
  );

  for (final ctrl in [...qtyCtrls, ...priceCtrls, ...discountCtrls]) {
    ctrl.dispose();
  }
  final reason = reasonCtrl.text.trim().isEmpty
      ? 'Sale correction'
      : reasonCtrl.text.trim();
  customerCtrl.dispose();
  paidCtrl.dispose();
  notesCtrl.dispose();
  reasonCtrl.dispose();

  final edited = result;
  if (edited == null || !context.mounted) return null;
  await SaleOperationsService.editSale(
    original: sale,
    edited: edited,
    reason: reason,
  );
  return edited;
}
