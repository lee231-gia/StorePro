import 'package:flutter/foundation.dart';

import '../../core/enums/product_browser_enums.dart';
import '../../core/utils/app_helpers.dart';
import '../../models/product_model.dart';
import '../../widgets/product_card.dart';

class ProductBrowserController extends ChangeNotifier {
  ProductBrowserController({
    ProductViewMode viewMode = ProductViewMode.list,
    ProductSortOption sortOption = ProductSortOption.recent,
    String categoryFilter = 'All',
    String statusFilter = 'All',
    bool groupVariants = true,
  }) : _viewMode = viewMode,
       _sortOption = sortOption,
       _categoryFilter = categoryFilter,
       _statusFilter = statusFilter,
       _groupVariants = groupVariants;

  String _search = '';
  ProductViewMode _viewMode;
  ProductSortOption _sortOption;
  String _categoryFilter;
  String _statusFilter;
  bool _groupVariants;

  String get search => _search;
  ProductViewMode get viewMode => _viewMode;
  ProductSortOption get sortOption => _sortOption;
  String get categoryFilter => _categoryFilter;
  String get statusFilter => _statusFilter;
  bool get groupVariants => _groupVariants;

  set search(String value) {
    if (_search == value) return;
    _search = value;
    notifyListeners();
  }

  set viewMode(ProductViewMode value) {
    if (_viewMode == value) return;
    _viewMode = value;
    notifyListeners();
  }

  set sortOption(ProductSortOption value) {
    if (_sortOption == value) return;
    _sortOption = value;
    notifyListeners();
  }

  set categoryFilter(String value) {
    if (_categoryFilter == value) return;
    _categoryFilter = value;
    notifyListeners();
  }

  set statusFilter(String value) {
    if (_statusFilter == value) return;
    _statusFilter = value;
    notifyListeners();
  }

  set groupVariants(bool value) {
    if (_groupVariants == value) return;
    _groupVariants = value;
    notifyListeners();
  }

  List<ProductModel> apply(Iterable<ProductModel> products) {
    var list = List<ProductModel>.from(products);
    final q = _search.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((p) {
        return p.name.toLowerCase().contains(q) ||
            p.categoryName.toLowerCase().contains(q) ||
            p.variants.any((v) => v.name.toLowerCase().contains(q));
      }).toList();
    }
    if (_categoryFilter != 'All') {
      list = list.where((p) => p.categoryName == _categoryFilter).toList();
    }
    list = _applyStatusFilter(list);
    _sort(list);
    return list;
  }

  List<ProductDisplayItem> displayItems(Iterable<ProductModel> products) {
    return ProductDisplayItem.fromProducts(
      apply(products),
      groupVariants: _groupVariants,
    );
  }

  List<ProductModel> _applyStatusFilter(List<ProductModel> products) {
    switch (_statusFilter) {
      case 'Expiring':
        return products
            .where(
              (p) => AppHelpers.expiryStatus(p.nearestExpiry) == 'expiring',
            )
            .toList();
      case 'Expired':
        return products
            .where((p) => AppHelpers.expiryStatus(p.nearestExpiry) == 'expired')
            .toList();
      case 'Low Stock':
        return products
            .where((p) => p.totalStock > 0 && p.totalStock <= 10)
            .toList();
      case 'No Stock':
        return products.where((p) => p.totalStock == 0).toList();
      case 'Available':
        return products.where((p) => p.totalStock > 0).toList();
      default:
        return products;
    }
  }

  void _sort(List<ProductModel> products) {
    switch (_sortOption) {
      case ProductSortOption.nameAsc:
        products.sort((a, b) => a.name.compareTo(b.name));
        break;
      case ProductSortOption.nameDesc:
        products.sort((a, b) => b.name.compareTo(a.name));
        break;
      case ProductSortOption.categoryAsc:
        products.sort((a, b) => a.categoryName.compareTo(b.categoryName));
        break;
      case ProductSortOption.categoryDesc:
        products.sort((a, b) => b.categoryName.compareTo(a.categoryName));
        break;
      case ProductSortOption.stockAsc:
        products.sort((a, b) => a.totalStock.compareTo(b.totalStock));
        break;
      case ProductSortOption.stockDesc:
        products.sort((a, b) => b.totalStock.compareTo(a.totalStock));
        break;
      case ProductSortOption.expiryAsc:
        products.sort(_expiryAsc);
        break;
      case ProductSortOption.expiryDesc:
        products.sort((a, b) => _expiryAsc(b, a));
        break;
      case ProductSortOption.priceAsc:
        products.sort((a, b) => a.lowestPrice.compareTo(b.lowestPrice));
        break;
      case ProductSortOption.priceDesc:
        products.sort((a, b) => b.lowestPrice.compareTo(a.lowestPrice));
        break;
      case ProductSortOption.recent:
        products.sort((a, b) => b.addedOn.compareTo(a.addedOn));
        break;
    }
  }

  int _expiryAsc(ProductModel a, ProductModel b) {
    if (a.nearestExpiry.isEmpty) return 1;
    if (b.nearestExpiry.isEmpty) return -1;
    return a.nearestExpiry.compareTo(b.nearestExpiry);
  }
}
