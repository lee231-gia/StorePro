import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/app_helpers.dart';
import '../../models/product_model.dart';
import '../../repositories/product_repository.dart';
import '../../widgets/product_card.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/employee_picker.dart';
import 'add_product_page.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;
  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  ProductModel? _product;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    // Instant SQLite
    final p = await ProductRepository.getOne(
      widget.productId,
    ).timeout(const Duration(seconds: 3), onTimeout: () => null);

    if (mounted) {
      setState(() {
        _product = p;
        _loading = false;
      });
    }
  }

  // ── DELETE ────────────────────────────────────────────────
  Future<void> _delete() async {
    final ok = await pickEmployee(context);
    if (!ok || !mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Product',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text('Delete "${_product!.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ProductRepository.delete(widget.productId, _product!.name);
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (_product == null) {
      return Scaffold(
        appBar: buildAppBar(
          title: 'Product Details',
          context: context,
          showMenu: false,
          showBack: true,
        ),
        body: Column(
          children: [
            if (_loading) LinearProgressIndicator(color: cs.primary),
            const Expanded(child: Center(child: Text('Product not found.'))),
          ],
        ),
      );
    }

    final p = _product!;
    final variantNames = p.variants.map((v) => v.name).join(', ');
    final headerVariant = p.imageUrl.isEmpty ? _firstVariantImage(p) : null;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: buildAppBar(
        title: 'Product Details',
        context: context,
        showMenu: false,
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddProductPage(productId: widget.productId),
              ),
            ).then((_) => _load()),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _delete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── HEADER CARD ────────────────────────────────
            appCard(
              child: Row(
                children: [
                  ProductImage(
                    item: ProductDisplayItem(
                      product: p,
                      variant: headerVariant,
                    ),
                    size: 82,
                    padding: EdgeInsets.zero,
                    borderRadius: BorderRadius.circular(12),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p.description.trim().isEmpty
                              ? p.name
                              : p.description.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── DETAIL TABLE ───────────────────────────────
            // Kotatsu-style: label | value rows
            appCard(
              child: Column(
                children: [
                  infoRow('Added On', AppHelpers.formatDate(p.addedOn)),
                  const Divider(height: 1),
                  infoRow(
                    'Description',
                    p.description.trim().isEmpty
                        ? p.name
                        : p.description.trim(),
                  ),
                  const Divider(height: 1),
                  infoRow('Variants', '${p.variants.length}'),
                  if (variantNames.isNotEmpty) ...[
                    const Divider(height: 1),
                    infoRow('Variant Names', variantNames),
                  ],
                  const Divider(height: 1),
                  infoRow('Total Stock', '${p.totalStock} pcs'),
                ],
              ),
            ),

            // ── VARIANTS ───────────────────────────────────
            appCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Variants & Stock',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  ...p.variants.map(_buildVariantTile),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── EDIT BUTTON ────────────────────────────────
            PrimaryButton(
              label: 'Edit Product',
              icon: Icons.edit,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddProductPage(productId: widget.productId),
                ),
              ).then((_) => _load()),
            ),
          ],
        ),
      ),
    );
  }

  // ── VARIANT TILE ──────────────────────────────────────────
  Widget _buildVariantTile(VariantModel v) {
    final cs = Theme.of(context).colorScheme;
    final batches = v.batches;
    final totalStock = v.totalStock;
    final primaryDue = v.nearestExpiryIndicator;
    final status = primaryDue == null
        ? 'good'
        : AppHelpers.expiryStatus(primaryDue.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + stock
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (v.imageUrl.isNotEmpty) ...[
                _variantImageFor(v),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  _variantDisplayName(v),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                '$totalStock pcs',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppHelpers.stockColor(totalStock),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Detail rows (Kotatsu style)
          _detRow('Unit', '${v.unit} \u2022 ${v.pcsPerUnit} pcs/unit'),
          _detRow('Selling Price', AppHelpers.peso(v.price)),
          if (v.costPrice > 0)
            _detRow('Cost Price', AppHelpers.peso(v.costPrice)),
          if (v.hasDiscount)
            _detRow('Original', AppHelpers.peso(v.originalPrice)),

          // Conditions
          if (v.conditions.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              children: v.conditions
                  .map(
                    (c) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${c.name}  ${AppHelpers.peso(c.price)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],

          // Shelf-life badge. Only true due-date indicators can appear here.
          if (primaryDue != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${_lifeIndicatorStatus(primaryDue)}  '
                  '${AppHelpers.formatDate(primaryDue.date)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppHelpers.statusColor(status),
                  ),
                ),
              ],
            ),
          ],

          // Batch list
          if (batches.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 6),
            Text(
              'Batches',
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            ...batches.map((b) {
              final indicators = b.indicators.where((i) => i.hasDate);
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 3,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${b.qty} pcs',
                      style: TextStyle(fontSize: 12, color: cs.onSurface),
                    ),
                    ...indicators.map(
                      (i) => Text(
                        '${i.shortLabel}: ${AppHelpers.formatDate(i.date)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: _lifeIndicatorColor(i),
                        ),
                      ),
                    ),
                    if (b.costPrice > 0)
                      Text(
                        'Cost: ${AppHelpers.peso(b.costPrice)}',
                        style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                      ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _variantImageFor(VariantModel variant) {
    final product = _product;
    if (product == null) return const SizedBox(width: 46, height: 46);
    return ProductImage(
      item: ProductDisplayItem(product: product, variant: variant),
      size: 46,
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(8),
    );
  }

  String _variantDisplayName(VariantModel variant) {
    final productName = _product?.name.trim() ?? '';
    final variantName = variant.name.trim();
    if (productName.isEmpty) return variantName;
    if (variantName.isEmpty || variantName == productName) return productName;
    return '$productName - $variantName';
  }

  Widget _detRow(String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  VariantModel? _firstVariantImage(ProductModel product) {
    for (final variant in product.variants) {
      if (variant.imageUrl.isNotEmpty) return variant;
    }
    return null;
  }

  Color _lifeIndicatorColor(LifeIndicator indicator) {
    if (!indicator.affectsExpiry) return Theme.of(context).colorScheme.onSurfaceVariant;
    return AppHelpers.statusColor(AppHelpers.expiryStatus(indicator.date));
  }

  String _lifeIndicatorStatus(LifeIndicator indicator) {
    final status = AppHelpers.expiryStatus(indicator.date);
    if (status == 'expired') {
      switch (indicator.type) {
        case 'Best Before':
        case 'Best if Used By':
          return 'PAST ${indicator.shortLabel.toUpperCase()}';
        case 'Sell By':
          return 'PAST SELL BY';
        case 'Period After Opening':
          return 'PAST PAO';
        default:
          return 'EXPIRED';
      }
    }
    if (status == 'expiring') {
      return '${indicator.shortLabel}: '
          '${AppHelpers.daysLeft(indicator.date)}d left';
    }
    return indicator.shortLabel;
  }
}
