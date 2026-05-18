import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
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

  // ── FILTERS ───────────────────────────────────────────────
  String _tier = 'all';
  // all | expired | urgent | standard | good | excellent | no_date
  String _catFilter = 'All';
  String _viewMode = 'list';
  String _sortBy = 'expiry-asc';
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

  // ── EXPIRY TIER HELPERS ───────────────────────────────────
  static String _tierLabel(String tier) {
    switch (tier) {
      case 'expired':
        return 'Expired';
      case 'urgent':
        return 'Urgent (<30d)';
      case 'standard':
        return 'Standard (1–3mo)';
      case 'good':
        return 'Good (3–6mo)';
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

  // ── ENTRIES BUILDER ───────────────────────────────────────
  List<Map<String, dynamic>> get _entries {
    final list = <Map<String, dynamic>>[];

    for (final product in _products) {
      if (_catFilter != 'All' && product.categoryName != _catFilter) continue;
      if (_search.isNotEmpty &&
          !product.name.toLowerCase().contains(_search.toLowerCase())) {
        continue;
      }

      for (final variant in product.variants) {
        // Collect all life indicators across batches
        final allIndicators = <LifeIndicator>[];
        for (final b in variant.batches) {
          allIndicators.addAll(b.indicators);
        }

        // Life indicator filter
        if (_liFilter != 'all') {
          final hasLi = allIndicators.any((i) => i.type == _liFilter);
          if (!hasLi) continue;
        }

        final expiry = variant.nearestExpiry;
        final tier = variant.expiryTier;

        // Tier filter
        if (_tier != 'all' && tier != _tier) continue;

        // Date range filter
        if (_dateRange != 'all' && expiry.isNotEmpty) {
          try {
            final expDt = DateTime.parse(expiry);
            final now = DateTime.now();
            bool pass = true;

            if (_selectedDate != null) {
              // Specific date
              pass =
                  expDt.year == _selectedDate!.year &&
                  expDt.month == _selectedDate!.month &&
                  expDt.day == _selectedDate!.day;
            } else {
              switch (_dateRange) {
                case 'today':
                  pass =
                      AppHelpers.expiryStatus(expiry) == 'expired' ||
                      AppHelpers.daysLeft(expiry) == 0;
                  break;
                case 'week':
                  pass = expDt.isBefore(now.add(const Duration(days: 7)));
                  break;
                case 'month':
                  pass = expDt.isBefore(now.add(const Duration(days: 30)));
                  break;
                case 'year':
                  pass = expDt.isBefore(now.add(const Duration(days: 365)));
                  break;
              }
            }
            if (!pass) continue;
          } catch (_) {}
        }

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

    // Sort
    list.sort((a, b) {
      final ae = a['expiry'] as String;
      final be = b['expiry'] as String;
      switch (_sortBy) {
        case 'expiry-desc':
          if (ae.isEmpty) return 1;
          if (be.isEmpty) return -1;
          return be.compareTo(ae);
        case 'a-z':
          return (a['product'] as ProductModel).name.compareTo(
            (b['product'] as ProductModel).name,
          );
        case 'z-a':
          return (b['product'] as ProductModel).name.compareTo(
            (a['product'] as ProductModel).name,
          );
        case 'cat-a-z':
          return (a['product'] as ProductModel).categoryName.compareTo(
            (b['product'] as ProductModel).categoryName,
          );
        case 'cat-z-a':
          return (b['product'] as ProductModel).categoryName.compareTo(
            (a['product'] as ProductModel).categoryName,
          );
        case 'stock-low':
          return (a['variant'] as VariantModel).totalStock.compareTo(
            (b['variant'] as VariantModel).totalStock,
          );
        case 'stock-high':
          return (b['variant'] as VariantModel).totalStock.compareTo(
            (a['variant'] as VariantModel).totalStock,
          );
        default: // expiry-asc
          if (ae.isEmpty) return 1;
          if (be.isEmpty) return -1;
          // Expired first, then nearest
          final at = a['tier'] as String;
          final bt = b['tier'] as String;
          if (at == 'expired' && bt != 'expired') return -1;
          if (bt == 'expired' && at != 'expired') return 1;
          return ae.compareTo(be);
      }
    });

    return list;
  }

  // ── TIER COUNTS ───────────────────────────────────────────
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

  // ── BUILD ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: buildAppBar(
        title: 'Expiry Tracker',
        context: context,
        actions: [
          // View mode
          PopupMenuButton<String>(
            icon: const Icon(Icons.view_module),
            onSelected: (v) => setState(() => _viewMode = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'list', child: Text('List')),
              PopupMenuItem(value: 'compact', child: Text('Compact')),
              PopupMenuItem(value: 'grid', child: Text('Grid')),
              PopupMenuItem(value: 'details', child: Text('Details')),
            ],
          ),
          // Sort
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (v) => setState(() => _sortBy = v),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'expiry-asc',
                child: Text('Expiry: Nearest First'),
              ),
              PopupMenuItem(
                value: 'expiry-desc',
                child: Text('Expiry: Furthest First'),
              ),
              PopupMenuItem(value: 'a-z', child: Text('Name A → Z')),
              PopupMenuItem(value: 'z-a', child: Text('Name Z → A')),
              PopupMenuItem(value: 'cat-a-z', child: Text('Category A → Z')),
              PopupMenuItem(value: 'cat-z-a', child: Text('Category Z → A')),
              PopupMenuItem(
                value: 'stock-low',
                child: Text('Stock: Low → High'),
              ),
              PopupMenuItem(
                value: 'stock-high',
                child: Text('Stock: High → Low'),
              ),
            ],
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

  // ── FILTERS ───────────────────────────────────────────────
}
