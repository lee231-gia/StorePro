part of 'reports_page.dart';

extension _ReportsFilters on _ReportsPageState {
  Widget _buildRangeSelector() {
    final cs = Theme.of(context).colorScheme;
    final ranges = {
      'hour': 'Hour',
      'today': 'Today',
      'yesterday': 'Yesterday',
      'week': 'Week',
      'month': 'Month',
      'year': 'Year',
      'total': 'Total',
      'custom': 'Custom',
    };

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ranges.entries
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () => e.key == 'custom'
                            ? _pickCustom()
                            : _setRange(e.key),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _range == e.key
                                ? cs.primary
                                : cs.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _range == e.key
                                  ? cs.primary
                                  : cs.outlineVariant,
                            ),
                          ),
                          child: Text(
                            e.value,
                            style: TextStyle(
                              fontSize: 12,
                              color: _range == e.key
                                  ? cs.onPrimary
                                  : cs.onSurfaceVariant,
                              fontWeight: _range == e.key
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            '${AppHelpers.formatDate(_fmt(_from))}  \u2192  '
            '${AppHelpers.formatDate(_fmt(_to))}',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surface,
      child: TabBar(
        controller: _tabCtrl,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: cs.primary,
        unselectedLabelColor: cs.onSurfaceVariant,
        indicatorColor: cs.primary,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        labelPadding: const EdgeInsets.symmetric(horizontal: 14),
        tabs: const [
          Tab(text: 'Sales & Revenue'),
          Tab(text: 'Inventory'),
          Tab(text: 'Profit Margins'),
          Tab(text: 'Activity'),
        ],
      ),
    );
  }

  Future<void> _pickCustom() async {
    final cs = Theme.of(context).colorScheme;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _from, end: _to),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: cs.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      _update(() {
        _range = 'custom';
        _from = picked.start;
        _to = picked.end;
      });
      _generate();
    }
  }
}
