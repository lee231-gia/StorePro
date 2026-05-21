part of 'add_product_page.dart';

extension _AddProductPageStock on _AddProductPageState {
  Widget _stockSection(VariantModel v) {
    final idx = _variants.indexWhere((x) => x.id == v.id);
    return appCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Variant header
          Row(
            children: [
              if (v.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: CachedNetworkImage(
                    imageUrl: ProductImage.optimizedUrl(v.imageUrl, 96),
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                    memCacheWidth: 96,
                    memCacheHeight: 96,
                    errorWidget: (_, _, _) => Container(
                      width: 32,
                      height: 32,
                      color: kRedLight,
                      child: const Icon(
                        Icons.inventory_2,
                        color: kRed,
                        size: 16,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: kRedLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.inventory_2, color: kRed, size: 16),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${v.unit} · ₱${v.price.toStringAsFixed(2)}',
                      style: const TextStyle(color: kGrey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              statusBadge(
                '${v.totalStock} pcs',
                AppHelpers.stockColor(v.totalStock),
              ),
            ],
          ),

          // Existing batches
          if (v.batches.isNotEmpty) ...[
            const Divider(height: 16),
            ...v.batches.map((b) => _batchRow(b, v, idx)),
          ],

          const SizedBox(height: 8),

          // Add stock button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: kGreen,
              side: const BorderSide(color: kGreen),
              minimumSize: const Size(double.infinity, 38),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => _showBatchDialog(idx),
            icon: const Icon(Icons.add, size: 14),
            label: const Text(
              'Add Stock Batch',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _batchRow(BatchModel b, VariantModel v, int varIdx) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: kBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${b.qty} pcs',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      if (b.batchNumber.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          'Batch: ${b.batchNumber}',
                          style: const TextStyle(color: kGrey, fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                  if (b.costPrice > 0)
                    Text(
                      'Cost: ₱${b.costPrice.toStringAsFixed(2)}',
                      style: const TextStyle(color: kGrey, fontSize: 11),
                    ),
                  // Show all life indicators
                  ...b.indicators
                      .where((i) => i.type != 'N/A' && i.date.isNotEmpty)
                      .map(
                        (i) => Row(
                          children: [
                            Icon(
                              Icons.event_outlined,
                              size: 11,
                              color: _lifeIndicatorColor(i),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${i.type}: '
                              '${AppHelpers.formatDate(i.date)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: _lifeIndicatorColor(i),
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _showBatchDialog(
                    varIdx,
                    existing: b,
                    batchIndex: _variants[varIdx].batches.indexOf(b),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: kGrey,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    final batches = List<BatchModel>.from(
                      _variants[varIdx].batches,
                    )..remove(b);
                    _update(() {
                      _variants[varIdx] = v.copyWith(batches: batches);
                    });
                  },
                  child: const Icon(Icons.close, size: 16, color: kGrey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── BATCH DIALOG ──────────────────────────────────────────
  void _showBatchDialog(
    int variantIndex, {
    BatchModel? existing,
    int? batchIndex,
  }) {
    final qtyCtrl = TextEditingController(
      text: existing == null ? '' : existing.qty.toString(),
    );
    final costCtrl = TextEditingController(
      text: existing == null ? '' : existing.costPrice.toStringAsFixed(2),
    );
    final batchCtrl = TextEditingController(text: existing?.batchNumber ?? '');
    List<LifeIndicator> indicators = List<LifeIndicator>.from(
      existing?.indicators ?? const [],
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            existing == null ? 'Add Stock Batch' : 'Edit Stock Batch',
            style: const TextStyle(fontWeight: FontWeight.bold, color: kGreen),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Batch number
                  fieldLabel('Batch Number (optional)'),
                  TextField(
                    controller: batchCtrl,
                    decoration: AppInput.dialog('e.g. BATCH-001'),
                  ),
                  const SizedBox(height: 10),

                  // Quantity
                  fieldLabel('Quantity (pcs) *'),
                  TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: AppInput.dialog('Enter quantity'),
                  ),
                  const SizedBox(height: 10),

                  // Cost
                  fieldLabel('Cost per piece (₱)'),
                  TextField(
                    controller: costCtrl,
                    keyboardType: TextInputType.number,
                    decoration: AppInput.dialog('0.00'),
                  ),
                  const SizedBox(height: 12),

                  // Life indicators
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Product Life Indicators',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => setD(
                          () => indicators.add(
                            LifeIndicator(type: 'Expiry Date', date: ''),
                          ),
                        ),
                        icon: const Icon(Icons.add, size: 14, color: kGreen),
                        label: const Text(
                          'Add',
                          style: TextStyle(color: kGreen, fontSize: 12),
                        ),
                      ),
                    ],
                  ),

                  ...indicators.asMap().entries.map((e) {
                    final i = e.key;
                    final ind = e.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          // Type dropdown
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: ind.type,
                              isExpanded: true,
                              decoration: AppInput.dialog('Type').copyWith(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                              ),
                              selectedItemBuilder: (_) => LifeIndicator.types
                                  .map(
                                    (t) => Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        t,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              items: LifeIndicator.types
                                  .map(
                                    (t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(
                                        t,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v == null) return;
                                setD(() {
                                  indicators[i] = LifeIndicator(
                                    type: v,
                                    date: ind.date,
                                  );
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Date picker
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final d = await showDatePicker(
                                  context: ctx,
                                  initialDate: DateTime.now().add(
                                    const Duration(days: 30),
                                  ),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2040),
                                );
                                if (d != null) {
                                  final mm = d.month.toString().padLeft(2, '0');
                                  final dd = d.day.toString().padLeft(2, '0');
                                  setD(() {
                                    indicators[i] = LifeIndicator(
                                      type: ind.type,
                                      date: '${d.year}-$mm-$dd',
                                    );
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: kInputFill,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  ind.date.isEmpty
                                      ? 'Pick date'
                                      : AppHelpers.formatDate(ind.date),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: ind.date.isEmpty ? kGrey : kDark,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => setD(() => indicators.removeAt(i)),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: kGrey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  if (indicators.isEmpty)
                    GestureDetector(
                      onTap: () => setD(
                        () => indicators.add(
                          LifeIndicator(type: 'Expiry Date', date: ''),
                        ),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_circle_outline,
                              color: kGrey,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Add life indicator '
                              '(expiry, MFG, etc.)',
                              style: TextStyle(color: kGrey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
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
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kGreen,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final qty = int.tryParse(qtyCtrl.text) ?? 0;
                if (qty <= 0) {
                  showSnack(ctx, 'Enter a valid quantity.', isError: true);
                  return;
                }
                final cost = double.tryParse(costCtrl.text) ?? 0;
                final batch = BatchModel(
                  id:
                      existing?.id ??
                      'b${DateTime.now().millisecondsSinceEpoch}',
                  batchNumber: batchCtrl.text.trim(),
                  qty: qty,
                  costPrice: cost,
                  indicators: indicators
                      .where((i) => i.type != 'N/A' && i.date.isNotEmpty)
                      .toList(),
                  addedOn: AppHelpers.todayStr(),
                );

                final v = _variants[variantIndex];
                final batches = List<BatchModel>.from(v.batches);
                if (existing != null && batchIndex != null && batchIndex >= 0) {
                  batches[batchIndex] = batch;
                } else {
                  batches.add(batch);
                }

                _update(() {
                  _variants[variantIndex] = v.copyWith(batches: batches);
                });
                Navigator.pop(ctx);
              },
              child: Text(existing == null ? 'Add Batch' : 'Save Batch'),
            ),
          ],
        ),
      ),
    );
  }

  Color _lifeIndicatorColor(LifeIndicator indicator) {
    if (!indicator.affectsExpiry) return kGrey;
    return AppHelpers.statusColor(AppHelpers.expiryStatus(indicator.date));
  }

  // ── VARIANT DIALOG (for has-variants mode) ────────────────
}
