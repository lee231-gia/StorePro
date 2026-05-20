import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/utils/app_helpers.dart';
import '../../models/product_model.dart';
import '../../repositories/product_repository.dart';
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
              backgroundColor: kRed,
              foregroundColor: Colors.white,
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
            if (_loading) const LinearProgressIndicator(color: kRed),
            const Expanded(child: Center(child: Text('Product not found.'))),
          ],
        ),
      );
    }

    final p = _product!;
    final catColor =
        kCategoryColors[p.colorIndex.clamp(0, kCategoryColors.length - 1)];
    final icon = AppIcons.get(p.iconIndex);
    final variantNames = p.variants.map((v) => v.name).join(', ');
    final imageCacheSize = (96 * MediaQuery.devicePixelRatioOf(context))
        .clamp(160, 480)
        .round();

    return Scaffold(
      backgroundColor: kBg,
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
                  // Image or icon
                  p.imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: _optimizedImageUrl(
                              p.imageUrl,
                              imageCacheSize,
                            ),
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            fadeInDuration: Duration.zero,
                            fadeOutDuration: Duration.zero,
                            memCacheWidth: imageCacheSize,
                            memCacheHeight: imageCacheSize,
                            maxWidthDiskCache: imageCacheSize,
                            maxHeightDiskCache: imageCacheSize,
                            errorWidget: (context, url, error) =>
                                _iconBox(catColor, icon, 72),
                          ),
                        )
                      : _iconBox(catColor, icon, 72),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: kDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p.categoryName,
                          style: TextStyle(color: catColor, fontSize: 13),
                        ),
                        Text(
                          '${p.totalStock} pcs total',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppHelpers.stockColor(p.totalStock),
                          ),
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
                  infoRow(
                    'Added On',
                    AppHelpers.formatDate(p.addedOn),
                    icon: Icons.calendar_today_outlined,
                  ),
                  const Divider(height: 1),
                  infoRow(
                    'Category',
                    p.categoryName,
                    icon: Icons.category_outlined,
                  ),
                  const Divider(height: 1),
                  infoRow(
                    'Variants',
                    '${p.variants.length}',
                    icon: Icons.list_alt_outlined,
                  ),
                  if (variantNames.isNotEmpty) ...[
                    const Divider(height: 1),
                    infoRow(
                      'Variant Names',
                      variantNames,
                      icon: Icons.account_tree_outlined,
                    ),
                  ],
                  const Divider(height: 1),
                  infoRow(
                    'Total Stock',
                    '${p.totalStock} pcs',
                    icon: Icons.inventory_outlined,
                  ),
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
                      const Icon(Icons.layers_outlined, color: kRed, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'Variants & Stock',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: kRed,
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
        color: kBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + stock
          Row(
            children: [
              Expanded(
                child: Text(
                  v.name,
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
          _detRow('Unit', '${v.unit} · ${v.pcsPerUnit} pcs/unit'),
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
                        color: kRedLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${c.name}  ${AppHelpers.peso(c.price)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: kRed,
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
                Icon(
                  Icons.event_outlined,
                  size: 13,
                  color: AppHelpers.statusColor(status),
                ),
                const SizedBox(width: 4),
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
            const Text(
              'Batches',
              style: TextStyle(
                fontSize: 11,
                color: kGrey,
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
                      style: const TextStyle(fontSize: 12, color: kDark),
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
                        style: const TextStyle(fontSize: 11, color: kGrey),
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

  Widget _detRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 1),
    child: Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(color: kGrey, fontSize: 11),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: kDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _iconBox(Color color, IconData icon, double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon, color: color, size: size * 0.46),
  );

  String _optimizedImageUrl(String url, int width) {
    if (!url.contains('/upload/') || url.contains('/upload/c_')) return url;
    final targetWidth = width.clamp(160, 900);
    return url.replaceFirst(
      '/upload/',
      '/upload/c_fill,g_auto,w_$targetWidth,q_auto,f_auto/',
    );
  }

  Color _lifeIndicatorColor(LifeIndicator indicator) {
    if (!indicator.affectsExpiry) return kGrey;
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
