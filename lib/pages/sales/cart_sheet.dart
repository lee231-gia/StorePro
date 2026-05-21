part of 'sales_sheets.dart';

Future<bool> showCartSheet({
  required BuildContext context,
  required List<CartItem> cart,
  required TextEditingController customerCtrl,
  required TextEditingController notesCtrl,
  List<CustomerModel> customers = const [],
  required void Function(int, int) onChangeQty,
  required void Function(int) onRemove,
  required void Function(int, double) onItemDiscount,
}) async {
  final discountCtrls = <String, TextEditingController>{};
  final customerFocus = FocusNode();
  final proceed = await showModalBottomSheet<bool>(
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
                  padding: EdgeInsets.zero,
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
                      margin: EdgeInsets.zero,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      decoration: BoxDecoration(
                        color: kCard,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade100),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _cartThumb(item, size: 78),
                              const SizedBox(width: 12),
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
                                      [
                                        if (item.conditionName.isNotEmpty)
                                          item.conditionName,
                                        '${item.qty} x ${AppHelpers.peso(item.price)}',
                                      ].join('  '),
                                      style: const TextStyle(
                                        color: kGrey,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      AppHelpers.peso(item.subtotal),
                                      style: const TextStyle(
                                        color: kRed,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 78,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    SizedBox(
                                      width: 28,
                                      height: 24,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        tooltip: 'Remove',
                                        icon: const Icon(
                                          Icons.close,
                                          color: kGrey,
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          onRemove(i);
                                          setS(() {});
                                          if (cart.isEmpty) {
                                            FocusManager.instance.primaryFocus
                                                ?.unfocus();
                                            Navigator.pop(ctx, false);
                                          }
                                        },
                                      ),
                                    ),
                                    const Spacer(),
                                    _cartQtyStepper(
                                      qty: item.qty,
                                      onDecrease: () {
                                        onChangeQty(i, -1);
                                        setS(() {});
                                        if (cart.isEmpty) {
                                          FocusManager.instance.primaryFocus
                                              ?.unfocus();
                                          Navigator.pop(ctx, false);
                                        }
                                      },
                                      onIncrease: () {
                                        onChangeQty(i, 1);
                                        setS(() {});
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.only(
                              left: 2,
                              top: 2,
                              bottom: 2,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.confirmation_num_outlined,
                                  color: kRed,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Discount',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: kDark,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                SizedBox(
                                  width: 104,
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
                                      fillColor: kRedLight,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 8,
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
                                const Icon(
                                  Icons.chevron_right,
                                  color: kGrey,
                                  size: 18,
                                ),
                              ],
                            ),
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
                          onPressed: () async {
                            FocusManager.instance.primaryFocus?.unfocus();
                            await Future<void>.delayed(
                              const Duration(milliseconds: 100),
                            );
                            if (ctx.mounted) Navigator.pop(ctx, true);
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
  _disposeCheckoutInputs(
    controllers: discountCtrls.values.toList(),
    focusNodes: [customerFocus],
  );
  if (proceed == true) await _settleCheckoutOverlays();
  return proceed == true;
}

Future<void> _settleCheckoutOverlays() =>
    Future<void>.delayed(const Duration(milliseconds: 180));

void _disposeCheckoutInputs({
  List<TextEditingController> controllers = const [],
  List<FocusNode> focusNodes = const [],
}) {
  Future<void>.delayed(const Duration(milliseconds: 700), () {
    for (final focusNode in focusNodes) {
      focusNode.dispose();
    }
    for (final controller in controllers) {
      controller.dispose();
    }
  });
}

Widget _cartQtyStepper({
  required int qty,
  required VoidCallback onDecrease,
  required VoidCallback onIncrease,
}) {
  return Container(
    height: 36,
    decoration: BoxDecoration(
      color: kInputFill,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 34,
          height: 36,
          child: IconButton(
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove, color: kGrey, size: 18),
            onPressed: onDecrease,
          ),
        ),
        Container(width: 1, height: 18, color: Colors.white),
        SizedBox(
          width: 34,
          child: Text(
            '$qty',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
        Container(width: 1, height: 18, color: Colors.white),
        SizedBox(
          width: 34,
          height: 36,
          child: IconButton(
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add, color: kDark, size: 19),
            onPressed: onIncrease,
          ),
        ),
      ],
    ),
  );
}

Widget _cartThumb(CartItem item, {double size = 48}) {
  final color =
      kCategoryColors[item.colorIndex.clamp(0, kCategoryColors.length - 1)];
  if (item.imageUrl.isNotEmpty) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: ProductImage.optimizedUrl(item.imageUrl, 180),
        width: size,
        height: size,
        fit: BoxFit.cover,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        memCacheWidth: 180,
        memCacheHeight: 180,
        placeholder: (_, _) => _cartIcon(item, color, size),
        errorWidget: (_, _, _) => _cartIcon(item, color, size),
      ),
    );
  }
  return _cartIcon(item, color, size);
}

Widget _cartIcon(CartItem item, Color color, double size) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(AppIcons.get(item.iconIndex), color: color, size: size * 0.46),
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

  void fillExact(String value) {
    final name = value.trim().toLowerCase();
    if (name.isEmpty) return;
    final matches = customers.where(
      (customer) => customer.name.trim().toLowerCase() == name,
    );
    if (matches.isNotEmpty) fill(matches.first);
  }

  return TextField(
    controller: controller,
    focusNode: focusNode,
    textInputAction: TextInputAction.next,
    decoration: AppInput.field(hint, icon: Icons.person_outline),
    onChanged: fillExact,
    onEditingComplete: () {
      fillExact(controller.text);
      focusNode.unfocus();
    },
  );
}

// 3. PAYMENT SHEET
// ══════════════════════════════════════════════════════════════
