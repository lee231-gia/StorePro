enum ProductViewMode {
  list('list', 'List'),
  compact('compact', 'Compact'),
  grid('grid', 'Grid'),
  details('details', 'Details');

  const ProductViewMode(this.value, this.label);

  final String value;
  final String label;

  static ProductViewMode fromValue(String value) {
    return ProductViewMode.values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => ProductViewMode.list,
    );
  }
}

enum ProductSortOption {
  recent('recent', 'Recently Added'),
  nameAsc('a-z', 'Name A-Z'),
  nameDesc('z-a', 'Name Z-A'),
  categoryAsc('cat-a-z', 'Category A-Z'),
  categoryDesc('cat-z-a', 'Category Z-A'),
  stockAsc('stock-low', 'Stock: Low to High'),
  stockDesc('stock-high', 'Stock: High to Low'),
  expiryAsc('expiry-asc', 'Expiry: Nearest First'),
  expiryDesc('expiry-desc', 'Expiry: Furthest First'),
  priceAsc('price-low', 'Price: Low to High'),
  priceDesc('price-high', 'Price: High to Low');

  const ProductSortOption(this.value, this.label);

  final String value;
  final String label;

  static ProductSortOption fromValue(String value) {
    return ProductSortOption.values.firstWhere(
      (option) => option.value == value,
      orElse: () => ProductSortOption.recent,
    );
  }
}
