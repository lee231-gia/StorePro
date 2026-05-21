part of 'reports_page.dart';

extension _ReportsActivity on _ReportsPageState {
  Widget _buildActivityTab() {
    final logs = _activityLogs;
    if (logs.isEmpty) {
      return const Center(
        child: Text('No activity logged yet.', style: TextStyle(color: kGrey)),
      );
    }

    return RefreshIndicator(
      color: kRed,
      onRefresh: _generate,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'System Activity Logs',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kDark,
                    fontSize: 16,
                  ),
                ),
              ),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Overview')),
                  ButtonSegment(value: true, label: Text('Detailed')),
                ],
                selected: {_activityDetailed},
                onSelectionChanged: (value) =>
                    _update(() => _activityDetailed = value.first),
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  textStyle: WidgetStateProperty.all(
                    const TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...logs.map((log) => _activityCard(log, detailed: _activityDetailed)),
        ],
      ),
    );
  }

  Widget _activityCard(Map<String, dynamic> log, {required bool detailed}) {
    final action = _actionName(log);
    final timestamp = log['timestamp'] as String? ?? '';
    final color = _activityColor(action);
    final lines = detailed ? _activityDetailLines(log) : const <String>[];
    final total = _activityOverviewTotal(log);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_activityIcon(action), color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '[${_activityTime(timestamp)}] $action$total',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                if (detailed && lines.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ...lines.map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        line,
                        style: const TextStyle(
                          color: kDark,
                          fontSize: 11,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _actionName(Map<String, dynamic> log) {
    final action = (log['action'] as String? ?? '').toLowerCase();
    final details = _details(log);
    final productName = (details['productName'] ?? log['targetName'] ?? '')
        .toString();
    if (action == 'new_sale') return 'New Sale Completed';
    if (action == 'add_product') {
      return productName.isEmpty
          ? 'Added New Product'
          : 'Added New Product: "$productName"';
    }
    if (action == 'edit_product') {
      return productName.isEmpty
          ? 'Edited Existing Product'
          : 'Edited Product: "$productName"';
    }
    if (action == 'delete_product') return 'Deleted Product';
    if (action == 'add_customer') {
      return productName.isEmpty
          ? 'Added Customer'
          : 'Added Customer: "$productName"';
    }
    if (action == 'edit_customer') {
      return productName.isEmpty
          ? 'Updated Customer'
          : 'Updated Customer: "$productName"';
    }
    if (action == 'delete_customer') return 'Deleted Customer';
    return _capitalize(action.replaceAll('_', ' '));
  }

  String _activityOverviewTotal(Map<String, dynamic> log) {
    final action = (log['action'] as String? ?? '').toLowerCase();
    final details = _details(log);
    if (action == 'new_sale') {
      final grandTotal = (details['grandTotal'] as num?)?.toDouble();
      if (grandTotal != null) {
        return ' (Grand Total: ${AppHelpers.peso(grandTotal)})';
      }
    }
    return '';
  }

  List<String> _activityDetailLines(Map<String, dynamic> log) {
    final action = (log['action'] as String? ?? '').toLowerCase();
    final details = _details(log);
    if (details.isEmpty) {
      return const ['Details were not captured for this older log.'];
    }

    if (action == 'new_sale') {
      final total = (details['grandTotal'] as num?)?.toDouble() ?? 0.0;
      final cash = (details['cash'] as num?)?.toDouble() ?? 0.0;
      final utang = (details['utang'] as num?)?.toDouble() ?? 0.0;
      final subtotal = (details['subtotal'] as num?)?.toDouble() ?? 0.0;
      final discount = (details['discount'] as num?)?.toDouble() ?? 0.0;
      final cogs = (details['cogs'] as num?)?.toDouble() ?? 0.0;
      final profit = (details['profit'] as num?)?.toDouble() ?? 0.0;
      final items = (details['items'] as List? ?? const []).whereType<Map>();
      return [
        '-> Grand Total: ${AppHelpers.peso(total)} (Cash: ${AppHelpers.peso(cash)} / Utang: ${AppHelpers.peso(utang)})',
        '-> Cost Breakdown: Subtotal ${AppHelpers.peso(subtotal)} - Discounts ${AppHelpers.peso(discount)} - COGS ${AppHelpers.peso(cogs)} = Profit ${AppHelpers.peso(profit)}',
        if (items.isNotEmpty)
          '-> Items: ${items.map((item) {
            final qty = (item['qty'] as num?)?.toInt() ?? 0;
            final product = (item['productName'] ?? '').toString();
            final variant = (item['variantName'] ?? '').toString();
            return '$qty x $product${variant.isEmpty ? '' : ' ($variant)'}';
          }).join(', ')}',
      ];
    }

    if (action == 'add_product') {
      final count = (details['variantCount'] as num?)?.toInt() ?? 0;
      final variants = (details['variants'] as List? ?? const [])
          .whereType<Map>();
      return [
        '-> Added $count variant${count == 1 ? '' : 's'}:',
        ...variants.map((variant) {
          final name = (variant['name'] ?? 'Variant').toString();
          final stock = (variant['stock'] as num?)?.toInt() ?? 0;
          return '   - $name ($stock units)';
        }),
      ];
    }

    if (action == 'edit_product') {
      final changes = (details['changes'] as List? ?? const [])
          .whereType<Map>();
      if (changes.isEmpty) {
        return const ['-> No material field changes captured.'];
      }
      return changes.map((change) {
        final field = (change['field'] ?? 'Field').toString();
        final oldValue = _formatActivityValue(change['old']);
        final newValue = _formatActivityValue(change['new']);
        return '-> Changed $field from $oldValue to $newValue';
      }).toList();
    }

    return details.entries
        .map((entry) => '-> ${entry.key}: ${_formatActivityValue(entry.value)}')
        .toList();
  }

  Map<String, dynamic> _details(Map<String, dynamic> log) {
    final raw = log['details'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const {};
  }

  String _formatActivityValue(Object? value) {
    if (value is double) return AppHelpers.peso(value);
    if (value is int) return '$value';
    if (value is num) return value.toStringAsFixed(2);
    final text = (value ?? '').toString();
    return text.isEmpty ? 'blank' : text;
  }

  String _activityTime(String timestamp) {
    final parsed = DateTime.tryParse(timestamp);
    if (parsed == null) return '--:--';
    final hour = parsed.hour == 0
        ? 12
        : parsed.hour > 12
        ? parsed.hour - 12
        : parsed.hour;
    final minute = parsed.minute.toString().padLeft(2, '0');
    final suffix = parsed.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  Color _activityColor(String action) {
    final lower = action.toLowerCase();
    if (lower.contains('delete') || lower.contains('refund')) return kRed;
    if (lower.contains('add') || lower.contains('new')) return kGreen;
    if (lower.contains('sale')) return kOrange;
    return kGrey;
  }

  IconData _activityIcon(String action) {
    final lower = action.toLowerCase();
    if (lower.contains('delete')) return Icons.delete_outline;
    if (lower.contains('sale')) return Icons.point_of_sale_outlined;
    if (lower.contains('product')) return Icons.inventory_2_outlined;
    if (lower.contains('category')) return Icons.category_outlined;
    return Icons.history;
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}
