part of 'add_product_page.dart';

extension _AddProductPageVariants on _AddProductPageState {
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_hasVariants) ...[
            // Single product — show one variant form inline
            const Text(
              'Product Details',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: kDark,
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: kDark,
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kRed,
                    foregroundColor: Colors.white,
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
                    const Icon(Icons.layers_outlined, color: kGrey, size: 48),
                    const SizedBox(height: 8),
                    const Text(
                      'No variants yet.',
                      style: TextStyle(color: kGrey),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tap "Add Variant" to add sizes or types.',
                      style: TextStyle(color: kGrey, fontSize: 12),
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
                    color: kInputFill,
                    borderRadius: BorderRadius.circular(10),
                    image: variantImageFile != null
                        ? DecorationImage(
                            image: FileImage(variantImageFile!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: variantImageFile == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              color: kGrey,
                              size: 28,
                            ),
                            Text(
                              'Variant image (optional)',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: kGrey, fontSize: 11),
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
                    color: kRed,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '+ Add Conditions',
                    style: TextStyle(
                      color: kRed,
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
                  backgroundColor: kRed,
                  foregroundColor: Colors.white,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Stock Batches',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: kDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Add stock for each variant. '
            'Each batch tracks quantity and product life.',
            style: TextStyle(color: kGrey, fontSize: 12),
          ),
          const SizedBox(height: 16),

          ..._variants.map((v) => _stockSection(v)),
        ],
      ),
    );
  }
}
