import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/enums/product_browser_enums.dart';
import '../../core/utils/app_helpers.dart';
import '../../models/product_model.dart';
import '../../repositories/product_repository.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/product_card.dart';

part 'expiry_filters.dart';
part 'expiry_content.dart';
part 'expiry_cards.dart';

class ExpiryPage extends StatefulWidget {
  final Function(int) changeTab;
  final int currentIndex;

  const ExpiryPage({
    super.key,
    required this.changeTab,
    required this.currentIndex,
  });

  @override
  State<ExpiryPage> createState() => _ExpiryPageState();
}

class _ExpiryPageState extends State<ExpiryPage> {
  List<ProductModel> _products = [];
  bool _loading = true;

  // â”€â”€ FILTERS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  String _tier = 'all';
  // all | expired | urgent | standard | good | excellent | no_date
  String _catFilter = 'All';
  ProductViewMode _viewMode = ProductViewMode.list;
  ProductSortOption _sortBy = ProductSortOption.expiryAsc;
  String _search = '';
  String _liFilter = 'all'; // product life indicator filter
  List<String> _categories = ['All'];
  DateTime? _selectedDate; // calendar date filter
  String _dateRange = 'all';
  // all | today | week | month | year | custom

  final _searchCtrl = TextEditingController();

  void _update(VoidCallback fn) => setState(fn);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    var products = _products;
    try {
      products = await ProductRepository.getAll().timeout(
        const Duration(seconds: 3),
        onTimeout: () => <ProductModel>[],
      );
    } catch (_) {}
    final cats = <String>{'All'};
    for (final p in products) {
      cats.add(p.categoryName);
    }
    if (mounted) {
      setState(() {
        _products = products;
        _categories = cats.toList();
        _loading = false;
      });
    }
    ProductRepository.syncInBackground((fresh) {
      if (!mounted) return;
      final c = <String>{'All'};
      for (final p in fresh) {
        c.add(p.categoryName);
      }
      setState(() {
        _products = fresh;
        _categories = c.toList();
      });
    });
  }

  // â”€â”€ EXPIRY TIER HELPERS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static String _tierLabel(String tier) {
    switch (tier) {
      case 'expired':
        return 'Expired';
      case 'urgent':
        return 'Urgent (<30d)';
      case 'standard':
        return 'Standard (1-3mo)';
      case 'good':
        return 'Good (3-6mo)';
      case 'excellent':
        return 'Excellent (6mo+)';
      case 'no_date':
        return 'No Date';
      default:
        return 'All';
    }
  }

  static Color _tierColor(String tier) {
    switch (tier) {
      case 'expired':
        return kRed;
      case 'urgent':
        return const Color(0xFFE53935);
      case 'standard':
        return kOrange;
      case 'good':
        return const Color(0xFF43A047);
      case 'excellent':
        return kGreen;
      default:
        return kGrey;
    }
  }

  static IconData _tierIcon(String tier) {
    switch (tier) {
      case 'expired':
        return Icons.dangerous_outlined;
      case 'urgent':
        return Icons.warning_amber_outlined;
      case 'standard':
        return Icons.schedule_outlined;
      case 'good':
        return Icons.check_circle_outline;
      case 'excellent':
        return Icons.verified_outlined;
      default:
        return Icons.event_outlined;
    }
  }

  // â”€â”€ ENTRIES BUILDER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  List<Map<String, dynamic>> get _entries {
    final list = <Map<String, dynamic>>[];
    for (final product in _products) {
      if (_catFilter != 'All' && product.categoryName != _catFilter) continue;
      if (_search.isNotEmpty &&
          !product.name.toLowerCase().contains(_search.toLowerCase())) {
        continue;
      }
      for (final variant in product.variants) {
        final allIndicators = <LifeIndicator>[];
        for (final b in variant.batches) {
          allIndicators.addAll(b.indicators);
        }
        if (_liFilter != 'all' &&
            !allIndicators.any((i) => i.type == _liFilter)) {
          continue;
        }

        final expiry = variant.nearestExpiry;
        final tier = variant.expiryTier;
        if (_tier != 'all' && tier != _tier) continue;
        if (!_passesDateRange(expiry)) continue;

        list.add({
          'product': product,
          'variant': variant,
          'expiry': expiry,
          'tier': tier,
          'days': AppHelpers.daysLeft(expiry),
          'indicators': allIndicators,
        });
      }
    }
    list.sort(_compareEntries);
    return list;
  }

  bool _passesDateRange(String expiry) {
    if (_dateRange == 'all' || expiry.isEmpty) return true;
    try {
      final expDt = DateTime.parse(expiry);
      final now = DateTime.now();
      if (_selectedDate != null) {
        return expDt.year == _selectedDate!.year &&
            expDt.month == _selectedDate!.month &&
            expDt.day == _selectedDate!.day;
      }
      switch (_dateRange) {
        case 'today':
          return AppHelpers.expiryStatus(expiry) == 'expired' ||
              AppHelpers.daysLeft(expiry) == 0;
        case 'week':
          return expDt.isBefore(now.add(const Duration(days: 7)));
        case 'month':
          return expDt.isBefore(now.add(const Duration(days: 30)));
        case 'year':
          return expDt.isBefore(now.add(const Duration(days: 365)));
        default:
          return true;
      }
    } catch (_) {
      return true;
    }
  }

  int _compareEntries(Map<String, dynamic> a, Map<String, dynamic> b) {
    final ae = a['expiry'] as String;
    final be = b['expiry'] as String;
    switch (_sortBy) {
      case ProductSortOption.expiryDesc:
        if (ae.isEmpty) return 1;
        if (be.isEmpty) return -1;
        return be.compareTo(ae);
      case ProductSortOption.nameAsc:
        return (a['product'] as ProductModel).name.compareTo(
          (b['product'] as ProductModel).name,
        );
      case ProductSortOption.nameDesc:
        return (b['product'] as ProductModel).name.compareTo(
          (a['product'] as ProductModel).name,
        );
      case ProductSortOption.categoryAsc:
        return (a['product'] as ProductModel).categoryName.compareTo(
          (b['product'] as ProductModel).categoryName,
        );
      case ProductSortOption.categoryDesc:
        return (b['product'] as ProductModel).categoryName.compareTo(
          (a['product'] as ProductModel).categoryName,
        );
      case ProductSortOption.stockAsc:
        return (a['variant'] as VariantModel).totalStock.compareTo(
          (b['variant'] as VariantModel).totalStock,
        );
      case ProductSortOption.stockDesc:
        return (b['variant'] as VariantModel).totalStock.compareTo(
          (a['variant'] as VariantModel).totalStock,
        );
      case ProductSortOption.recent:
      case ProductSortOption.priceAsc:
      case ProductSortOption.expiryAsc:
        if (ae.isEmpty) return 1;
        if (be.isEmpty) return -1;
        final at = a['tier'] as String;
        final bt = b['tier'] as String;
        if (at == 'expired' && bt != 'expired') return -1;
        if (bt == 'expired' && at != 'expired') return 1;
        return ae.compareTo(be);
    }
  }

  // â”€â”€ TIER COUNTS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Map<String, int> get _tierCounts {
    final counts = {
      'expired': 0,
      'urgent': 0,
      'standard': 0,
      'good': 0,
      'excellent': 0,
      'no_date': 0,
    };
    for (final p in _products) {
      for (final v in p.variants) {
        final t = v.expiryTier;
        counts[t] = (counts[t] ?? 0) + 1;
      }
    }
    return counts;
  }

  // â”€â”€ BUILD â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: buildAppBar(
        title: 'Expiry Tracker',
        context: context,
        actions: [
          PopupMenuButton<ProductViewMode>(
            icon: const Icon(Icons.view_module),
            onSelected: (v) => setState(() => _viewMode = v),
            itemBuilder: (_) => ProductViewMode.values
                .map(
                  (mode) => PopupMenuItem(value: mode, child: Text(mode.label)),
                )
                .toList(),
          ),
          PopupMenuButton<ProductSortOption>(
            icon: const Icon(Icons.sort),
            onSelected: (v) => setState(() => _sortBy = v),
            itemBuilder: (_) => ProductSortOption.values
                .where((option) => option != ProductSortOption.priceAsc)
                .map(
                  (option) =>
                      PopupMenuItem(value: option, child: Text(option.label)),
                )
                .toList(),
          ),
        ],
      ),
      drawer: AppDrawer(
        changeTab: widget.changeTab,
        currentIndex: widget.currentIndex,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kRed))
          : Column(
              children: [
                _buildFilters(),
                _buildTierStrip(),
                _buildDateRangeBar(),
                Expanded(child: _buildContent()),
              ],
            ),
    );
  }

  // â”€â”€ FILTERS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
}
