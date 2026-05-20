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
                  'All Activity',
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
          ...logs.map(_activityCard),
        ],
      ),
    );
  }

  Widget _activityCard(Map<String, dynamic> log) {
    final action = (log['action'] as String? ?? '').replaceAll('_', ' ');
    final employee = log['employeeName'] as String? ?? '';
    final target = log['targetName'] as String? ?? '';
    final targetType = log['targetType'] as String? ?? '';
    final targetId = log['targetId'] as String? ?? '';
    final timestamp = log['timestamp'] as String? ?? '';
    final color = _activityColor(action);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: targetType == 'product' && targetId.isNotEmpty
          ? () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailPage(productId: targetId),
              ),
            )
          : null,
      child: Container(
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
                    _capitalize(action),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  if (target.isNotEmpty)
                    Text(
                      target,
                      style: const TextStyle(
                        color: kDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: _activityDetailed ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (_activityDetailed) ...[
                    const SizedBox(height: 2),
                    Text(
                      'By ${employee.isEmpty ? 'System' : employee}',
                      style: const TextStyle(color: kGrey, fontSize: 11),
                    ),
                    if (targetType.isNotEmpty)
                      Text(
                        'Target: $targetType',
                        style: const TextStyle(color: kGrey, fontSize: 11),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              AppHelpers.formatDateTime(
                DateTime.tryParse(timestamp) ?? DateTime.now(),
              ),
              textAlign: TextAlign.right,
              style: const TextStyle(color: kGrey, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Color _activityColor(String action) {
    if (action.contains('delete') || action.contains('refund')) return kRed;
    if (action.contains('add') || action.contains('new')) return kGreen;
    if (action.contains('sale')) return kOrange;
    return kGrey;
  }

  IconData _activityIcon(String action) {
    if (action.contains('delete')) return Icons.delete_outline;
    if (action.contains('sale')) return Icons.point_of_sale_outlined;
    if (action.contains('product')) return Icons.inventory_2_outlined;
    if (action.contains('category')) return Icons.category_outlined;
    return Icons.history;
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}
