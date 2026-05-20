part of 'add_product_page.dart';

extension _AddProductPageDialogs on _AddProductPageState {
  void _showVariantDialog({VariantModel? existing, int? editIndex}) {
    final namCtrl = TextEditingController(text: existing?.name ?? '');
    final priceCtrl = TextEditingController(
      text: existing != null ? existing.price.toStringAsFixed(2) : '',
    );
    final costCtrl = TextEditingController(
      text: existing != null ? existing.costPrice.toStringAsFixed(2) : '',
    );
    final skuCtrl = TextEditingController(text: existing?.sku ?? '');
    final ppuCtrl = TextEditingController(
      text: (existing?.pcsPerUnit ?? 1).toString(),
    );
    String unit = existing?.unit ?? 'piece';
    String packaging = existing?.packaging ?? 'Solo';
    List<ConditionModel> conditions = List.from(existing?.conditions ?? []);
    String varImgUrl = existing?.imageUrl ?? '';
    File? varImgFile = existing == null
        ? null
        : _variantImageFiles[existing.id];
    bool showCond = conditions.isNotEmpty;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            existing != null ? 'Edit Variant' : 'Add Variant',
            style: const TextStyle(fontWeight: FontWeight.bold, color: kRed),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                appCard(
                  color: kBg,
                  margin: EdgeInsets.zero,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => _showImagePicker(
                        onPicked: (f) => setD(() => varImgFile = f),
                      ),
                      child: Container(
                        width: 116,
                        height: 116,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: kInputFill,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                          image: varImgFile != null
                              ? DecorationImage(
                                  image: FileImage(varImgFile!),
                                  fit: BoxFit.cover,
                                )
                              : varImgUrl.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(varImgUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: varImgFile == null && varImgUrl.isEmpty
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    color: kGrey,
                                    size: 28,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Variant image',
                                    style: TextStyle(
                                      color: kGrey,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                _variantFields(
                  namCtrl: namCtrl,
                  priceCtrl: priceCtrl,
                  costCtrl: costCtrl,
                  skuCtrl: skuCtrl,
                  ppuCtrl: ppuCtrl,
                  unit: unit,
                  packaging: packaging,
                  onUnitChange: (v) => setD(() => unit = v),
                  onPackChange: (v) => setD(() => packaging = v),
                  productName: _nameCtrl.text,
                  isDialog: true,
                ),

                const SizedBox(height: 10),

                // Conditions
                GestureDetector(
                  onTap: () => setD(() => showCond = !showCond),
                  child: Row(
                    children: [
                      Icon(
                        showCond ? Icons.expand_less : Icons.add_circle_outline,
                        color: kRed,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        showCond ? 'Hide Conditions' : '+ Add Conditions',
                        style: const TextStyle(
                          color: kRed,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                if (showCond) ...[
                  const SizedBox(height: 8),
                  _conditionsEditor(
                    conditions: conditions,
                    onChanged: (c) => setD(() => conditions = c),
                  ),
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
                backgroundColor: kRed,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (namCtrl.text.trim().isEmpty || priceCtrl.text.isEmpty) {
                  return;
                }
                final price = double.tryParse(priceCtrl.text) ?? 0;
                final cost = double.tryParse(costCtrl.text) ?? 0;
                final ppu = int.tryParse(ppuCtrl.text) ?? 1;
                final sku = skuCtrl.text.trim().isEmpty
                    ? _autoSku(_nameCtrl.text, namCtrl.text)
                    : skuCtrl.text.trim();

                final variant = VariantModel(
                  id:
                      existing?.id ??
                      'v${DateTime.now().millisecondsSinceEpoch}',
                  name: namCtrl.text.trim(),
                  sku: sku,
                  unit: unit,
                  packaging: packaging,
                  pcsPerUnit: ppu,
                  price: price,
                  originalPrice: price,
                  costPrice: cost,
                  conditions: conditions,
                  batches: existing?.batches ?? [],
                  imageUrl: varImgUrl,
                );

                _update(() {
                  if (varImgFile != null) {
                    _variantImageFiles[variant.id] = varImgFile!;
                  }
                  if (editIndex != null) {
                    _variants[editIndex] = variant;
                  } else {
                    _variants.add(variant);
                  }
                });
                Navigator.pop(ctx);
              },
              child: Text(existing != null ? 'Save' : 'Add Variant'),
            ),
          ],
        ),
      ),
    );
  }

  // ── SHARED FIELD BUILDER ──────────────────────────────────
  Widget _variantFields({
    required TextEditingController namCtrl,
    required TextEditingController priceCtrl,
    required TextEditingController costCtrl,
    required TextEditingController skuCtrl,
    required TextEditingController ppuCtrl,
    required String unit,
    required String packaging,
    required void Function(String) onUnitChange,
    required void Function(String) onPackChange,
    required String productName,
    bool isDialog = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_hasVariants) ...[
          fieldLabel('Variant Name (optional)'),
          TextField(
            controller: namCtrl,
            decoration: AppInput.field('e.g. 1L Bottle'),
          ),
          const SizedBox(height: 10),
        ] else ...[
          fieldLabel('Variant Name *'),
          TextField(
            controller: namCtrl,
            decoration: AppInput.field(
              'e.g. Liter Solo',
              icon: Icons.label_outline,
            ),
          ),
          const SizedBox(height: 10),
        ],

        // UOM + Packaging row
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  fieldLabel('UOM'),
                  DropdownButtonFormField<String>(
                    initialValue: _AddProductPageOptions(
                      this,
                    )._optionValueOrNull(_uomOptions, unit),
                    decoration: AppInput.field('Unit'),
                    items: _uomOptions
                        .map(
                          (u) => DropdownMenuItem(
                            value: u.value,
                            child: Text(
                              u.value,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        onUnitChange(v);
                        ppuCtrl.text = _AddProductPageOptions(
                          this,
                        )._defaultPcs(v).toString();
                      }
                    },
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () =>
                          _AddProductPageOptions(this)._showOptionManager(
                            type: ProductOptionRepository.uom,
                            title: 'UOM',
                          ),
                      icon: const Icon(Icons.tune, size: 14),
                      label: const Text('Edit UOM'),
                      style: TextButton.styleFrom(
                        foregroundColor: kRed,
                        textStyle: const TextStyle(fontSize: 11),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 28),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  fieldLabel('Packaging'),
                  DropdownButtonFormField<String>(
                    initialValue: _AddProductPageOptions(
                      this,
                    )._optionValueOrNull(_packagingOptions, packaging),
                    decoration: AppInput.field('Packaging'),
                    items: _packagingOptions
                        .map(
                          (p) => DropdownMenuItem(
                            value: p.value,
                            child: Text(
                              p.value,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) onPackChange(v);
                    },
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () =>
                          _AddProductPageOptions(this)._showOptionManager(
                            type: ProductOptionRepository.packaging,
                            title: 'Packaging',
                          ),
                      icon: const Icon(Icons.tune, size: 14),
                      label: const Text('Edit Packaging'),
                      style: TextButton.styleFrom(
                        foregroundColor: kRed,
                        textStyle: const TextStyle(fontSize: 11),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 28),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  fieldLabel('Pieces/Unit'),
                  TextField(
                    controller: ppuCtrl,
                    keyboardType: TextInputType.number,
                    decoration: AppInput.field('1'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  fieldLabel('Cost (₱)'),
                  TextField(
                    controller: costCtrl,
                    keyboardType: TextInputType.number,
                    decoration: AppInput.field('0.00'),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        fieldLabel('Selling Price (₱) *'),
        TextField(
          controller: priceCtrl,
          keyboardType: TextInputType.number,
          decoration: AppInput.field('0.00', icon: Icons.attach_money),
        ),

        const SizedBox(height: 10),

        // SKU row
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  fieldLabel('SKU (optional)'),
                  TextField(
                    controller: skuCtrl,
                    decoration: AppInput.field(
                      'Auto-generate or enter custom',
                      icon: Icons.qr_code,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: TextButton(
                onPressed: () {
                  skuCtrl.text = _autoSku(
                    productName,
                    namCtrl.text.isEmpty ? 'default' : namCtrl.text,
                  );
                },
                child: const Text(
                  'Auto',
                  style: TextStyle(color: kRed, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── CONDITIONS EDITOR ─────────────────────────────────────
  Widget _conditionsEditor({
    required List<ConditionModel> conditions,
    required void Function(List<ConditionModel>) onChanged,
  }) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    return StatefulBuilder(
      builder: (ctx, setC) => Column(
        children: [
          if (conditions.isNotEmpty)
            ...conditions.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.value.name,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Text(
                      '+₱${e.value.additionalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12, color: kGrey),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        conditions.removeAt(e.key);
                        onChanged(conditions);
                        setC(() {});
                      },
                      child: const Icon(Icons.close, size: 14, color: kGrey),
                    ),
                  ],
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: nameCtrl,
                  decoration: AppInput.dialog('Name (e.g. Cold)'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: AppInput.dialog('+Price'),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  if (nameCtrl.text.trim().isEmpty) {
                    return;
                  }
                  conditions.add(
                    ConditionModel(
                      name: nameCtrl.text.trim(),
                      additionalPrice: double.tryParse(priceCtrl.text) ?? 0,
                    ),
                  );
                  onChanged(conditions);
                  nameCtrl.clear();
                  priceCtrl.clear();
                  setC(() {});
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kRed,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── IMAGE PICKER HELPER ───────────────────────────────────
}
