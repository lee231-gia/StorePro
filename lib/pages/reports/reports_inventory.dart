part of 'reports_page.dart';

extension _ReportsInventory on _ReportsPageState {
  Widget _buildInventoryTab() {
    return FutureBuilder(
      future: Future.wait([
        ReportRepository.getInventoryLogs(_fmt(_from), _fmt(_to)),
        ProductRepository.getAll(),
      ]).timeout(const Duration(seconds: 4), onTimeout: () => [[], []]),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kRed));
        }
        if (snap.hasError) {
          return const Center(
            child: Text(
              'Could not load inventory report.',
              style: TextStyle(color: kGrey),
            ),
          );
        }
        if (!snap.hasData) return const SizedBox.shrink();

        final logs = snap.data![0] as List;
        final products = snap.data![1] as List<ProductModel>;

        final added = logs.fold(
          0,
          (s, l) => s + (l.qty > 0 ? l.qty as int : 0),
        );
        final removed = logs.fold(
          0,
          (s, l) => s + (l.qty < 0 ? (l.qty as int).abs() : 0),
        );

        // Inventory value
        double invValue = 0;
        for (final p in products) {
          for (final v in p.variants) {
            invValue += v.totalStock * v.avgCostPrice;
          }
        }

        // Expiry risk
        double expiryRisk = 0;
        final expAlerts = <Map<String, dynamic>>[];
        for (final p in products) {
          for (final v in p.variants) {
            final tier = v.expiryTier;
            if (tier == 'expired' || tier == 'urgent') {
              final risk = v.totalStock * v.avgCostPrice;
              expiryRisk += risk;
              if (tier == 'expired' || tier == 'urgent') {
                expAlerts.add({
                  'name': p.name,
                  'variant': v.name,
                  'tier': tier,
                  'stock': v.totalStock,
                  'risk': risk,
                });
              }
            }
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── INVENTORY VALUE ────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kGreen, Color(0xFF1B5E20)],
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
                        fontSize: 24,
                      ),
                    ),
                    const Text(
                      'Stock on Hand × Cost Price',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  _statCard2('Stock Added', '+$added pcs', kGreen),
                  const SizedBox(width: 10),
                  _statCard2('Stock Removed', '-$removed pcs', kOrange),
                ],
              ),

              const SizedBox(height: 12),

              // ── EXPIRY RISK ────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kRedLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kRed.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber, color: kRed, size: 18),
                        const SizedBox(width: 6),
                        const Text(
                          'Potential Loss (Expiry Risk)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: kRed,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppHelpers.peso(expiryRisk),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: kRed,
                      ),
                    ),
                    const Text(
                      'Expired + Urgent items × Cost Price\n'
                      'This is how much you could lose '
                      'if these items expire.',
                      style: TextStyle(color: kGrey, fontSize: 11, height: 1.4),
                    ),
                  ],
                ),
              ),

              if (expAlerts.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'At-Risk Items',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: kDark,
                  ),
                ),
                const SizedBox(height: 8),
                ...expAlerts.map(
                  (a) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: a['tier'] == 'expired' ? kRed : kOrange,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          a['tier'] == 'expired'
                              ? Icons.dangerous_outlined
                              : Icons.warning_amber_outlined,
                          color: a['tier'] == 'expired' ? kRed : kOrange,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${a['name']} — ${a['variant']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${a['stock']} pcs at risk',
                                style: const TextStyle(
                                  color: kGrey,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          AppHelpers.peso((a['risk'] as double)),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: kRed,
                            fontSize: 12,
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
      },
    );
  }

  // ══════════════════════════════════════════════════════════
  // TAB 2 — PROFIT MARGINS
  // ══════════════════════════════════════════════════════════
}
