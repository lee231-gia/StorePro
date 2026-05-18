part of 'reports_page.dart';

extension _ReportsSales on _ReportsPageState {
  Widget _buildSalesTab() {
    final s = _summary;
    if (s == null) {
      return const Center(
        child: Text('No data.', style: TextStyle(color: kGrey)),
      );
    }
    final revenue = (s['totalRevenue'] as num?)?.toDouble() ?? 0.0;
    final profit = (s['totalProfit'] as num?)?.toDouble() ?? 0.0;
    final discount = (s['totalDiscount'] as num?)?.toDouble() ?? 0.0;
    final txCount = (s['totalTx'] as num?)?.toInt() ?? 0;
    final topProds = (s['topProducts'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final cogs = revenue - profit;
    final margin = revenue > 0 ? (profit / revenue) * 100 : 0.0;
    final avgSale = txCount > 0 ? revenue / txCount : 0.0;

    return RepaintBoundary(
      key: _reportKey,
      child: RefreshIndicator(
        color: kRed,
        onRefresh: _generate,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── REVENUE CARD ──────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kRed, kRedDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Revenue',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    Text(
                      AppHelpers.peso(revenue),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '$txCount transaction'
                          '${txCount != 1 ? 's' : ''}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Avg: ${AppHelpers.peso(avgSale)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── STAT CARDS ─────────────────────────
              Row(
                children: [
                  _statCard2('Net Profit', AppHelpers.peso(profit), kGreen),
                  const SizedBox(width: 10),
                  _statCard2('COGS', AppHelpers.peso(cogs), kOrange),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _statCard2(
                    'Profit Margin',
                    '${margin.toStringAsFixed(1)}%',
                    margin >= 20 ? kGreen : kOrange,
                  ),
                  const SizedBox(width: 10),
                  _statCard2('Total Discount', AppHelpers.peso(discount), kRed),
                ],
              ),

              const SizedBox(height: 16),

              // ── PROFIT FORMULA BOX ─────────────────
              appCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.functions, color: kRed, size: 16),
                        const SizedBox(width: 6),
                        const Text(
                          'How Profit is Calculated',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: kRed,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 12),
                    _formulaRow('Revenue', 'Units Sold × Selling Price'),
                    _formulaRow('COGS', 'Units Sold × Cost Price'),
                    _formulaRow('Gross Profit', 'Revenue − COGS'),
                    _formulaRow('Profit Margin', '(Profit ÷ Revenue) × 100'),
                    const Divider(height: 8),
                    _formulaRow(
                      'Today',
                      'Revenue: ${AppHelpers.peso(revenue)}  |  '
                          'COGS: ${AppHelpers.peso(cogs)}  |  '
                          'Profit: ${AppHelpers.peso(profit)}',
                      highlight: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── TOP PRODUCTS ───────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Top Products by Units Sold',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: kDark,
                    ),
                  ),
                  Text(
                    '${topProds.length} products',
                    style: const TextStyle(color: kGrey, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (topProds.isEmpty)
                const Text(
                  'No sales in this period.',
                  style: TextStyle(color: kGrey),
                )
              else
                ...topProds.asMap().entries.map((e) {
                  final rank = e.key + 1;
                  final name = e.value['name'] as String? ?? 'Unknown';
                  final qty = (e.value['qty'] as num?)?.toInt() ?? 0;

                  // Find product for profit data
                  final match = _products.where((p) => p.name == name).toList();
                  double profitPerUnit = 0;
                  if (match.isNotEmpty && match.first.variants.isNotEmpty) {
                    final v = match.first.variants.first;
                    profitPerUnit = v.price - v.costPrice;
                  }
                  final totalProfit = profitPerUnit * qty;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: kCard,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: rank <= 3 ? kRed : kRedLight,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$rank',
                              style: TextStyle(
                                color: rank <= 3 ? Colors.white : kRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: kDark,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (profitPerUnit > 0)
                                Text(
                                  'Est. profit: '
                                  '${AppHelpers.peso(totalProfit)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: kGrey,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: kRedLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$qty sold',
                            style: const TextStyle(
                              color: kRed,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // TAB 1 — INVENTORY
  // ══════════════════════════════════════════════════════════
}
