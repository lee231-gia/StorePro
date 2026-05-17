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

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6),
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
                  '${log.variantName}  ·  '
                  '${_reasonLabel(log.reason)}',
                  style: const TextStyle(color: kGrey, fontSize: 11),
                ),
                if (log.employeeName.isNotEmpty)
                  Text(
                    'by ${log.employeeName}',
                    style: const TextStyle(color: kGrey, fontSize: 11),
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
                AppHelpers.formatDate(log.date),
                style: const TextStyle(color: kGrey, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── SHARED FILTERS BAR ────────────────────────────────────
}
