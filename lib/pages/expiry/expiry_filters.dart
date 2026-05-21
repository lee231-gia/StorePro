part of 'expiry_page.dart';

extension _ExpiryFilters on _ExpiryPageState {
  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => _update(() => _search = v),
            decoration: AppInput.field(
              'Search products...',
              icon: Icons.search,
            ),
          ),
          const SizedBox(height: 8),

          // Category chips
          SizedBox(
            height: 30,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final active = _catFilter == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => _update(() => _catFilter = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: active ? kRed : kCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: active ? kRed : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 11,
                          color: active ? Colors.white : kGrey,
                          fontWeight: active
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 6),

          // Life indicator type filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _liChip('all', 'All Types'),
                ...[
                  'Expiry Date',
                  'Best Before',
                  'Manufacturing Date (MFG)',
                  'Use-By',
                  'Sell By',
                ].map(
                  (t) => _liChip(
                    t,
                    t.replaceAll('Manufacturing Date (MFG)', 'MFG'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),
          _expiryOverviewLine(),
        ],
      ),
    );
  }

  Widget _expiryOverviewLine() {
    final counts = _tierCounts;
    final total = counts.values.fold<int>(0, (sum, count) => sum + count);
    final parts = [
      '$total total',
      '${counts['expired'] ?? 0} expired',
      '${counts['urgent'] ?? 0} urgent',
      '${counts['no_date'] ?? 0} no date',
      '${_entries.length} shown',
    ];
    return Text(
      parts.join(' \u2022 '),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(color: kGrey, fontSize: 12),
    );
  }

  Widget _liChip(String value, String label) => Padding(
    padding: const EdgeInsets.only(right: 6),
    child: GestureDetector(
      onTap: () => _update(() => _liFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _liFilter == value
              ? kRed.withValues(alpha: 0.15)
              : Colors.transparent,
          border: Border.all(
            color: _liFilter == value ? kRed : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: _liFilter == value ? kRed : kGrey,
            fontWeight: _liFilter == value
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ),
    ),
  );

  // ── 5-TIER STATUS STRIP ───────────────────────────────────
  Widget _buildTierStrip() {
    final counts = _tierCounts;
    final tiers = ['expired', 'urgent', 'standard', 'good', 'excellent'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: tiers.map((t) {
          final active = _tier == t;
          final color = _ExpiryPageState._tierColor(t);
          final count = counts[t] ?? 0;
          return Expanded(
            child: GestureDetector(
              onTap: () => _update(() => _tier = active ? 'all' : t),
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: active ? color.withValues(alpha: 0.15) : kCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: active ? color : Colors.grey.shade200,
                    width: active ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _ExpiryPageState._tierIcon(t),
                      color: active ? color : kGrey,
                      size: 16,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$count',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: active ? color : kDark,
                      ),
                    ),
                    Text(
                      t == 'expired'
                          ? 'Exp'
                          : t == 'urgent'
                          ? '<30d'
                          : t == 'standard'
                          ? '1-3m'
                          : t == 'good'
                          ? '3-6m'
                          : '6m+',
                      style: const TextStyle(fontSize: 9, color: kGrey),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── DATE RANGE BAR ────────────────────────────────────────
  Widget _buildDateRangeBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final r in {
                    'all': 'All Dates',
                    'today': 'Today',
                    'week': 'This Week',
                    'month': 'This Month',
                    'year': 'This Year',
                  }.entries)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () => _update(() {
                          _dateRange = r.key;
                          _selectedDate = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _dateRange == r.key && _selectedDate == null
                                ? kRed
                                : Colors.transparent,
                            border: Border.all(
                              color:
                                  _dateRange == r.key && _selectedDate == null
                                  ? kRed
                                  : Colors.grey.shade300,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            r.value,
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  _dateRange == r.key && _selectedDate == null
                                  ? Colors.white
                                  : kGrey,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Calendar pick button
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2040),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.light(primary: kRed),
                  ),
                  child: child!,
                ),
              );
              if (d != null) {
                _update(() {
                  _selectedDate = d;
                  _dateRange = 'custom';
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _selectedDate != null ? kRed : kCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _selectedDate != null ? kRed : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    color: _selectedDate != null ? Colors.white : kGrey,
                    size: 16,
                  ),
                  if (_selectedDate != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      '${_selectedDate!.day}/'
                      '${_selectedDate!.month}',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── CONTENT ───────────────────────────────────────────────
}
