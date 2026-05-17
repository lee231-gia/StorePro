part of 'expiry_page.dart';

extension _ExpiryContent on _ExpiryPageState {
  Widget _buildContent() {
    final entries = _entries;
    if (entries.isEmpty) {
      return const Center(
        child: Text(
          'No items match the filter.',
          style: TextStyle(color: kGrey),
        ),
      );
    }

    if (_viewMode == 'grid') {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.0,
        ),
        itemCount: entries.length,
        itemBuilder: (_, i) => _gridCard(entries[i]),
      );
    }

    if (_viewMode == 'compact') {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: entries.length,
        itemBuilder: (_, i) => _compactRow(entries[i]),
      );
    }

    if (_viewMode == 'details') {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: entries.length,
        itemBuilder: (_, i) => _detailCard(entries[i]),
      );
    }

    // Default: list
    return RefreshIndicator(
      color: kRed,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: entries.length,
        itemBuilder: (_, i) => _listCard(entries[i]),
      ),
    );
  }

  // ── LIST CARD ─────────────────────────────────────────────
}
