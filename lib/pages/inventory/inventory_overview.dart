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

    final cs = Theme.of(context).colorScheme;
    return RefreshIndicator(
      color: cs.primary,
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
                  cs.primary,
                ),
                const SizedBox(width: 10),
                _statCard(
                  'Total Stock',
                  '$totalStock pcs',
                  Icons.warehouse_outlined,
                  cs.brightness == Brightness.dark ? PaletteDark.success : PaletteLight.success,
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
                  cs.brightness == Brightness.dark ? PaletteDark.warning : PaletteLight.warning,
                ),
                const SizedBox(width: 10),
                _statCard('No Stock', '$noStock', Icons.block_outlined, cs.primary),
              ],
            ),
            const SizedBox(height: 10),
            // Inventory value card (full width)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary, Color.lerp(cs.primary, Colors.black, 0.15)!],
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
                  Text(
                    AppHelpers.peso(invValue),
                    style: TextStyle(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  Text(
                    'Stock on Hand × Cost Price',
                    style: TextStyle(color: cs.onPrimary.withValues(alpha: 0.6), fontSize: 11),
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
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
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
