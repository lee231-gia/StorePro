part of 'add_product_page.dart';

extension _AddProductPageVariants on _AddProductPageState {
  Widget _buildStep2() {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_hasVariants) ...[
            // Single product — show one variant form inline
            Text(
              'Product Details',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            if (_variants.isEmpty)
              _buildSingleVariantForm()
            else
              _variantCollapsibleCard(_variants.first, 0),
          ] else ...[
            // Multiple variants
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_variants.length} variant'
                  '${_variants.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: cs.onSurface,
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onPressed: _showVariantDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text(
                    'Add Variant',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_variants.isEmpty)
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Icon(Icons.layers_outlined, color: cs.onSurfaceVariant, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      'No variants yet.',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap "Add Variant" to add sizes or types.',
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ..._variants.asMap().entries.map(
                (e) => _variantCollapsibleCard(e.value, e.key),
              ),
          ],
        ],
      ),
    );
  }

  // Single product inline form
  Widget _buildSingleVariantForm() {
    final cs = Theme.of(context).colorScheme;
    final namCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final skuCtrl = TextEditingController();
    final ppuCtrl = TextEditingController(text: '1');
    String unit = 'piece';
    String packaging = 'Solo';
    List<ConditionModel> conditions = [];
    bool showCond = false;
    File? variantImageFile;

    return StatefulBuilder(
      builder: (ctx, setS) => appCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: () => _showImagePicker(
                  onPicked: (f) => setS(() => variantImageFile = f),
                ),
                onLongPress: () => _previewImage(file: variantImageFile),
                child: Container(
                  height: 104,
                  width: 104,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                    image: variantImageFile != null
                        ? DecorationImage(
                            image: FileImage(variantImageFile!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: variantImageFile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              color: cs.onSurfaceVariant,
                              size: 28,
                            ),
                            Text(
                              'Variant image (optional)',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
            ),
            _variantFields(
              namCtrl: namCtrl,
              priceCtrl: priceCtrl,
              costCtrl: costCtrl,
              skuCtrl: skuCtrl,
              ppuCtrl: ppuCtrl,
              unit: unit,
              packaging: packaging,
              onUnitChange: (v) => setS(() => unit = v),
              onPackChange: (v) => setS(() => packaging = v),
              productName: _nameCtrl.text,
            ),

            const SizedBox(height: 12),

            // Conditions toggle
            GestureDetector(
              onTap: () => setS(() => showCond = !showCond),
              child: Row(
                children: [
                  Icon(
                    showCond ? Icons.expand_less : Icons.add_circle_outline,
                    color: cs.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '+ Add Conditions',
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            if (showCond) ...[
              const SizedBox(height: 8),
              _conditionsEditor(
                conditions: conditions,
                onChanged: (c) => setS(() => conditions = c),
              ),
            ],

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  if (priceCtrl.text.isEmpty) {
                    showSnack(context, 'Price is required.', isError: true);
                    return;
                  }
                  final price = double.tryParse(priceCtrl.text) ?? 0;
                  final cost = double.tryParse(costCtrl.text) ?? 0;
                  final ppu = int.tryParse(ppuCtrl.text) ?? 1;
                  final sku = skuCtrl.text.trim().isEmpty
                      ? _autoSku(
                          _nameCtrl.text,
                          namCtrl.text.isEmpty ? 'default' : namCtrl.text,
                        )
                      : skuCtrl.text.trim();

                  final variantId = 'v${DateTime.now().millisecondsSinceEpoch}';
                  final variant = VariantModel(
                    id: variantId,
                    name: namCtrl.text.trim().isEmpty
                        ? _nameCtrl.text.trim()
                        : namCtrl.text.trim(),
                    sku: sku,
                    unit: unit,
                    packaging: packaging,
                    pcsPerUnit: ppu,
                    price: price,
                    originalPrice: price,
                    costPrice: cost,
                    conditions: conditions,
                  );

                  _update(() {
                    if (variantImageFile != null) {
                      _variantImageFiles[variantId] = variantImageFile!;
                    }
                    _variants = [variant];
                  });
                  showSnack(context, 'Product details saved!');
                },
                child: const Text('Save Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Collapsible variant card
  Widget _variantCollapsibleCard(VariantModel v, int index) {
    return _ExpandableVariantCard(
      variant: v,
      index: index,
      productName: _nameCtrl.text,
      onEdit: () => _showVariantDialog(existing: v, editIndex: index),
      onDelete: () {
        _update(() => _variants.removeAt(index));
      },
    );
  }

  // ══════════════════════════════════════════════════════════
  // STEP 3 — STOCKS
  // ══════════════════════════════════════════════════════════
  Widget _buildStep3() {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Stock Batches',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add stock for each variant. '
            'Each batch tracks quantity and product life.',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 16),

          ..._variants.map((v) => _stockSection(v)),
        ],
      ),
    );
  }
}
