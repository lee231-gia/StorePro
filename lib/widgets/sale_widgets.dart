import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_helpers.dart';
import '../../models/sale_model.dart';
import '../../models/product_model.dart';
import '../../core/constants/app_icons.dart';
import '../../repositories/product_repository.dart';
import '../../repositories/sale_repository.dart';

// ── SALES TAB BUTTON ──────────────────────────────────────────
class SalesTabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const SalesTabButton({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? Colors.white : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white60,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

// ── CART ITEM MODEL (local, not persisted) ────────────────────
class CartItem {
  final String productId;
  final String variantId;
  final String productName;
  final String variantName;
  final String conditionName;
  double price;
  int qty;
  double costPrice;
  double itemDiscount; // per-item discount amount

  CartItem({
    required this.productId,
    required this.variantId,
    required this.productName,
    required this.variantName,
    this.conditionName = '',
    required this.price,
    this.qty = 1,
    this.costPrice = 0.0,
    this.itemDiscount = 0.0,
  });

  // Unique key for deduplication in cart
  String get key => '$productId|$variantId|$conditionName';

  double get subtotal => (price * qty) - itemDiscount;
  double get profit => (price - costPrice) * qty - itemDiscount;
}

// ── SUMMARY VIEW ──────────────────────────────────────────────
class SalesSummaryView extends StatefulWidget {
  const SalesSummaryView({super.key});

  @override
  State<SalesSummaryView> createState() => _SalesSummaryViewState();
}

class _SalesSummaryViewState extends State<SalesSummaryView> {
  List<SaleModel> _sales = [];
  List<ProductModel> _products = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    List<SaleModel> sales = [];
    List<ProductModel> products = [];
    try {
      final results = await Future.wait([
        SaleRepository.getAll(),
        ProductRepository.getAll(),
      ]).timeout(const Duration(seconds: 3));
      sales = results[0] as List<SaleModel>;
      products = results[1] as List<ProductModel>;
    } catch (_) {}
    if (mounted) {
      setState(() {
        _sales = sales;
        _products = products;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Today's stats
    final today = AppHelpers.todayStr();
    final todaySales = _sales.where((s) => s.date == today).toList();
    final todayRev = todaySales.fold(0.0, (sum, s) => sum + s.total);
    final todayProfit = todaySales.fold(0.0, (sum, s) => sum + s.profit);

    // Top sellers
    final Map<String, int> sold = {};
    for (final sale in _sales) {
      for (final item in sale.items) {
        sold[item.productName] = (sold[item.productName] ?? 0) + item.qty;
      }
    }
    final topList =
        (sold.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
            .take(5)
            .toList();

    return RefreshIndicator(
      color: kRed,
      onRefresh: () async => _load(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── TODAY CARD ─────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [kRed, kRedDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Today's Sales",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppHelpers.peso(todayRev),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '${todaySales.length} transaction'
                        '${todaySales.length != 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Profit: ${AppHelpers.peso(todayProfit)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Top Selling',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: kDark,
              ),
            ),
            const SizedBox(height: 10),

            if (topList.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text(
                    'No sales data yet.',
                    style: TextStyle(color: kGrey),
                  ),
                ),
              )
            else
              ...topList.asMap().entries.map((entry) {
                final rank = entry.key + 1;
                final name = entry.value.key;
                final qty = entry.value.value;
                final match = _products.where((p) => p.name == name).toList();
                final colorIndex = match.isNotEmpty
                    ? match.first.colorIndex
                    : 0;
                final color =
                    kCategoryColors[colorIndex.clamp(
                      0,
                      kCategoryColors.length - 1,
                    )];
                final icon = match.isNotEmpty
                    ? AppIcons.get(match.first.iconIndex)
                    : Icons.inventory_2_outlined;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Rank badge
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: rank == 1 ? kRed : kRedLight,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$rank',
                            style: TextStyle(
                              color: rank == 1 ? Colors.white : kRed,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 13,
                            color: kDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: kRedLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$qty sold',
                          style: const TextStyle(color: kRed, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

// ── HISTORY CARD ──────────────────────────────────────────────
class SalesHistoryCard extends StatelessWidget {
  final SaleModel sale;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const SalesHistoryCard({
    super.key,
    required this.sale,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Status color
    final statusColor = sale.status == 'refunded'
        ? kOrange
        : sale.status == 'partial'
        ? kOrange
        : kGreen;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            // ── HEADER ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sale.customerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              AppHelpers.formatDate(sale.date),
                              style: const TextStyle(
                                color: kGrey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (sale.employeeName.isNotEmpty)
                              Text(
                                'by ${sale.employeeName}',
                                style: const TextStyle(
                                  color: kGrey,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Status + total
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppHelpers.peso(sale.total),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: kRed,
                          fontSize: 15,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          sale.status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onDelete,
                    child: const Icon(
                      Icons.delete_outline,
                      color: kGrey,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            // ── ITEMS ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: sale.items
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item.productName} '
                                '(${item.variantName}'
                                '${item.conditionName.isNotEmpty ? '/${item.conditionName}' : ''}'
                                ') ×${item.qty}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: kGrey,
                                ),
                              ),
                            ),
                            Text(
                              AppHelpers.peso(item.subtotal),
                              style: const TextStyle(
                                fontSize: 12,
                                color: kGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
