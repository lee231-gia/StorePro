part of 'reports_page.dart';

extension _ReportsProfit on _ReportsPageState {
  Widget _buildProfitTab() {
    // Build profit margin table from products
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

    // Sort by margin descending
    items.sort(
      (a, b) => (b['margin'] as double).compareTo(a['margin'] as double),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── FORMULA BOX ─────────────────────────
          appCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.functions, color: kRed, size: 16),
                    const SizedBox(width: 6),
                    const Text(
                      'Profit Margin Formula',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kRed,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 12),
                _formulaRow('Profit per Unit', 'Selling Price − Cost Price'),
                _formulaRow('Margin %', '(Profit ÷ Selling Price) × 100'),
                _formulaRow('Markup %', '(Profit ÷ Cost Price) × 100'),
                const SizedBox(height: 4),
                const Text(
                  'Margin tells you what % of the '
                  'selling price is profit.\n'
                  'Markup tells you how much above '
                  'cost you are selling.',
                  style: TextStyle(color: kGrey, fontSize: 11, height: 1.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Text(
            '${items.length} product variant'
            '${items.length != 1 ? 's' : ''}',
            style: const TextStyle(color: kGrey, fontSize: 12),
          ),
          const SizedBox(height: 8),

          if (items.isEmpty)
            const Text(
              'Add cost prices to see margins.',
              style: TextStyle(color: kGrey),
            )
          else
            ...items.map((item) => _profitRow(item)),
        ],
      ),
    );
  }

  Widget _profitRow(Map<String, dynamic> item) {
    final margin = item['margin'] as double;
    final color = margin >= 30
        ? kGreen
        : margin >= 15
        ? kOrange
        : kRed;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCard,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['productName'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: kDark,
                      ),
                    ),
                    Text(
                      item['variantName'],
                      style: const TextStyle(color: kGrey, fontSize: 11),
                    ),
                    if ((item['sku'] as String).isNotEmpty)
                      Text(
                        item['sku'],
                        style: const TextStyle(color: kGrey, fontSize: 10),
                      ),
                  ],
                ),
              ),
              // Margin badge
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

          // Price table (Kotatsu style)
          Row(
            children: [
              Expanded(
                child: _priceCell(
                  'Cost',
                  AppHelpers.peso(item['costPrice']),
                  kGrey,
                ),
              ),
              Expanded(
                child: _priceCell(
                  'Price',
                  AppHelpers.peso(item['sellPrice']),
                  kDark,
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
                  kOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceCell(String label, String value, Color color) => Column(
    children: [
      Text(
        value,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: color,
        ),
      ),
      Text(label, style: const TextStyle(fontSize: 9, color: kGrey)),
    ],
  );

  // ── SHARED HELPERS ────────────────────────────────────────
  Widget _statCard2(String label, String value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCard,
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
          Text(label, style: const TextStyle(color: kGrey, fontSize: 11)),
        ],
      ),
    ),
  );

  Widget _formulaRow(String label, String formula, {bool highlight = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(
                label,
                style: const TextStyle(color: kGrey, fontSize: 12),
              ),
            ),
            Expanded(
              child: Text(
                formula,
                style: TextStyle(
                  fontSize: 12,
                  color: highlight ? kRed : kDark,
                  fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      );

  // ── EXPORT ────────────────────────────────────────────────
}
