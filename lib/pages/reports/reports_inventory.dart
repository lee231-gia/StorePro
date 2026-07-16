part of 'reports_page.dart';

extension _ReportsInventory on _ReportsPageState {
  Widget _buildInventoryTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final success = isDark ? PaletteDark.success : PaletteLight.success;
    final warning = isDark ? PaletteDark.warning : PaletteLight.warning;
    final error = isDark ? PaletteDark.error : PaletteLight.error;

    return FutureBuilder<List<InventoryLogModel>>(
      future: ReportRepository.getInventoryLogs(
        _fmt(_from),
        _fmt(_to),
      ).timeout(const Duration(seconds: 4), onTimeout: () => const []),
      builder: (ctx, snap) {
        final cs = Theme.of(context).colorScheme;
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: AppSkeletonList(itemCount: 3),
          );
        }

        final logs = snap.data ?? const <InventoryLogModel>[];
        final products = _products;
        final lowStock = _stockRows(products, lowOnly: true);
        final noStock = _stockRows(products, noStockOnly: true);
        final atRisk = _expiryRiskRows(products);
        final damaged = _lossRows(logs);

        final added = logs.fold(0, (sum, l) => sum + (l.qty > 0 ? l.qty : 0));
        final removed = logs.fold(
          0,
          (sum, l) => sum + (l.qty < 0 ? l.qty.abs() : 0),
        );
        final invValue = products.fold(0.0, (sum, p) {
          return sum +
              p.variants.fold(
                0.0,
                (variantSum, v) => variantSum + (v.totalStock * v.avgCostPrice),
              );
        });
        final damagedLoss = damaged.fold(
          0.0,
          (sum, row) => sum + ((row['loss'] as num?)?.toDouble() ?? 0.0),
        );
        final riskLoss = atRisk.fold(
          0.0,
          (sum, row) => sum + ((row['risk'] as num?)?.toDouble() ?? 0.0),
        );

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [success, Color.lerp(success, Colors.black, 0.2)!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Inventory Value',
                    style: TextStyle(color: cs.onPrimary.withValues(alpha: 0.7), fontSize: 12),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      AppHelpers.peso(invValue),
                      style: TextStyle(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  Text(
                    'Stock on hand x average cost price',
                    style: TextStyle(color: cs.onPrimary.withValues(alpha: 0.6), fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _statCard2('Stock Added', '+$added pcs', success),
                const SizedBox(width: 10),
                _statCard2('Stock Removed', '-$removed pcs', warning),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _statCard2('Total Low Stock', '${lowStock.length}', warning),
                const SizedBox(width: 10),
                _statCard2('Total No Stock', '${noStock.length}', error),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _statCard2(
                  'Damaged/Shrinkage',
                  AppHelpers.peso(damagedLoss),
                  error,
                ),
                const SizedBox(width: 10),
                _statCard2('At Risk Loss', AppHelpers.peso(riskLoss), warning),
              ],
            ),
            const SizedBox(height: 12),
            _reorderWarning(lowStock),
            _inventoryListSection(
              'Low Stock Products',
              lowStock,
              emptyText: 'No low-stock products.',
              color: warning,
            ),
            _inventoryListSection(
              'No Stock Products',
              noStock,
              emptyText: 'No out-of-stock products.',
              color: error,
            ),
            _inventoryListSection(
              'At Risk Products',
              atRisk,
              emptyText: 'No urgent expiry risk found.',
              color: error,
              amountKey: 'risk',
            ),
            _inventoryListSection(
              'Shrinkage / Damaged Losses',
              damaged,
              emptyText: 'No shrinkage or damaged losses in this range.',
              color: error,
              amountKey: 'loss',
            ),
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> _stockRows(
    List<ProductModel> products, {
    bool lowOnly = false,
    bool noStockOnly = false,
  }) {
    final rows = <Map<String, dynamic>>[];
    for (final product in products) {
      for (final variant in product.variants) {
        final stock = variant.totalStock;
        if (noStockOnly && stock != 0) continue;
        if (lowOnly && (stock <= 0 || stock > 10)) continue;
        rows.add({
          'productId': product.id,
          'name': product.name,
          'variant': variant.name,
          'stock': stock,
          'subtitle': '${variant.name} | $stock pcs',
        });
      }
    }
    rows.sort((a, b) => (a['stock'] as int).compareTo(b['stock'] as int));
    return rows;
  }

  List<Map<String, dynamic>> _expiryRiskRows(List<ProductModel> products) {
    final rows = <Map<String, dynamic>>[];
    for (final product in products) {
      for (final variant in product.variants) {
        final tier = variant.expiryTier;
        if (tier != 'expired' && tier != 'urgent') continue;
        final risk = variant.totalStock * variant.avgCostPrice;
        rows.add({
          'productId': product.id,
          'name': product.name,
          'variant': variant.name,
          'stock': variant.totalStock,
          'risk': risk,
          'subtitle': '${variant.name} | ${variant.totalStock} pcs | $tier',
        });
      }
    }
    rows.sort((a, b) => ((b['risk'] as double).compareTo(a['risk'] as double)));
    return rows;
  }

  List<Map<String, dynamic>> _lossRows(List<InventoryLogModel> logs) {
    final grouped = <String, Map<String, dynamic>>{};
    for (final log in logs) {
      final reason = log.reason.toLowerCase();
      final isLoss =
          reason.contains('damage') ||
          reason.contains('shrink') ||
          reason.contains('loss') ||
          reason.contains('expired');
      if (!isLoss || log.qty >= 0) continue;
      final key = '${log.productId}:${log.variantId}';
      final current = grouped[key];
      final qty = log.qty.abs();
      grouped[key] = {
        'productId': log.productId,
        'name': log.productName,
        'variant': log.variantName,
        'stock': ((current?['stock'] as int?) ?? 0) + qty,
        'loss':
            ((current?['loss'] as num?)?.toDouble() ?? 0.0) +
            (qty * log.costPrice),
        'subtitle': '${log.variantName} | ${_reasonLabel(log.reason)}',
      };
    }
    final rows = grouped.values.toList();
    rows.sort((a, b) => ((b['loss'] as double).compareTo(a['loss'] as double)));
    return rows;
  }

  Widget _reorderWarning(List<Map<String, dynamic>> lowStock) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final warning = isDark ? PaletteDark.warning : PaletteLight.warning;
    final critical = lowStock
        .where((row) => (row['stock'] as int) <= 5)
        .toList();
    if (critical.isEmpty) return const SizedBox.shrink();
    final names = critical
        .take(2)
        .map((row) => '${row['name']} ${row['variant']}')
        .join(' and ');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_outlined, color: warning, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Reorder Warning: $names ${critical.length > 2 ? 'and ${critical.length - 2} more are' : 'are'} critically low.',
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

  Widget _inventoryListSection(
    String title,
    List<Map<String, dynamic>> rows, {
    required String emptyText,
    required Color color,
    String? amountKey,
  }) {
    final cs = Theme.of(context).colorScheme;
    return appCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                    fontSize: 14,
                  ),
                ),
              ),
              statusBadge('${rows.length}', color),
            ],
          ),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            Text(emptyText, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11))
          else
            ...rows.take(8).map((row) {
              final amount = amountKey == null
                  ? null
                  : (row[amountKey] as num?)?.toDouble();
              return InkWell(
                onTap: () {
                  final id = (row['productId'] ?? '').toString();
                  if (id.isEmpty) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailPage(productId: id),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, color: color, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (row['name'] ?? '').toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: cs.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              (row['subtitle'] ?? '').toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (amount != null)
                        Text(
                          AppHelpers.peso(amount),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  String _reasonLabel(String value) {
    if (value.isEmpty) return 'Adjustment';
    return value
        .split('_')
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }
}
