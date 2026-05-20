part of 'inventory_page.dart';

extension _InventoryLogs on _InventoryPageState {
  Widget _buildLogs() {
    if (_logs.isEmpty) {
      return const Center(
        child: Text('No inventory logs yet.', style: TextStyle(color: kGrey)),
      );
    }
    return RefreshIndicator(
      color: kRed,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _logs.length,
        itemBuilder: (_, i) => _logCard(_logs[i]),
      ),
    );
  }

  Widget _logCard(InventoryLogModel log) {
    final isAdd = log.qty > 0;
    final color = isAdd ? kGreen : kRed;
    final icon = isAdd ? Icons.add_circle_outline : Icons.remove_circle_outline;
    final currentStock = _currentStockForLog(log);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailPage(productId: log.productId),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: kDark,
                    ),
                  ),
                  Text(
                    '${log.variantName} • ${_reasonLabel(log.reason)}',
                    style: const TextStyle(color: kGrey, fontSize: 11),
                  ),
                  if (currentStock != null)
                    Text(
                      'Current stock: $currentStock pcs left',
                      style: TextStyle(
                        color: AppHelpers.stockColor(currentStock),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${log.qty > 0 ? '+' : ''}${log.qty} pcs',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: color,
                  ),
                ),
                Text(
                  _logDateTime(log),
                  style: const TextStyle(color: kGrey, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int? _currentStockForLog(InventoryLogModel log) {
    for (final product in _products) {
      if (product.id != log.productId) continue;
      for (final variant in product.variants) {
        if (variant.id == log.variantId) return variant.totalStock;
      }
      return product.totalStock;
    }
    return null;
  }

  String _logDateTime(InventoryLogModel log) {
    final dt = DateTime.tryParse(
      log.updatedAt.isNotEmpty ? log.updatedAt : log.date,
    );
    if (dt == null) return AppHelpers.formatDate(log.date);
    return AppHelpers.formatDateTime(dt);
  }
}
