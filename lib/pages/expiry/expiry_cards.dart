part of 'expiry_page.dart';

extension _ExpiryCards on _ExpiryPageState {
  Widget _listCard(Map<String, dynamic> entry) {
    final product = entry['product'] as ProductModel;
    final variant = entry['variant'] as VariantModel;
    final expiry = entry['expiry'] as String;
    final tier = entry['tier'] as String;
    final days = entry['days'] as int;
    final indicators = entry['indicators'] as List<LifeIndicator>;
    final tierColor = _ExpiryPageState._tierColor(tier);

    return ProductCard(
      product: product,
      variant: variant,
      onTap: () => _openProduct(product.id),
      extraBadges: [
        _tierBadge(tier, days, tierColor),
        if (indicators.where(_hasDate).isNotEmpty)
          ProductBadge(
            label: '${indicators.where(_hasDate).length} dates',
            color: kGrey,
          ),
      ],
      trailing: _expiryTrailing(expiry, tier, tierColor),
    );
  }

  Widget _compactRow(Map<String, dynamic> entry) {
    final product = entry['product'] as ProductModel;
    final variant = entry['variant'] as VariantModel;
    final expiry = entry['expiry'] as String;
    final tier = entry['tier'] as String;
    final days = entry['days'] as int;
    final tierColor = _ExpiryPageState._tierColor(tier);

    return ProductCard(
      product: product,
      variant: variant,
      compact: true,
      onTap: () => _openProduct(product.id),
      extraBadges: [_tierBadge(tier, days, tierColor)],
      trailing: Text(
        expiry.isNotEmpty ? AppHelpers.formatDate(expiry) : '-',
        style: TextStyle(
          color: tierColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _gridCard(Map<String, dynamic> entry) {
    final product = entry['product'] as ProductModel;
    final variant = entry['variant'] as VariantModel;
    final expiry = entry['expiry'] as String;
    final tier = entry['tier'] as String;
    final days = entry['days'] as int;
    final tierColor = _ExpiryPageState._tierColor(tier);

    return ProductGridCard(
      product: product,
      variant: variant,
      onTap: () => _openProduct(product.id),
      badges: [_tierBadge(tier, days, tierColor)],
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            expiry.isNotEmpty ? AppHelpers.formatDate(expiry) : '-',
            style: TextStyle(
              color: tierColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${variant.totalStock} pcs \u2022 ${_ExpiryPageState._tierLabel(tier)}',
            style: const TextStyle(color: kGrey, fontSize: 10),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _detailCard(Map<String, dynamic> entry) {
    final product = entry['product'] as ProductModel;
    final variant = entry['variant'] as VariantModel;
    final tier = entry['tier'] as String;
    final days = entry['days'] as int;
    final indicators = entry['indicators'] as List<LifeIndicator>;
    final tierColor = _ExpiryPageState._tierColor(tier);

    return appCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProductImage(
                item: ProductDisplayItem(product: product, variant: variant),
                size: 46,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${product.name} - ${variant.name}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: kDark,
                      ),
                    ),
                    Text(
                      product.categoryName,
                      style: const TextStyle(color: kGrey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              _tierBadge(tier, days, tierColor),
            ],
          ),
          const Divider(height: 14),
          infoRow('Category', product.categoryName),
          infoRow(
            'Stock',
            '${variant.totalStock} pcs',
            icon: Icons.inventory_outlined,
          ),
          if (variant.sku.isNotEmpty)
            infoRow('SKU', variant.sku, icon: Icons.qr_code),
          infoRow(
            'Days Remaining',
            tier == 'expired'
                ? 'Expired'
                : tier == 'no_date'
                ? '-'
                : '$days days',
            icon: Icons.timer_outlined,
          ),
          if (indicators.where(_hasDate).isNotEmpty) ...[
            const Divider(height: 12),
            const Text(
              'Product Life Indicators',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: kGrey,
              ),
            ),
            const SizedBox(height: 4),
            ...indicators.where(_hasDate).map(_indicatorRow),
          ],
        ],
      ),
    );
  }

  void _openProduct(String productId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(productId: productId),
      ),
    ).then((_) => _load());
  }

  ProductBadge _tierBadge(String tier, int days, Color color) {
    return ProductBadge(label: _shortTierLabel(tier, days), color: color);
  }

  Widget _expiryTrailing(String expiry, String tier, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          expiry.isNotEmpty ? AppHelpers.formatDate(expiry) : '-',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          _ExpiryPageState._tierLabel(tier),
          style: TextStyle(color: color, fontSize: 10),
        ),
      ],
    );
  }

  Widget _indicatorRow(LifeIndicator indicator) {
    final color = indicator.affectsExpiry
        ? AppHelpers.statusColor(AppHelpers.expiryStatus(indicator.date))
        : kGrey;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(Icons.event_outlined, size: 12, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              indicator.type,
              style: const TextStyle(color: kGrey, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            AppHelpers.formatDate(indicator.date),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  bool _hasDate(LifeIndicator indicator) {
    return indicator.type != 'N/A' && indicator.date.isNotEmpty;
  }

  String _shortTierLabel(String tier, int days) {
    if (tier == 'expired') return 'EXPIRED';
    if (tier == 'no_date') return 'NO DATE';
    return '${days}d';
  }
}
