part of 'expiry_page.dart';

extension _ExpiryCards on _ExpiryPageState {
  Widget _listCard(Map<String, dynamic> entry) {
    final product = entry['product'] as ProductModel;
    final variant = entry['variant'] as VariantModel;
    final expiry = entry['expiry'] as String;
    final tier = entry['tier'] as String;
    final days = entry['days'] as int;
    final indicators = entry['indicators'] as List<LifeIndicator>;
    final color =
        kCategoryColors[product.colorIndex.clamp(
          0,
          kCategoryColors.length - 1,
        )];
    final tColor = _ExpiryPageState._tierColor(tier);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: tColor, width: 4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                AppIcons.get(product.iconIndex),
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: kDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    variant.name,
                    style: const TextStyle(color: kGrey, fontSize: 11),
                  ),
                  Text(
                    product.categoryName,
                    style: TextStyle(color: color, fontSize: 10),
                  ),
                  Text(
                    '${variant.totalStock} pcs',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppHelpers.stockColor(variant.totalStock),
                    ),
                  ),
                  // Show all life indicators
                  if (indicators.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: indicators
                          .where((i) => i.type != 'N/A' && i.date.isNotEmpty)
                          .map(
                            (i) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${i.type.length > 8 ? i.type.substring(0, 8) : i.type}: '
                                '${AppHelpers.formatDate(i.date)}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: kGrey,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Tier badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: tColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tier == 'expired'
                        ? 'EXPIRED'
                        : tier == 'no_date'
                        ? 'NO DATE'
                        : '${days}d',
                    style: TextStyle(
                      color: tColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  expiry.isNotEmpty ? AppHelpers.formatDate(expiry) : '—',
                  style: const TextStyle(fontSize: 10, color: kGrey),
                ),
                Text(
                  _ExpiryPageState._tierLabel(tier),
                  style: TextStyle(fontSize: 9, color: tColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _compactRow(Map<String, dynamic> entry) {
    final product = entry['product'] as ProductModel;
    final variant = entry['variant'] as VariantModel;
    final expiry = entry['expiry'] as String;
    final tier = entry['tier'] as String;
    final days = entry['days'] as int;
    final tColor = _ExpiryPageState._tierColor(tier);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: tColor, width: 3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${product.name} — ${variant.name}',
              style: const TextStyle(fontSize: 12, color: kDark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            expiry.isNotEmpty ? AppHelpers.formatDate(expiry) : '—',
            style: const TextStyle(fontSize: 11, color: kGrey),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: tColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              tier == 'expired'
                  ? 'EXP'
                  : tier == 'no_date'
                  ? '—'
                  : '${days}d',
              style: TextStyle(
                color: tColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gridCard(Map<String, dynamic> entry) {
    final product = entry['product'] as ProductModel;
    final variant = entry['variant'] as VariantModel;
    final expiry = entry['expiry'] as String;
    final tier = entry['tier'] as String;
    final days = entry['days'] as int;
    final color =
        kCategoryColors[product.colorIndex.clamp(
          0,
          kCategoryColors.length - 1,
        )];
    final tColor = _ExpiryPageState._tierColor(tier);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tColor.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  AppIcons.get(product.iconIndex),
                  color: color,
                  size: 20,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: tColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tier == 'expired'
                      ? 'EXP'
                      : tier == 'no_date'
                      ? '—'
                      : '${days}d',
                  style: TextStyle(
                    color: tColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            product.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: kDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            variant.name,
            style: const TextStyle(color: kGrey, fontSize: 9),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            expiry.isNotEmpty ? AppHelpers.formatDate(expiry) : '—',
            style: TextStyle(
              fontSize: 9,
              color: tColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '${variant.totalStock} pcs  ·  '
            '${_ExpiryPageState._tierLabel(tier)}',
            style: const TextStyle(fontSize: 9, color: kGrey),
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
    final tColor = _ExpiryPageState._tierColor(tier);

    return appCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: tColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${product.name} — ${variant.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: kDark,
                  ),
                ),
              ),
              statusBadge(_ExpiryPageState._tierLabel(tier), tColor),
            ],
          ),
          const Divider(height: 12),

          // Info table
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
                ? 'EXPIRED'
                : tier == 'no_date'
                ? '—'
                : '$days days',
            icon: Icons.timer_outlined,
          ),

          if (indicators.isNotEmpty) ...[
            const Divider(height: 10),
            const Text(
              'Product Life Indicators',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: kGrey,
              ),
            ),
            const SizedBox(height: 4),
            ...indicators
                .where((i) => i.type != 'N/A' && i.date.isNotEmpty)
                .map(
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      children: [
                        Icon(
                          Icons.event_outlined,
                          size: 12,
                          color: AppHelpers.statusColor(
                            AppHelpers.expiryStatus(i.date),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          i.type,
                          style: const TextStyle(color: kGrey, fontSize: 11),
                        ),
                        const Spacer(),
                        Text(
                          AppHelpers.formatDate(i.date),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppHelpers.statusColor(
                              AppHelpers.expiryStatus(i.date),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}
