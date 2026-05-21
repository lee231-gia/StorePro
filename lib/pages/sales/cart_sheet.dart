part of 'sales_sheets.dart';

void showCartSheet({
  required BuildContext context,
  required List<CartItem> cart,
  required TextEditingController customerCtrl,
  required TextEditingController notesCtrl,
  List<CustomerModel> customers = const [],
  required void Function(int, int) onChangeQty,
  required void Function(int) onRemove,
  required void Function(int, double) onItemDiscount,
  required VoidCallback onConfirm,
}) {
  final discountCtrls = <String, TextEditingController>{};
  final customerFocus = FocusNode();
  final sheet = showModalBottomSheet(
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
          initialChildSize: 0.78,
          minChildSize: 0.48,
          maxChildSize: 0.95,
          builder: (_, ctrl) => SingleChildScrollView(
            controller: ctrl,
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).padding.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: cart.length,
                  itemBuilder: (_, i) {
                    final item = cart[i];
                    final discountCtrl = discountCtrls.putIfAbsent(
                      item.key,
                      () => TextEditingController(
                        text: item.itemDiscount > 0
                            ? item.itemDiscount.toStringAsFixed(2)
                            : '',
                      ),
                    );
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
                              _cartThumb(item),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.variantName.trim().isEmpty
                                          ? item.productName
                                          : '${item.productName} - ${item.variantName}',
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
                                          ? item.conditionName
                                          : '${item.qty} × ${AppHelpers.peso(item.price)}',
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
                              const Text(
                                'Discount',
                                style: TextStyle(fontSize: 11, color: kGrey),
                              ),
                              const Spacer(),
                              SizedBox(
                                width: 92,
                                child: TextField(
                                  controller: discountCtrl,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 12),
                                  textAlign: TextAlign.right,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText: '0.00',
                                    prefixText: '\u20B1 ',
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
                                    final maxDiscount = item.price * item.qty;
                                    final d = (double.tryParse(v) ?? 0.0)
                                        .clamp(0, maxDiscount)
                                        .toDouble();
                                    onItemDiscount(i, d);
                                    setS(() {});
                                  },
                                  onEditingComplete: () {
                                    FocusScope.of(ctx).nextFocus();
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Subtotal'),
                                  Text(AppHelpers.peso(subtotal + discTotal)),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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

                      _customerSelector(
                        controller: customerCtrl,
                        focusNode: customerFocus,
                        customers: customers,
                        hint: 'Customer name (optional)',
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
          ),
        );
      },
    ),
  );
  sheet.whenComplete(() {
    for (final ctrl in discountCtrls.values) {
      ctrl.dispose();
    }
    customerFocus.dispose();
  });
}

Widget _cartThumb(CartItem item) {
  final color =
      kCategoryColors[item.colorIndex.clamp(0, kCategoryColors.length - 1)];
  if (item.imageUrl.isNotEmpty) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        item.imageUrl,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _cartIcon(item, color),
      ),
    );
  }
  return _cartIcon(item, color);
}

Widget _cartIcon(CartItem item, Color color) {
  return Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(AppIcons.get(item.iconIndex), color: color, size: 22),
  );
}

// ══════════════════════════════════════════════════════════════
Widget _customerSelector({
  required TextEditingController controller,
  required FocusNode focusNode,
  required List<CustomerModel> customers,
  required String hint,
  TextEditingController? phoneController,
  TextEditingController? addressController,
}) {
  void fill(CustomerModel customer) {
    controller.text = customer.name;
    phoneController?.text = customer.phone;
    addressController?.text = customer.address;
  }

  return LayoutBuilder(
    builder: (context, constraints) => RawAutocomplete<CustomerModel>(
      textEditingController: controller,
      focusNode: focusNode,
      displayStringForOption: (customer) => customer.name,
      optionsBuilder: (value) {
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty) return customers.take(8);
        return customers.where(
          (customer) =>
              customer.name.toLowerCase().contains(query) ||
              customer.phone.toLowerCase().contains(query),
        );
      },
      onSelected: fill,
      fieldViewBuilder:
          (context, textController, focusNode, onFieldSubmitted) => TextField(
            controller: textController,
            focusNode: focusNode,
            decoration: AppInput.field(hint, icon: Icons.person_outline)
                .copyWith(
                  suffixIcon: customers.isEmpty
                      ? null
                      : const Icon(Icons.expand_more, size: 18),
                ),
            onChanged: (value) {
              final match = customers.where(
                (customer) =>
                    customer.name.toLowerCase() == value.trim().toLowerCase(),
              );
              if (match.isNotEmpty) fill(match.first);
            },
          ),
      optionsViewBuilder: (context, onSelected, options) {
        final list = options.toList();
        if (list.isEmpty) return const SizedBox.shrink();
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth,
                maxHeight: 220,
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final customer = list[i];
                  return ListTile(
                    dense: true,
                    title: Text(customer.name, overflow: TextOverflow.ellipsis),
                    subtitle: customer.phone.isEmpty
                        ? null
                        : Text(customer.phone, overflow: TextOverflow.ellipsis),
                    onTap: () => onSelected(customer),
                  );
                },
              ),
            ),
          ),
        );
      },
    ),
  );
}

// 3. PAYMENT SHEET
// ══════════════════════════════════════════════════════════════
