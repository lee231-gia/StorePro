part of 'add_product_page.dart';

extension _AddProductPageLayout on _AddProductPageState {
  Widget _buildStepBar() {
    final steps = ['Basic Info', 'Variants', 'Stocks'];
    return Container(
      color: kCard,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: steps.asMap().entries.map((e) {
          final i = e.key;
          final label = e.value;
          final active = _step == i;
          final done = _step > i;
          return Expanded(
            child: Row(
              children: [
                if (i > 0)
                  Container(
                    height: 2,
                    width: 16,
                    color: done || active ? kRed : Colors.grey.shade300,
                  ),
                Expanded(
                  child: GestureDetector(
                    onTap: done ? () => _update(() => _step = i) : null,
                    child: Column(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: active
                                ? kRed
                                : done
                                ? kGreen
                                : Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: done
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 14,
                                  )
                                : Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                      color: active ? Colors.white : kGrey,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 9,
                            color: active
                                ? kRed
                                : done
                                ? kGreen
                                : kGrey,
                            fontWeight: active
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── BOTTOM NAVIGATION BAR ─────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: kCard,
      child: Row(
        children: [
          if (_step > 0)
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: kRed,
                  side: const BorderSide(color: kRed),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => _update(() => _step--),
                child: const Text('Back'),
              ),
            ),
          if (_step > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _step < 2 ? kRed : kGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              onPressed: _saving
                  ? null
                  : () {
                      if (_step == 0) {
                        if (_nameCtrl.text.trim().isEmpty) {
                          showSnack(
                            context,
                            'Product name required.',
                            isError: true,
                          );
                          return;
                        }
                        _update(() => _step = 1);
                      } else if (_step == 1) {
                        if (_variants.isEmpty) {
                          showSnack(
                            context,
                            'Add at least one variant.',
                            isError: true,
                          );
                          return;
                        }
                        _update(() => _step = 2);
                      } else {
                        _save();
                      }
                    },
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _step == 0
                          ? 'Next: Variants'
                          : _step == 1
                          ? 'Next: Stocks'
                          : isEditing
                          ? 'Save Changes'
                          : 'Add Product',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // STEP 1 — BASIC INFO
  // ══════════════════════════════════════════════════════════
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          Center(
            child: GestureDetector(
              onTap: () => _showImagePicker(
                onPicked: (f) => _update(() => _imageFile = f),
              ),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: kInputFill,
                  borderRadius: BorderRadius.circular(16),
                  image: _imageFile != null
                      ? DecorationImage(
                          image: FileImage(_imageFile!),
                          fit: BoxFit.cover,
                        )
                      : _imageUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(_imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: (_imageFile == null && _imageUrl.isEmpty)
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.add_photo_alternate,
                            color: kGrey,
                            size: 36,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Add Photo',
                            style: TextStyle(color: kGrey, fontSize: 11),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
          ),

          const SizedBox(height: 20),

          fieldLabel('Product Name *'),
          TextField(
            controller: _nameCtrl,
            decoration: AppInput.field(
              'e.g. Coca-Cola',
              icon: Icons.inventory_2_outlined,
            ),
          ),

          const SizedBox(height: 12),

          fieldLabel('Description (optional)'),
          TextField(
            controller: _descCtrl,
            maxLines: 2,
            decoration: AppInput.field('Brief description'),
          ),

          const SizedBox(height: 12),

          fieldLabel('Category'),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _catId.isEmpty ? null : _catId,
                  decoration: AppInput.field(
                    'Select category',
                    icon: Icons.category_outlined,
                  ),
                  items: _categories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    final cat = _categories.firstWhere((c) => c.id == v);
                    _update(() {
                      _catId = cat.id;
                      _catName = cat.name;
                      _colorIndex = cat.colorIndex;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                style: IconButton.styleFrom(
                  backgroundColor: kRedLight,
                  foregroundColor: kRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                tooltip: 'Add category',
                onPressed: () =>
                    _AddProductPageOptions(this)._showQuickCategoryDialog(),
                icon: const Icon(Icons.add),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Has Variants toggle
          appCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Product Type',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: kDark,
                  ),
                ),
                const SizedBox(height: 12),
                _typeOption(
                  label: 'Has Variants',
                  subtitle: 'Multiple sizes, types, or options',
                  icon: Icons.layers_outlined,
                  selected: _hasVariants,
                  onTap: () => _update(() => _hasVariants = true),
                ),
                const SizedBox(height: 8),
                _typeOption(
                  label: 'Single Product',
                  subtitle: 'One size, one option',
                  icon: Icons.inventory_2_outlined,
                  selected: !_hasVariants,
                  onTap: () => _update(() => _hasVariants = false),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Icon picker
          appCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Product Icon',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: AppIcons.icons.length,
                  itemBuilder: (_, i) {
                    final active = _iconIndex == i;
                    return GestureDetector(
                      onTap: () => _update(() => _iconIndex = i),
                      child: Container(
                        decoration: BoxDecoration(
                          color: active ? kRed : kInputFill,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          AppIcons.icons[i],
                          color: active ? Colors.white : kGrey,
                          size: 22,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeOption({
    required String label,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? kRedLight : kBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? kRed : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? kRed : kGrey, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: selected ? kRed : kDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: kGrey, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle, color: kRed, size: 20),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // STEP 2 — VARIANTS / SINGLE PRODUCT
  // ══════════════════════════════════════════════════════════
}
