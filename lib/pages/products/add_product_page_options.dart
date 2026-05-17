part of 'add_product_page.dart';

extension _AddProductPageOptions on _AddProductPageState {
  String? _optionValueOrNull(List<ProductOptionModel> options, String value) {
    if (options.any((option) => option.value == value)) return value;
    return options.isEmpty ? null : options.first.value;
  }

  int _defaultPcs(String unit) {
    final match = _uomOptions.where((option) => option.value == unit);
    return match.isEmpty ? AppIcons.defaultPcs(unit) : match.first.pcsPerUnit;
  }

  void _showQuickCategoryDialog() {
    final nameCtrl = TextEditingController();
    int selIcon = _iconIndex;
    int selColor = _colorIndex;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 18,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Add Category',
            style: TextStyle(fontWeight: FontWeight.bold, color: kRed),
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.62,
              maxWidth: 420,
            ),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: AppInput.dialog('Category name'),
                ),
                const SizedBox(height: 12),
                fieldLabel('Icon'),
                SizedBox(
                  height: 150,
                  width: double.maxFinite,
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                        ),
                    itemCount: AppIcons.icons.length,
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () => setD(() => selIcon = i),
                      child: Container(
                        decoration: BoxDecoration(
                          color: selIcon == i ? kRed : kInputFill,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          AppIcons.icons[i],
                          color: selIcon == i ? Colors.white : kGrey,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                fieldLabel('Color'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(kCategoryColors.length, (i) {
                    return GestureDetector(
                      onTap: () => setD(() => selColor = i),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: kCategoryColors[i],
                          shape: BoxShape.circle,
                          border: selColor == i
                              ? Border.all(color: kDark, width: 2)
                              : null,
                        ),
                        child: selColor == i
                            ? const Icon(
                                Icons.check,
                                size: 15,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    );
                  }),
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
                backgroundColor: kRed,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final cat = await CategoryRepository.save(
                  CategoryModel(
                    id: '',
                    storeId: Session.storeId,
                    name: nameCtrl.text.trim(),
                    iconIndex: selIcon,
                    colorIndex: selColor,
                    updatedAt: AppHelpers.nowStr(),
                  ),
                );
                if (!mounted) return;
                _update(() {
                  _categories = [..._categories, cat];
                  _catId = cat.id;
                  _catName = cat.name;
                  _colorIndex = cat.colorIndex;
                });
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionManager({required String type, required String title}) {
    final valueCtrl = TextEditingController();
    final pcsCtrl = TextEditingController(text: '1');
    var options = List<ProductOptionModel>.from(
      type == ProductOptionRepository.uom ? _uomOptions : _packagingOptions,
    );
    ProductOptionModel? editing;

    Future<void> refresh(StateSetter setD) async {
      final fresh = await ProductOptionRepository.getByType(type);
      setD(() => options = fresh);
      _update(() {
        if (type == ProductOptionRepository.uom) {
          _uomOptions = fresh;
        } else {
          _packagingOptions = fresh;
        }
      });
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Manage $title',
            style: const TextStyle(fontWeight: FontWeight.bold, color: kRed),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: valueCtrl,
                          decoration: AppInput.dialog('$title name'),
                        ),
                      ),
                      if (type == ProductOptionRepository.uom) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: pcsCtrl,
                            keyboardType: TextInputType.number,
                            decoration: AppInput.dialog('Pcs'),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      IconButton.filled(
                        style: IconButton.styleFrom(backgroundColor: kRed),
                        onPressed: () async {
                          if (valueCtrl.text.trim().isEmpty) return;
                          await ProductOptionRepository.save(
                            ProductOptionModel(
                              id: editing?.id ?? '',
                              storeId: Session.storeId,
                              type: type,
                              value: valueCtrl.text.trim(),
                              pcsPerUnit: int.tryParse(pcsCtrl.text) ?? 1,
                              updatedAt: AppHelpers.nowStr(),
                            ),
                          );
                          valueCtrl.clear();
                          pcsCtrl.text = '1';
                          editing = null;
                          await refresh(setD);
                        },
                        icon: Icon(
                          editing == null ? Icons.add : Icons.check,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...options.map(
                    (option) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(option.value),
                      subtitle: type == ProductOptionRepository.uom
                          ? Text('${option.pcsPerUnit} pcs/unit')
                          : null,
                      trailing: option.id.startsWith('default_')
                          ? null
                          : Wrap(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    setD(() {
                                      editing = option;
                                      valueCtrl.text = option.value;
                                      pcsCtrl.text = '${option.pcsPerUnit}';
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: kRed,
                                    size: 18,
                                  ),
                                  onPressed: () async {
                                    await ProductOptionRepository.delete(
                                      option.id,
                                    );
                                    await refresh(setD);
                                  },
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
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
