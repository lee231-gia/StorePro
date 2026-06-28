import 'package:flutter_test/flutter_test.dart';
import 'package:storepro/shared/controllers/list_query_controller.dart';

void main() {
  group('ListQueryController', () {
    group('search', () {
      late ListQueryController<String> controller;

      final items = [
        'Coca-Cola', 'Mountain Dew', 'Lays Classic', 'Piatos', 'Coke Zero',
      ];

      setUp(() {
        controller = ListQueryController<String>(
          searchMatcher: (item, query) => item.toLowerCase().contains(query),
        );
      });

      test('returns all items when query is empty', () {
        final result = controller.apply(items);
        expect(result.length, equals(5));
      });

      test('filters items matching query', () {
        controller.query = 'coca';
        final result = controller.apply(items);
        expect(result, equals(['Coca-Cola']));
      });

      test('is case-insensitive', () {
        controller.query = 'MOUNTAIN';
        final result = controller.apply(items);
        expect(result, equals(['Mountain Dew']));
      });

      test('returns empty when no match', () {
        controller.query = 'nonexistent';
        final result = controller.apply(items);
        expect(result, isEmpty);
      });

      test('trimmed whitespace does not affect results', () {
        controller.query = '  dew  ';
        final result = controller.apply(items);
        expect(result.length, equals(1));
      });

      test('does not filter when searchMatcher is null', () {
        final noSearch = ListQueryController<String>();
        noSearch.query = 'coke';
        final result = noSearch.apply(items);
        expect(result.length, equals(5));
      });
    });

    group('filter', () {
      late ListQueryController<String> controller;

      final items = ['apple', 'banana', 'apricot', 'blueberry', 'cherry'];

      setUp(() {
        controller = ListQueryController<String>(
          filterMatcher: (item, filter) => item.startsWith(filter),
        );
      });

      test('returns items matching filter prefix', () {
        controller.filter = 'a';
        final result = controller.apply(items);
        expect(result, containsAll(['apple', 'apricot']));
        expect(result.length, equals(2));
      });

      test('returns all items when filter is "all"', () {
        controller.filter = 'all';
        final result = controller.apply(items);
        expect(result.length, equals(5));
      });

      test('does not filter when filterMatcher is null', () {
        final noFilter = ListQueryController<String>();
        noFilter.filter = 'a';
        final result = noFilter.apply(items);
        expect(result.length, equals(5));
      });
    });

    group('sort', () {
      late ListQueryController<String> controller;

      final items = ['banana', 'apple', 'cherry', 'date'];

      setUp(() {
        controller = ListQueryController<String>(
          sorters: {
            'asc': (a, b) => a.compareTo(b),
            'desc': (a, b) => b.compareTo(a),
            'length': (a, b) => a.length.compareTo(b.length),
          },
        );
      });

      test('sorts ascending when sortKey is "asc"', () {
        controller.sortKey = 'asc';
        final result = controller.apply(items);
        expect(result, equals(['apple', 'banana', 'cherry', 'date']));
      });

      test('sorts descending when sortKey is "desc"', () {
        controller.sortKey = 'desc';
        final result = controller.apply(items);
        expect(result, equals(['date', 'cherry', 'banana', 'apple']));
      });

      test('sorts by custom comparator', () {
        controller.sortKey = 'length';
        final result = controller.apply(items);
        expect(result, equals(['date', 'apple', 'banana', 'cherry']));
      });

      test('does not sort when sortKey does not match any sorter', () {
        controller.sortKey = 'nonexistent';
        final result = controller.apply(items);
        expect(result, equals(['banana', 'apple', 'cherry', 'date']));
      });

      test('does not sort when sorters map is empty', () {
        final noSort = ListQueryController<String>();
        noSort.sortKey = 'asc';
        final result = noSort.apply(items);
        expect(result, equals(items));
      });

      test('does not sort when sortKey is empty string', () {
        controller.sortKey = '';
        final result = controller.apply(items);
        expect(result, equals(['banana', 'apple', 'cherry', 'date']));
      });
    });

    group('combined search + filter + sort', () {
      test('applies all three operations in order', () {
        final items = [
          'Green Apple', 'Red Apple', 'Banana', 'Grapes', 'Mango',
        ];
        final controller = ListQueryController<String>(
          searchMatcher: (item, query) => item.toLowerCase().contains(query),
          filterMatcher: (item, filter) => item.startsWith(filter),
          sorters: {'alpha': (a, b) => a.compareTo(b)},
        );
        controller.query = 'apple';
        controller.filter = 'G';
        controller.sortKey = 'alpha';
        final result = controller.apply(items);
        expect(result, equals(['Green Apple']));
      });
    });

    group('notifySafely prevents notification after dispose', () {
      test('does not throw when query is set after dispose', () {
        final controller = ListQueryController<String>(
          searchMatcher: (item, query) => item.contains(query),
        );
        controller.dispose();
        expect(() { controller.query = 'test'; }, returnsNormally);
      });
    });
  });
}
