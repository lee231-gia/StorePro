part of 'reports_page.dart';

extension _ReportsProfit on _ReportsPageState {
  Widget _buildProfitTab() {
    final cs = Theme.of(context).colorScheme;

    final items = <Map<String, dynamic>>[];
    for (final p in _products) {
      for (final v in p.variants) {
        if (v.costPrice <= 0 && v.price <= 0) continue;
        final margin = v.price > 0
            ? ((v.price - v.costPrice) / v.price) * 100
            : 0.0;
        final markup = v.costPrice > 0
            ? ((v.price - v.costPrice) / v.costPrice) * 100
            : 0.0;
        items.add({
          'product': p,
          'variant': v,
          'productName': p.name,
          'variantName': v.name,
          'sku': v.sku,
          'costPrice': v.costPrice,
          'sellPrice': v.price,
          'profit': v.price - v.costPrice,
          'margin': margin,
          'markup': markup,
        });
      }
    }

    items.sort(
      (a, b) => (b['margin'] as double).compareTo(a['margin'] as double),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          appCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.functions, color: cs.primary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Profit Margin Formula',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 12),
                _formulaRow('Profit per Unit', 'Selling Price \u2212 Cost Price'),
                _formulaRow('Margin %', '(Profit \u00f7 Selling Price) \u00d7 100'),
                _formulaRow('Markup %', '(Profit \u00f7 Cost Price) \u00d7 100'),
                const SizedBox(height: 4),
                Text(
                  'Margin tells you what % of the '
                  'selling price is profit.\n'
                  'Markup tells you how much above '
                  'cost you are selling.',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11, height: 1.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Text(
            '${items.length} product variant'
            '${items.length != 1 ? 's' : ''}',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 8),

          if (items.isEmpty)
            Text(
              'Add cost prices to see margins.',
              style: TextStyle(color: cs.onSurfaceVariant),
            )
          else
            ...items.map((item) => _profitRow(item)),
        ],
      ),
    );
  }

  Widget _profitRow(Map<String, dynamic> item) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final success = isDark ? PaletteDark.success : PaletteLight.success;
    final warning = isDark ? PaletteDark.warning : PaletteLight.warning;
    final error = isDark ? PaletteDark.error : PaletteLight.error;
    final margin = item['margin'] as double;
    final color = margin >= 30
        ? success
        : margin >= 15
        ? warning
        : error;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProductImage(
                item: ProductDisplayItem(
                  product: item['product'] as ProductModel,
                  variant: item['variant'] as VariantModel,
                ),
                size: 44,
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['productName'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      item['variantName'],
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                    ),
                    if ((item['sku'] as String).isNotEmpty)
                      Text(
                        item['sku'],
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${margin.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              Expanded(
                child: _priceCell(
                  'Cost',
                  AppHelpers.peso(item['costPrice']),
                  cs.onSurfaceVariant,
                ),
              ),
              Expanded(
                child: _priceCell(
                  'Price',
                  AppHelpers.peso(item['sellPrice']),
                  cs.onSurface,
                ),
              ),
              Expanded(
                child: _priceCell(
                  'Profit/unit',
                  AppHelpers.peso(item['profit']),
                  color,
                ),
              ),
              Expanded(
                child: _priceCell(
                  'Markup',
                  '${(item['markup'] as double).toStringAsFixed(1)}%',
                  warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceCell(String label, String value, Color color) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant)),
      ],
    );
  }

  Widget _statCard2(String label, String value, Color color) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
            Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _formulaRow(String label, String formula, {bool highlight = false}) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              formula,
              style: TextStyle(
                fontSize: 12,
                color: highlight ? cs.primary : cs.onSurface,
                fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
