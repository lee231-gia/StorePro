import 'package:flutter_test/flutter_test.dart';
import 'package:storepro/core/enums/product_browser_enums.dart';

void main() {
  group('ProductViewMode', () {
    test('values have correct string representations', () {
      expect(ProductViewMode.list.value, equals('list'));
      expect(ProductViewMode.list.label, equals('List'));
      expect(ProductViewMode.grid.value, equals('grid'));
      expect(ProductViewMode.details.label, equals('Details'));
    });

    test('fromValue returns correct enum for valid value', () {
      expect(ProductViewMode.fromValue('list'), equals(ProductViewMode.list));
      expect(ProductViewMode.fromValue('compact'), equals(ProductViewMode.compact));
      expect(ProductViewMode.fromValue('grid'), equals(ProductViewMode.grid));
      expect(ProductViewMode.fromValue('details'), equals(ProductViewMode.details));
    });

    test('fromValue returns list for unknown value', () {
      expect(ProductViewMode.fromValue('unknown'), equals(ProductViewMode.list));
    });

    test('fromValue returns list for empty string', () {
      expect(ProductViewMode.fromValue(''), equals(ProductViewMode.list));
    });
  });

  group('ProductSortOption', () {
    test('values have correct string representations', () {
      expect(ProductSortOption.recent.value, equals('recent'));
      expect(ProductSortOption.recent.label, equals('Recently Added'));
      expect(ProductSortOption.nameAsc.value, equals('a-z'));
      expect(ProductSortOption.nameAsc.label, equals('Name A-Z'));
    });

    test('has all expected sort options', () {
      expect(ProductSortOption.values.length, equals(11));
      expect(ProductSortOption.values, containsAll([
        ProductSortOption.recent,
        ProductSortOption.nameAsc,
        ProductSortOption.nameDesc,
        ProductSortOption.categoryAsc,
        ProductSortOption.categoryDesc,
        ProductSortOption.stockAsc,
        ProductSortOption.stockDesc,
        ProductSortOption.expiryAsc,
        ProductSortOption.expiryDesc,
        ProductSortOption.priceAsc,
        ProductSortOption.priceDesc,
      ]));
    });

    test('fromValue returns correct enum for valid value', () {
      expect(ProductSortOption.fromValue('a-z'), equals(ProductSortOption.nameAsc));
      expect(ProductSortOption.fromValue('stock-high'), equals(ProductSortOption.stockDesc));
      expect(ProductSortOption.fromValue('price-low'), equals(ProductSortOption.priceAsc));
    });

    test('fromValue returns recent for unknown value', () {
      expect(ProductSortOption.fromValue('unknown'), equals(ProductSortOption.recent));
    });

    test('fromValue returns recent for empty string', () {
      expect(ProductSortOption.fromValue(''), equals(ProductSortOption.recent));
    });
  });
}
