part of 'reports_page.dart';

extension _ReportsSales on _ReportsPageState {
  Widget _buildSalesTab() {
    final s = _summary;
    if (s == null) {
      return const Center(
        child: Text('No data.', style: TextStyle(color: kGrey)),
      );
    }

    final grossRevenue = (s['grossRevenue'] as num?)?.toDouble() ?? 0.0;
    final revenue =
        (s['netRevenue'] as num?)?.toDouble() ??
        (s['totalRevenue'] as num?)?.toDouble() ??
        0.0;
    final profit = (s['totalProfit'] as num?)?.toDouble() ?? 0.0;
    final discount = (s['totalDiscount'] as num?)?.toDouble() ?? 0.0;
    final cogs = (s['cogs'] as num?)?.toDouble() ?? (revenue - profit);
    final txCount = (s['totalTx'] as num?)?.toInt() ?? 0;
    final cashCollected = (s['cashCollected'] as num?)?.toDouble() ?? 0.0;
    final utangSales = (s['utangTotal'] as num?)?.toDouble() ?? 0.0;
    final topProds = _topProductsFrom(s);
    final margin = revenue > 0 ? (profit / revenue) * 100 : 0.0;
    final avgSale = txCount > 0 ? revenue / txCount : 0.0;

    return RepaintBoundary(
      key: _reportKey,
      child: RefreshIndicator(
        color: kRed,
        onRefresh: _generate,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_rangeSummaries.isNotEmpty) ...[
              appCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Timeframe Summary',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: kDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${AppHelpers.formatDate(_fmt(_from))} to '
                      '${AppHelpers.formatDate(_fmt(_to))}',
                      style: const TextStyle(color: kGrey, fontSize: 11),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickCustom,
                            icon: const Icon(Icons.date_range, size: 16),
                            label: const Text('Customize'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _showExportOptions,
                            icon: const Icon(Icons.ios_share, size: 16),
                            label: const Text('Get Copy'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _timeframeHeaderRow(),
                    ...[
                      'total',
                      'hour',
                      'today',
                      'yesterday',
                      'week',
                      'month',
                      'year',
                    ].map((key) => _rangeSummaryRow(key, _rangeSummaries[key])),
                    _rangeSummaryRow('custom', s),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            _heroRevenueCard(revenue, txCount, avgSale),
            const SizedBox(height: 12),
            Row(
              children: [
                _statCard2(
                  'Gross Revenue',
                  AppHelpers.peso(grossRevenue),
                  kDark,
                ),
                const SizedBox(width: 10),
                _statCard2('Discounts', AppHelpers.peso(discount), kRed),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _statCard2('COGS', AppHelpers.peso(cogs), kOrange),
                const SizedBox(width: 10),
                _statCard2('Net Profit', AppHelpers.peso(profit), kGreen),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _statCard2(
                  'Net Profit Margin',
                  '${margin.toStringAsFixed(1)}%',
                  margin >= 20 ? kGreen : kOrange,
                ),
                const SizedBox(width: 10),
                _statCard2('Sales Count', '$txCount', kDark),
              ],
            ),
            const SizedBox(height: 12),
            _collectionSummary(cashCollected, utangSales),
            _calculationCard(),
            const SizedBox(height: 4),
            _topProductsSection(topProds),
          ],
        ),
      ),
    );
  }

  Widget _heroRevenueCard(double revenue, int txCount, double avgSale) {
    return Container(
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
            'Net Revenue',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              AppHelpers.peso(revenue),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              Text(
                '$txCount sale${txCount != 1 ? 's' : ''}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                'Avg: ${AppHelpers.peso(avgSale)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _collectionSummary(double cashCollected, double utangSales) {
    final openUtang = _utang.where((u) => u.balance > 0).toList()
      ..sort((a, b) => b.balance.compareTo(a.balance));
    final openBalance = openUtang.fold(0.0, (sum, u) => sum + u.balance);

    return appCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            Icons.account_balance_wallet_outlined,
            'Collection Summary',
          ),
          const Divider(height: 12),
          Row(
            children: [
              _miniMetric('Cash', AppHelpers.peso(cashCollected), kGreen),
              const SizedBox(width: 8),
              _miniMetric('Utang', AppHelpers.peso(utangSales), kOrange),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Open utang to be paid: ${AppHelpers.peso(openBalance)}',
            style: const TextStyle(
              color: kDark,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          if (openUtang.isEmpty)
            const Text(
              'No open utang balances.',
              style: TextStyle(color: kGrey, fontSize: 11),
            )
          else
            ...openUtang
                .take(5)
                .map(
                  (u) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            [
                              u.customerName,
                              if (u.customerPhone.isNotEmpty) u.customerPhone,
                              if (u.dueDate.isNotEmpty)
                                'Due ${AppHelpers.formatDate(u.dueDate)}',
                            ].join(' • '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: kGrey),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppHelpers.peso(u.balance),
                          style: const TextStyle(
                            color: kOrange,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _calculationCard() {
    return appCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.functions, 'How This Report Is Calculated'),
          const Divider(height: 12),
          _formulaRow('Gross Revenue', 'Sale subtotal before discounts'),
          _formulaRow('Discounts', 'All item and sale discounts'),
          _formulaRow('Net Revenue', 'Gross Revenue - Discounts'),
          _formulaRow('COGS', 'Units Sold x recorded Cost Price'),
          _formulaRow('Net Profit', 'Net Revenue - COGS'),
          _formulaRow('Profit Margin', '(Net Profit / Net Revenue) x 100'),
        ],
      ),
    );
  }

  Widget _topProductsSection(List<Map<String, dynamic>> topProds) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Top Products by Units Sold',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: kDark,
                ),
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
          const Text('No sales in this period.', style: TextStyle(color: kGrey))
        else
          ...topProds.asMap().entries.map((e) {
            final rank = e.key + 1;
            final item = e.value;
            final name = item['name'] as String? ?? 'Unknown';
            final variantName = item['variantName'] as String? ?? '';
            final qty = (item['qty'] as num?)?.toInt() ?? 0;
            final itemProfit = (item['profit'] as num?)?.toDouble() ?? 0.0;
            final product = _productForTop(item, name);
            final variant = _variantForTop(product, item, variantName);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
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
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ProductImage(
                        item: ProductDisplayItem(
                          product: product,
                          variant: variant,
                        ),
                        size: 44,
                        padding: EdgeInsets.zero,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      Positioned(
                        left: -5,
                        top: -5,
                        child: Container(
                          width: 21,
                          height: 21,
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
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 13,
                            color: kDark,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (variantName.isNotEmpty)
                          Text(
                            variantName,
                            style: const TextStyle(fontSize: 11, color: kGrey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        Text(
                          'Profit: ${AppHelpers.peso(itemProfit)}',
                          style: const TextStyle(fontSize: 11, color: kGrey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  statusBadge('$qty sold', kRed),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _rangeSummaryRow(String key, Map<String, dynamic>? summary) {
    final revenue =
        (summary?['netRevenue'] as num?)?.toDouble() ??
        (summary?['totalRevenue'] as num?)?.toDouble() ??
        0.0;
    final profit = (summary?['totalProfit'] as num?)?.toDouble() ?? 0.0;
    final tx = (summary?['totalTx'] as num?)?.toInt() ?? 0;
    final margin = revenue > 0 ? (profit / revenue) * 100 : 0.0;
    final sales = (summary?['sales'] as List? ?? const []).whereType<Map>();

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
          title: _timeframeDataRow(
            _rangeTitle(key),
            AppHelpers.peso(revenue),
            '$tx',
            '${margin.toStringAsFixed(1)}%',
            margin >= 20 ? kGreen : kOrange,
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'View Breakdown',
                style: TextStyle(
                  color: kRed.withValues(alpha: 0.85),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 6),
            if (sales.isEmpty)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'No sales entries for this timeframe.',
                  style: TextStyle(color: kGrey, fontSize: 11),
                ),
              )
            else
              ...sales.take(8).map((raw) {
                final sale = Map<String, dynamic>.from(raw);
                final total = (sale['total'] as num?)?.toDouble() ?? 0.0;
                final saleProfit = (sale['profit'] as num?)?.toDouble() ?? 0.0;
                final customer = (sale['customerName'] ?? 'Walk-in')
                    .toString()
                    .trim();
                final time = DateTime.tryParse(
                  (sale['timestamp'] ?? '').toString(),
                );
                return _breakdownSaleLine(
                  time == null
                      ? sale['date'].toString()
                      : AppHelpers.formatDateTime(time),
                  customer.isEmpty ? 'Walk-in' : customer,
                  AppHelpers.peso(total),
                  AppHelpers.peso(saleProfit),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _timeframeHeaderRow() => Padding(
    padding: const EdgeInsets.only(right: 40, bottom: 4),
    child: Row(
      children: const [
        Expanded(
          flex: 3,
          child: Text('Range', style: TextStyle(color: kGrey, fontSize: 10)),
        ),
        Expanded(
          flex: 3,
          child: Text(
            'Revenue',
            textAlign: TextAlign.right,
            style: TextStyle(color: kGrey, fontSize: 10),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'Sales',
            textAlign: TextAlign.right,
            style: TextStyle(color: kGrey, fontSize: 10),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'Margin',
            textAlign: TextAlign.right,
            style: TextStyle(color: kGrey, fontSize: 10),
          ),
        ),
      ],
    ),
  );

  Widget _timeframeDataRow(
    String range,
    String revenue,
    String sales,
    String margin,
    Color marginColor,
  ) => Row(
    children: [
      Expanded(
        flex: 3,
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: kRed,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                range,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: kDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
      Expanded(
        flex: 3,
        child: Text(
          revenue,
          textAlign: TextAlign.right,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: kRed,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ),
      Expanded(
        flex: 2,
        child: Text(
          sales,
          textAlign: TextAlign.right,
          style: const TextStyle(color: kDark, fontSize: 11),
        ),
      ),
      Expanded(
        flex: 2,
        child: Text(
          margin,
          textAlign: TextAlign.right,
          style: TextStyle(
            color: marginColor,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ),
    ],
  );

  Widget _sectionHeader(IconData icon, String text) => Row(
    children: [
      Icon(icon, color: kRed, size: 16),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: kRed,
            fontSize: 13,
          ),
        ),
      ),
    ],
  );

  Widget _miniMetric(String label, String value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          Text(label, style: const TextStyle(color: kGrey, fontSize: 10)),
        ],
      ),
    ),
  );

  Widget _breakdownSaleLine(
    String time,
    String customer,
    String total,
    String profit,
  ) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(time, style: const TextStyle(color: kGrey, fontSize: 10)),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 4,
          child: Text(
            customer,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: const TextStyle(color: kDark, fontSize: 10),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            '$total\nProfit $profit',
            textAlign: TextAlign.right,
            style: const TextStyle(color: kDark, fontSize: 10, height: 1.25),
          ),
        ),
      ],
    ),
  );

  List<Map<String, dynamic>> _topProductsFrom(Map<String, dynamic> s) =>
      (s['topProducts'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

  ProductModel _productForTop(Map<String, dynamic> item, String name) {
    final productId = (item['productId'] ?? '').toString();
    final matches = _products.where((p) => p.id == productId || p.name == name);
    if (matches.isNotEmpty) return matches.first;
    return ProductModel(
      id: '',
      storeId: '',
      name: name,
      categoryId: '',
      categoryName: '',
      variants: const [],
      addedOn: '',
      updatedAt: '',
    );
  }

  VariantModel? _variantForTop(
    ProductModel product,
    Map<String, dynamic> item,
    String variantName,
  ) {
    final variantId = (item['variantId'] ?? '').toString();
    final matches = product.variants.where(
      (v) => v.id == variantId || v.name == variantName,
    );
    return matches.isEmpty ? null : matches.first;
  }

  String _rangeTitle(String key) {
    switch (key) {
      case 'hour':
        return 'Last Hour';
      case 'today':
        return 'Today';
      case 'yesterday':
        return 'Yesterday';
      case 'week':
        return 'Week';
      case 'month':
        return 'Month';
      case 'year':
        return 'Year';
      case 'total':
        return 'Total';
      case 'custom':
        return 'Custom';
      default:
        return key;
    }
  }
}
