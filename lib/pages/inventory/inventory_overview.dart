part of 'inventory_page.dart';

extension _InventoryOverview on _InventoryPageState {
  Widget _buildOverview() {
    final totalStock = _products.fold(0, (s, p) => s + p.totalStock);
    final lowCount = _products
        .where((p) => p.totalStock > 0 && p.totalStock <= 10)
        .length;
    final noStock = _products.where((p) => p.totalStock == 0).length;
    // Inventory value = sum(variant stock × costPrice)
    double invValue = 0;
    for (final p in _products) {
      for (final v in p.variants) {
        invValue += v.totalStock * v.avgCostPrice;
      }
    }

    return RefreshIndicator(
      color: kRed,
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── STAT CARDS ─────────────────────────────
            Row(
              children: [
                _statCard(
                  'Products',
                  '${_products.length}',
                  Icons.inventory_2_outlined,
                  kRed,
                ),
                const SizedBox(width: 10),
                _statCard(
                  'Total Stock',
                  '$totalStock pcs',
                  Icons.warehouse_outlined,
                  kGreen,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _statCard(
                  'Low Stock',
                  '$lowCount',
                  Icons.warning_amber_outlined,
                  kOrange,
                ),
                const SizedBox(width: 10),
                _statCard('No Stock', '$noStock', Icons.block_outlined, kRed),
              ],
            ),
            const SizedBox(height: 10),
            // Inventory value card (full width)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [kRed, kRedDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Inventory Value',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    AppHelpers.peso(invValue),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  const Text(
                    'Stock on Hand × Cost Price',
                    style: TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── FILTERS ────────────────────────────────
            _buildTopFilters(showSearch: true),

            const SizedBox(height: 12),

            // ── PRODUCT LIST ───────────────────────────
            Text(
              '${_filtered.length} product'
              '${_filtered.length != 1 ? 's' : ''}',
              style: const TextStyle(color: kGrey, fontSize: 12),
            ),
            const SizedBox(height: 8),
            _buildProductView(_filtered, showStock: true),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // TAB 1 — REPLENISH
  // ══════════════════════════════════════════════════════════
}
