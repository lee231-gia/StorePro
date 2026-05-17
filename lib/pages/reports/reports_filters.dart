part of 'reports_page.dart';

extension _ReportsFilters on _ReportsPageState {
  Widget _buildRangeSelector() {
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
                            color: _range == e.key ? kRed : kCard,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _range == e.key
                                  ? kRed
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            e.value,
                            style: TextStyle(
                              fontSize: 12,
                              color: _range == e.key ? Colors.white : kGrey,
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
            '${AppHelpers.formatDate(_fmt(_from))}  →  '
            '${AppHelpers.formatDate(_fmt(_to))}',
            style: const TextStyle(color: kGrey, fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: kCard,
      child: TabBar(
        controller: _tabCtrl,
        labelColor: kRed,
        unselectedLabelColor: kGrey,
        indicatorColor: kRed,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        tabs: const [
          Tab(text: 'Sales & Revenue'),
          Tab(text: 'Inventory'),
          Tab(text: 'Profit Margins'),
        ],
      ),
    );
  }

  Future<void> _pickCustom() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _from, end: _to),
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: const ColorScheme.light(primary: kRed)),
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

  // ══════════════════════════════════════════════════════════
  // TAB 0 — SALES & REVENUE
  // ══════════════════════════════════════════════════════════
}
