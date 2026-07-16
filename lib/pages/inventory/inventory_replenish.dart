part of 'inventory_page.dart';

extension _InventoryReplenish on _InventoryPageState {
  Widget _buildReplenish() {
    return Column(
      children: [
        _buildTopFilters(padding: const EdgeInsets.fromLTRB(16, 12, 16, 0)),
        Expanded(child: _buildReplenishProductView()),
      ],
    );
  }

  // ignore: unused_element
  Widget _replenishCard(ProductModel p) {
    final cs = Theme.of(context).colorScheme;
    final color =
        kCategoryColors[p.colorIndex.clamp(0, kCategoryColors.length - 1)];

    return appCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(AppIcons.get(p.iconIndex), color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      p.categoryName,
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                    ),
                  ],
                ),
              ),
              statusBadge(
                '${p.totalStock} pcs total',
                AppHelpers.stockColor(p.totalStock),
              ),
            ],
          ),

          const Divider(height: 14),

          // Variant rows
          ...p.variants.map(
            (v) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              v.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                            ),
                            // Cost + stock info
                            Row(
                              children: [
                                Text(
                                  '${v.totalStock} pcs',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppHelpers.stockColor(v.totalStock),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Cost: ${AppHelpers.peso(v.avgCostPrice)}',
                                  style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                ),
                                if (v.sku.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    v.sku,
                                    style: TextStyle(
                                      color: cs.onSurfaceVariant,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Add / Remove buttons
                      _actionBtn(
                        icon: Icons.add_circle_outline,
                        color: cs.brightness == Brightness.dark ? PaletteDark.success : PaletteLight.success,
                        label: 'Add',
                        onTap: () => _showAdjustDialog(
                          product: p,
                          variant: v,
                          isAdding: true,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _actionBtn(
                        icon: Icons.remove_circle_outline,
                        color: cs.error,
                        label: 'Remove',
                        onTap: () => _showAdjustDialog(
                          product: p,
                          variant: v,
                          isAdding: false,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── ADJUST STOCK DIALOG ───────────────────────────────────
  void _showAdjustDialog({
    required ProductModel product,
    required VariantModel variant,
    required bool isAdding,
  }) {
    final cs = Theme.of(context).colorScheme;
    final qtyCtrl = TextEditingController();
    final costCtrl = TextEditingController(
      text: variant.costPrice.toStringAsFixed(2),
    );
    String reason = isAdding ? 'replenishment' : 'adjustment';
    List<LifeIndicator> indicators = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            isAdding ? 'Add Stock' : 'Remove Stock',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isAdding ? (cs.brightness == Brightness.dark ? PaletteDark.success : PaletteLight.success) : cs.error,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product info
                appCard(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      infoRow('Product', product.name),
                      infoRow('Variant', variant.name),
                      infoRow('Current Stock', '${variant.totalStock} pcs'),
                      infoRow('Cost', AppHelpers.peso(variant.avgCostPrice)),
                    ],
                  ),
                ),

                // Reason (remove only)
                if (!isAdding) ...[
                  Row(
                    children: [
                      const Expanded(child: Text('Reason')),
                      TextButton.icon(
                        onPressed: () => _showReasonManager(
                          onChanged: () => setD(() {
                            if (!_removeReasons.contains(reason)) {
                              reason = _removeReasons.first;
                            }
                          }),
                        ),
                        icon: const Icon(Icons.tune, size: 14),
                        label: const Text('Edit Reasons'),
                        style: TextButton.styleFrom(
                          foregroundColor: cs.primary,
                          textStyle: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _removeReasons.contains(reason)
                        ? reason
                        : _removeReasons.first,
                    decoration: AppInput.dialog(context, 'Select reason'),
                    items: _removeReasons
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(
                              _reasonLabel(r),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setD(() => reason = v);
                    },
                  ),
                  const SizedBox(height: 10),
                ],

                fieldLabel('Quantity (pcs) *'),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: AppInput.dialog(context, 'Enter qty'),
                ),

                if (isAdding) ...[
                  const SizedBox(height: 10),
                  fieldLabel('Cost per piece (₱)'),
                  TextField(
                    controller: costCtrl,
                    keyboardType: TextInputType.number,
                    decoration: AppInput.dialog(context, '0.00'),
                  ),
                  const SizedBox(height: 12),

                  // Life indicators for new stock
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Product Life Indicators',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => setD(
                          () => indicators.add(
                            LifeIndicator(type: 'Expiry Date', date: ''),
                          ),
                        ),
                        icon: Icon(Icons.add, size: 14, color: cs.brightness == Brightness.dark ? PaletteDark.success : PaletteLight.success),
                        label: Text(
                          'Add',
                          style: TextStyle(color: cs.brightness == Brightness.dark ? PaletteDark.success : PaletteLight.success, fontSize: 12),
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
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: ind.type,
                              isExpanded: true,
                              decoration: AppInput.dialog(context, 'Type').copyWith(
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
                                if (v != null) {
                                  setD(() {
                                    indicators[i] = LifeIndicator(
                                      type: v,
                                      date: ind.date,
                                    );
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 6),
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
                                  color: cs.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  ind.date.isEmpty
                                      ? 'Pick date'
                                      : AppHelpers.formatDate(ind.date),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: ind.date.isEmpty ? cs.onSurfaceVariant : cs.onSurface,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => setD(() => indicators.removeAt(i)),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
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
                backgroundColor: isAdding ? (cs.brightness == Brightness.dark ? PaletteDark.success : PaletteLight.success) : cs.error,
                foregroundColor: cs.onPrimary,
              ),
              onPressed: () async {
                final qty = int.tryParse(qtyCtrl.text) ?? 0;
                if (qty <= 0) {
                  showSnack(ctx, 'Enter a valid quantity.', isError: true);
                  return;
                }
                if (!isAdding && qty > variant.totalStock) {
                  showSnack(
                    ctx,
                    'Cannot remove more than '
                    '${variant.totalStock} pcs.',
                    isError: true,
                  );
                  return;
                }

                final ok = await pickEmployee(context);
                if (!ok || !ctx.mounted) return;

                final cost =
                    double.tryParse(costCtrl.text) ?? variant.costPrice;

                if (isAdding) {
                  // Build new batch with indicators
                  final varIdx = product.variants.indexWhere(
                    (v) => v.id == variant.id,
                  );
                  if (varIdx < 0) return;

                  final newBatch = BatchModel(
                    id: 'b${DateTime.now().millisecondsSinceEpoch}',
                    qty: qty,
                    costPrice: cost,
                    indicators: indicators
                        .where((i) => i.type != 'N/A' && i.date.isNotEmpty)
                        .toList(),
                    addedOn: AppHelpers.todayStr(),
                  );

                  final updatedVariants = List<VariantModel>.from(
                    product.variants,
                  );
                  final oldBatches = List<BatchModel>.from(
                    updatedVariants[varIdx].batches,
                  )..add(newBatch);

                  updatedVariants[varIdx] = variant.copyWith(
                    batches: oldBatches,
                  );

                  final newProd = product.copyWith(variants: updatedVariants);
                  await ProductRepository.save(newProd);
                } else {
                  await ProductRepository.deductFifo(
                    product.id,
                    variant.id,
                    qty,
                  );
                }

                // Log the adjustment
                await InventoryRepository.log(
                  InventoryLogModel(
                    id: '',
                    storeId: Session.storeId,
                    productId: product.id,
                    productName: product.name,
                    variantId: variant.id,
                    variantName: variant.name,
                    type: isAdding ? 'add' : 'remove',
                    qty: isAdding ? qty : -qty,
                    costPrice: cost,
                    reason: isAdding ? 'replenishment' : reason,
                    date: AppHelpers.todayStr(),
                    updatedAt: AppHelpers.nowStr(),
                  ),
                );

                if (ctx.mounted) Navigator.pop(ctx);
                _load();
                AlertService.runAll();
              },
              child: Text(isAdding ? 'Add Stock' : 'Remove'),
            ),
          ],
        ),
      ),
    );
  }

  String _reasonLabel(String r) {
    switch (r) {
      case 'adjustment':
        return 'Adjustment';
      case 'personal_use':
        return 'Personal Consumption';
      case 'waste_damage':
        return 'Waste / Damage';
      case 'stock_loss':
        return 'Stock Loss / Missing';
      default:
        return r.replaceAll('_', ' ');
    }
  }

  void _showReasonManager({required VoidCallback onChanged}) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Remove Stock Reasons'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ctrl,
                        decoration: AppInput.dialog(context, 'New reason'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        final value = ctrl.text.trim();
                        if (value.isEmpty) return;
                        setD(() {
                          _removeReasons.add(
                            value.toLowerCase().replaceAll(' ', '_'),
                          );
                          ctrl.clear();
                        });
                        onChanged();
                      },
                      icon: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._removeReasons.asMap().entries.map(
                  (entry) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(_reasonLabel(entry.value)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () {
                            ctrl.text = _reasonLabel(entry.value);
                            setD(() => _removeReasons.removeAt(entry.key));
                            onChanged();
                          },
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: _removeReasons.length <= 1
                              ? null
                              : () {
                                  setD(
                                    () => _removeReasons.removeAt(entry.key),
                                  );
                                  onChanged();
                                },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    ).whenComplete(ctrl.dispose);
  }

  // ══════════════════════════════════════════════════════════
  // TAB 2 — LOGS
  // ══════════════════════════════════════════════════════════
}
