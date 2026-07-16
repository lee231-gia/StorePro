part of 'add_product_page.dart';

extension _AddProductPageImagePicker on _AddProductPageState {
  void _showImagePicker({required void Function(File) onPicked}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.photo_camera_outlined, color: Theme.of(context).colorScheme.primary),
                title: const Text('Take Photo'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picked = await ImagePicker().pickImage(
                    source: ImageSource.camera,
                    imageQuality: 75,
                  );
                  if (picked != null) onPicked(File(picked.path));
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: Theme.of(context).colorScheme.primary),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picked = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 75,
                  );
                  if (picked != null) onPicked(File(picked.path));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpandableVariantCard extends StatefulWidget {
  final VariantModel variant;
  final int index;
  final String productName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExpandableVariantCard({
    required this.variant,
    required this.index,
    required this.productName,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_ExpandableVariantCard> createState() => _ExpandableVariantCardState();
}

class _ExpandableVariantCardState extends State<_ExpandableVariantCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final variant = widget.variant;
    final title = variant.name.isEmpty ? widget.productName : variant.name;

    return appCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: cs.primaryContainer,
                  child: Text(
                    '${widget.index + 1}',
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        '${variant.unit} • ${variant.totalStock} in stock',
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: widget.onEdit,
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: cs.primary, size: 20),
                  onPressed: widget.onDelete,
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: cs.onSurfaceVariant,
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 20),
            _row('SKU', variant.sku.isEmpty ? '-' : variant.sku),
            _row('Packaging', variant.packaging),
            _row('Pieces / Unit', '${variant.pcsPerUnit}'),
            _row('Price', AppHelpers.peso(variant.price)),
            _row('Cost', AppHelpers.peso(variant.costPrice)),
            _row('Batches', '${variant.batches.length}'),
            if (variant.conditions.isNotEmpty)
              _row(
                'Conditions',
                variant.conditions.map((c) => c.name).join(', '),
              ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
