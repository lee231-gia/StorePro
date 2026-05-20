part of 'sales_sheets.dart';

void showCartSheet({
  required BuildContext context,
  required List<CartItem> cart,
  required TextEditingController customerCtrl,
  required TextEditingController notesCtrl,
  required void Function(int, int) onChangeQty,
  required void Function(int) onRemove,
  required void Function(int, double) onItemDiscount,
  required VoidCallback onConfirm,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => StatefulBuilder(
      builder: (ctx, setS) {
        // Recompute totals every rebuild
        final subtotal = cart.fold(0.0, (s, i) => s + i.subtotal);
        final discTotal = cart.fold(0.0, (s, i) => s + i.itemDiscount);

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          builder: (_, ctrl) => Column(
            children: [
              _handle(),

              // Cart header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.shopping_cart_outlined, color: kRed),
                    const SizedBox(width: 8),
                    const Text(
                      'Cart',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${cart.length} item'
                      '${cart.length != 1 ? 's' : ''}',
                      style: const TextStyle(color: kGrey, fontSize: 13),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Cart items
              Expanded(
                child: ListView.builder(
                  controller: ctrl,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: cart.length,
                  itemBuilder: (_, i) {
                    final item = cart[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: kCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.035),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: kDark,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.conditionName.isNotEmpty
                                          ? '${item.variantName} / ${item.conditionName}'
                                          : item.variantName,
                                      style: const TextStyle(
                                        color: kGrey,
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${AppHelpers.peso(item.price)} each',
                                      style: const TextStyle(
                                        color: kGrey,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: kGrey,
                                  size: 18,
                                ),
                                onPressed: () {
                                  onRemove(i);
                                  setS(() {});
                                  if (cart.isEmpty) {
                                    Navigator.pop(ctx);
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: kInputFill,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                        color: kGrey,
                                      ),
                                      onPressed: () {
                                        onChangeQty(i, -1);
                                        setS(() {});
                                        if (cart.isEmpty) {
                                          Navigator.pop(ctx);
                                        }
                                      },
                                    ),
                                    SizedBox(
                                      width: 28,
                                      child: Text(
                                        '${item.qty}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                        color: kRed,
                                      ),
                                      onPressed: () {
                                        onChangeQty(i, 1);
                                        setS(() {});
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Line total',
                                    style: TextStyle(
                                      color: kGrey,
                                      fontSize: 10,
                                    ),
                                  ),
                                  Text(
                                    AppHelpers.peso(item.subtotal),
                                    style: const TextStyle(
                                      color: kRed,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(
                                Icons.discount_outlined,
                                size: 13,
                                color: kGrey,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Discount',
                                style: TextStyle(fontSize: 11, color: kGrey),
                              ),
                              const Spacer(),
                              SizedBox(
                                width: 92,
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 12),
                                  textAlign: TextAlign.right,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText: '0.00',
                                    prefixText: 'P ',
                                    filled: true,
                                    fillColor: kInputFill,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 8,
                                    ),
                                  ),
                                  onChanged: (v) {
                                    final d = double.tryParse(v) ?? 0.0;
                                    onItemDiscount(i, d);
                                    setS(() {});
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // ── TOTAL + CUSTOMER + CONFIRM ────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  MediaQuery.of(ctx).viewInsets.bottom + 16,
                ),
                child: Column(
                  children: [
                    // Summary
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: kRedLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          if (discTotal > 0) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Subtotal'),
                                Text(AppHelpers.peso(subtotal + discTotal)),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Discount',
                                  style: TextStyle(color: kOrange),
                                ),
                                Text(
                                  '- ${AppHelpers.peso(discTotal)}',
                                  style: const TextStyle(color: kOrange),
                                ),
                              ],
                            ),
                            const Divider(height: 8),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'TOTAL',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                AppHelpers.peso(subtotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: kRed,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Customer name
                    TextField(
                      controller: customerCtrl,
                      decoration: AppInput.field(
                        'Customer name (optional)',
                        icon: Icons.person_outline,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Notes
                    TextField(
                      controller: notesCtrl,
                      decoration: AppInput.field(
                        'Notes (optional)',
                        icon: Icons.note_outlined,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Confirm
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          onConfirm();
                        },
                        child: Text(
                          'Proceed  ${AppHelpers.peso(subtotal)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

// ══════════════════════════════════════════════════════════════
// 3. PAYMENT SHEET
// ══════════════════════════════════════════════════════════════
