import '../../core/base/base_controller.dart';

typedef SearchMatcher<T> = bool Function(T item, String query);
typedef FilterMatcher<T> = bool Function(T item, String filter);
typedef Sorter<T> = int Function(T a, T b);

class ListQueryController<T> extends BaseController {
  ListQueryController({
    this.searchMatcher,
    this.filterMatcher,
    Map<String, Sorter<T>> sorters = const {},
    String filter = 'all',
    String sortKey = '',
  }) : _filter = filter,
       _sortKey = sortKey,
       _sorters = sorters;

  final SearchMatcher<T>? searchMatcher;
  final FilterMatcher<T>? filterMatcher;
  final Map<String, Sorter<T>> _sorters;

  String _query = '';
  String _filter;
  String _sortKey;

  String get query => _query;
  String get filter => _filter;
  String get sortKey => _sortKey;

  set query(String value) {
    if (_query == value) return;
    _query = value;
    notifySafely();
  }

  set filter(String value) {
    if (_filter == value) return;
    _filter = value;
    notifySafely();
  }

  set sortKey(String value) {
    if (_sortKey == value) return;
    _sortKey = value;
    notifySafely();
  }

  List<T> apply(Iterable<T> items) {
    var result = List<T>.from(items);
    final cleanQuery = _query.trim().toLowerCase();
    if (cleanQuery.isNotEmpty && searchMatcher != null) {
      result = result
          .where((item) => searchMatcher!(item, cleanQuery))
          .toList();
    }
    if (_filter != 'all' && filterMatcher != null) {
      result = result.where((item) => filterMatcher!(item, _filter)).toList();
    }
    final sorter = _sorters[_sortKey];
    if (sorter != null) result.sort(sorter);
    return result;
  }
}
