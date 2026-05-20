import 'dart:async';

import 'package:flutter/material.dart';
import 'package:storepro/widgets/sale_widgets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/enums/product_browser_enums.dart';
import '../../core/utils/app_helpers.dart';
import '../../core/utils/session.dart';
import '../../core/services/sync_service.dart';
import '../../models/product_model.dart';
import '../../models/sale_model.dart';
import '../../models/utang_model.dart';
import '../../models/customer_model.dart';
import '../../repositories/product_repository.dart';
import '../../repositories/sale_repository.dart';
import '../../repositories/utang_repository.dart';
import '../../repositories/customer_repository.dart';
import '../../shared/controllers/product_browser_controller.dart';
import '../../shared/widgets/product_browser_toolbar.dart';
import '../../shared/widgets/product_browser_view.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/product_card.dart';
import '../../features/sales/services/sale_operations_service.dart';
import 'sales_sheets.dart';
import 'receipt_page.dart';

class SalesPage extends StatefulWidget {
  final Function(int) changeTab;
  final int currentIndex;

  const SalesPage({
    super.key,
    required this.changeTab,
    required this.currentIndex,
  });

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  // ── STATE ─────────────────────────────────────────────────
  int _tab = 0; // 0=new sale, 1=history
  bool _loading = true;
  late final ProductBrowserController _browser;

  List<ProductModel> _products = [];
  List<SaleModel> _sales = [];
  List<CustomerModel> _customers = [];
  List<String> _categories = ['All'];
  final List<CartItem> _cart = [];
  String _historyRange = 'all';
  DateTimeRange? _historyCustomRange;

  final _searchCtrl = TextEditingController();
  final _customerCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  StreamSubscription<String>? _changeSub;

  @override
  void initState() {
    super.initState();
    _browser = ProductBrowserController(
      viewMode: ProductViewMode.list,
      sortOption: ProductSortOption.nameAsc,
      groupVariants: false,
    )..addListener(_onBrowserChanged);
    _changeSub = SyncService.changes.listen((collection) {
      if (collection == 'products' || collection == 'sales') _load();
    });
    _load();
  }

  @override
  void dispose() {
    _changeSub?.cancel();
    _browser
      ..removeListener(_onBrowserChanged)
      ..dispose();
    _searchCtrl.dispose();
    _customerCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _onBrowserChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    List<ProductModel> products = [];
    List<SaleModel> sales = [];
    List<CustomerModel> customers = [];

    try {
      final results = await Future.wait([
        ProductRepository.getAll(),
        SaleRepository.getAll(),
        CustomerRepository.getAll(),
      ]).timeout(const Duration(seconds: 3));

      products = results[0] as List<ProductModel>;
      sales = results[1] as List<SaleModel>;
      customers = results[2] as List<CustomerModel>;
    } catch (_) {}

    if (mounted) {
      setState(() {
        _products = products;
        _sales = sales;
        _customers = customers;
        _categories = _categoryNames(products);
        _loading = false;
      });
    }

    // Background Firebase sync
    ProductRepository.syncInBackground((fresh) {
      if (mounted) {
        setState(() {
          _products = fresh;
          _categories = _categoryNames(fresh);
        });
      }
    });
    SaleRepository.syncInBackground((fresh) {
      if (mounted) setState(() => _sales = fresh);
    });
  }

  // ── CART COMPUTED ─────────────────────────────────────────
  double get _cartTotal => _cart.fold(0.0, (s, i) => s + i.subtotal);
  double get _discTotal => _cart.fold(0.0, (s, i) => s + i.itemDiscount);
  int get _cartCount => _cart.fold(0, (s, i) => s + i.qty);

  List<String> _categoryNames(List<ProductModel> products) =>
      {'All', ...products.map((product) => product.categoryName)}.toList();

  List<ProductDisplayItem> get _saleItems => _browser.displayItems(_products);
  bool get _showLegacySaleList => false;
  List<SaleModel> get _historySales {
    final now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    switch (_historyRange) {
      case 'today':
        start = DateTime(now.year, now.month, now.day);
        break;
      case 'week':
        start = DateTime(now.year, now.month, now.day).subtract(
          Duration(days: now.weekday - 1),
        );
        break;
      case 'month':
        start = DateTime(now.year, now.month);
        break;
      case 'year':
        start = DateTime(now.year);
        break;
      case 'custom':
        final range = _historyCustomRange;
        if (range == null) return _sales;
        start = DateTime(range.start.year, range.start.month, range.start.day);
        end = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59);
        break;
      default:
        return _sales;
    }
    return _sales.where((sale) {
      final dt = DateTime.tryParse(
        sale.timestamp.isNotEmpty ? sale.timestamp : sale.date,
      );
      if (dt == null) return false;
      return !dt.isBefore(start) && !dt.isAfter(end);
    }).toList();
  }

  // ── ADD TO CART ───────────────────────────────────────────
  void _addToCart(CartItem item) {
    setState(() {
      final index = _cart.indexWhere((c) => c.key == item.key);
      if (index >= 0) {
        _cart[index].qty++;
      } else {
        _cart.add(item);
      }
    });
  }

  void _changeQty(int index, int delta) {
    setState(() {
      final newQty = _cart[index].qty + delta;
      if (newQty <= 0) {
        _cart.removeAt(index);
      } else {
        _cart[index].qty = newQty;
      }
    });
  }

  void _removeItem(int index) {
    setState(() => _cart.removeAt(index));
  }

  void _setItemDiscount(int index, double disc) {
    setState(() {
      final maxDiscount = _cart[index].price * _cart[index].qty;
      _cart[index].itemDiscount = disc.clamp(0, maxDiscount).toDouble();
    });
  }

  // ── VARIANT PICKER SHORTCUT ───────────────────────────────
  void _showVariantPicker(ProductModel product) {
    final variants = product.variants;
    if (variants.isEmpty) return;

    // Shortcut: 1 variant, no conditions → add directly
    if (variants.length == 1 && variants.first.conditions.isEmpty) {
      _addToCart(
        CartItem(
          productId: product.id,
          variantId: variants.first.id,
          productName: product.name,
          variantName: variants.first.name,
          imageUrl: variants.first.imageUrl.isNotEmpty
              ? variants.first.imageUrl
              : product.imageUrl,
          iconIndex: product.iconIndex,
          colorIndex: product.colorIndex,
          price: variants.first.price,
          costPrice: variants.first.costPrice,
        ),
      );
      return;
    }

    showVariantPickerSheet(
      context: context,
      product: product,
      onAdd: _addToCart,
    );
  }

  void _selectProductItem(ProductDisplayItem item) {
    final variant = item.variant;
    if (variant != null && variant.conditions.isEmpty) {
      if (variant.totalStock <= 0) return;
      _addToCart(
        CartItem(
          productId: item.product.id,
          variantId: variant.id,
          productName: item.product.name,
          variantName: variant.name,
          imageUrl: variant.imageUrl.isNotEmpty
              ? variant.imageUrl
              : item.product.imageUrl,
          iconIndex: item.product.iconIndex,
          colorIndex: item.product.colorIndex,
          price: variant.price,
          costPrice: variant.costPrice,
        ),
      );
      return;
    }
    if (item.totalStock > 0) _showVariantPicker(item.product);
  }

  // ── OPEN CART ─────────────────────────────────────────────
  void _openCart() {
    showCartSheet(
      context: context,
      cart: _cart,
      customerCtrl: _customerCtrl,
      notesCtrl: _notesCtrl,
      customers: _customers,
      onChangeQty: _changeQty,
      onRemove: _removeItem,
      onItemDiscount: _setItemDiscount,
      onConfirm: _openPayment,
    );
  }

  // ── PAYMENT FLOW ──────────────────────────────────────────
  void _openPayment() {
    showPaymentSheet(
      context: context,
      total: _cartTotal,
      customerCtrl: _customerCtrl,
      customers: _customers,
      onPay:
          ({
            required String paymentType,
            required double amountPaid,
            required double change,
            required String customerId,
            required String customerPhone,
            required String customerAddress,
          }) async {
            await _completeSale(
              paymentType: paymentType,
              amountPaid: amountPaid,
              change: change,
              customerId: customerId,
              customerName: _customerCtrl.text.trim().isEmpty
                  ? 'Walk-in'
                  : _customerCtrl.text.trim(),
              customerPhone: customerPhone,
              customerAddress: customerAddress,
            );
          },
    );
  }

  // ── COMPLETE SALE ─────────────────────────────────────────
  Future<void> _completeSale({
    required String paymentType,
    required double amountPaid,
    required double change,
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String customerAddress,
  }) async {
    if (_cart.isEmpty) return;

    // Build sale items
    final items = _cart
        .map(
          (c) => SaleItemModel(
            productId: c.productId,
            productName: c.productName,
            variantId: c.variantId,
            variantName: c.variantName,
            conditionName: c.conditionName,
            qty: c.qty,
            price: c.price,
            costPrice: c.costPrice,
            discount: c.itemDiscount,
          ),
        )
        .toList();

    // Build sale record
    final sale = SaleModel(
      id: '',
      storeId: Session.storeId,
      customerId: customerId,
      customerName: customerName,
      employeeId: Session.safeEmployeeId,
      employeeName: Session.safeEmployeeName,
      items: items,
      subtotal: _cartTotal + _discTotal,
      totalDiscount: _discTotal,
      total: _cartTotal,
      amountPaid: amountPaid,
      change: change,
      paymentType: paymentType,
      status: paymentType == 'utang' ? 'partial' : 'completed',
      notes: _notesCtrl.text.trim(),
      date: AppHelpers.todayStr(),
      timestamp: AppHelpers.nowStr(),
      updatedAt: AppHelpers.nowStr(),
    );

    // Save sale
    final saved = await SaleRepository.save(sale);

    // Deduct stock (FIFO) for each item
    for (final item in _cart) {
      await ProductRepository.deductFifo(
        item.productId,
        item.variantId,
        item.qty,
      );
    }

    // If utang or multi — create debt record
    if (paymentType == 'utang' ||
        (paymentType == 'multi' && amountPaid < _cartTotal)) {
      // Save/find customer
      final custList = await CustomerRepository.getAll();
      CustomerModel? customer =
          custList.where((c) => c.name == customerName).isNotEmpty
          ? custList.firstWhere((c) => c.name == customerName)
          : null;

      customer ??= await CustomerRepository.save(
        CustomerModel(
          id: '',
          storeId: Session.storeId,
          name: customerName,
          phone: customerPhone,
          address: customerAddress,
          createdAt: AppHelpers.nowStr(),
          updatedAt: AppHelpers.nowStr(),
        ),
      );

      final paidSoFar = paymentType == 'multi' ? amountPaid : 0.0;
      final utang = UtangModel(
        id: '',
        storeId: Session.storeId,
        customerId: customer.id,
        customerName: customerName,
        customerPhone: customerPhone,
        saleId: saved.id,
        items: _cart
            .map(
              (c) => {
                'productId': c.productId,
                'productName': c.productName,
                'variantId': c.variantId,
                'variantName': c.variantName,
                'conditionName': c.conditionName,
                'qty': c.qty,
                'price': c.price,
              },
            )
            .toList(),
        totalAmount: _cartTotal,
        amountPaid: paidSoFar,
        startDate: AppHelpers.todayStr(),
        status: paidSoFar >= _cartTotal
            ? 'paid'
            : paidSoFar > 0
            ? 'partial'
            : 'pending',
        updatedAt: AppHelpers.nowStr(),
      );
      await UtangRepository.save(utang);

      // Update customer total purchases
      await CustomerRepository.addPurchase(customer.id, _cartTotal);
    } else {
      // Cash sale — update customer if named
      if (customerName != 'Walk-in') {
        final custList = await CustomerRepository.getAll();
        final match = custList.where((c) => c.name == customerName).toList();
        if (match.isNotEmpty) {
          await CustomerRepository.addPurchase(match.first.id, _cartTotal);
        }
      }
    }

    if (!mounted) return;

    // Clear cart
    setState(() {
      _cart.clear();
      _customerCtrl.clear();
      _notesCtrl.clear();
    });

    // Reload sales
    await _load();

    // Show receipt
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ReceiptPage(sale: saved)),
      );
    }
  }

  // ── BUILD ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: buildAppBar(
        title: 'Sales',
        context: context,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Row(
            children: [
              SalesTabButton(
                label: 'New Sale',
                isActive: _tab == 0,
                onTap: () => setState(() => _tab = 0),
              ),
              SalesTabButton(
                label: 'History',
                isActive: _tab == 1,
                onTap: () => setState(() => _tab = 1),
              ),
            ],
          ),
        ),
      ),
      drawer: AppDrawer(
        changeTab: widget.changeTab,
        currentIndex: widget.currentIndex,
      ),
      floatingActionButton: _tab == 1
          ? FloatingActionButton.small(
              heroTag: 'sales_add_fab',
              backgroundColor: kRed,
              foregroundColor: Colors.white,
              onPressed: () => setState(() => _tab = 0),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(color: kRed),
          Expanded(child: [_buildNewSale(), _buildHistory()][_tab]),
        ],
      ),
    );
  }

  // ── NEW SALE VIEW ─────────────────────────────────────────
  Widget _buildNewSale() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: ProductBrowserToolbar(
            controller: _browser,
            searchController: _searchCtrl,
            categories: _categories,
            searchHint: 'Search products...',
            itemCount: _saleItems.length,
            sortOptions: const [
              ProductSortOption.nameAsc,
              ProductSortOption.nameDesc,
              ProductSortOption.categoryAsc,
              ProductSortOption.categoryDesc,
              ProductSortOption.stockDesc,
              ProductSortOption.stockAsc,
              ProductSortOption.priceAsc,
              ProductSortOption.priceDesc,
            ],
          ),
        ),

        // Cart bar
        if (_cart.isNotEmpty)
          GestureDetector(
            onTap: _openCart,
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: kRed,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$_cartCount item'
                      '${_cartCount != 1 ? 's' : ''} in cart',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  Text(
                    AppHelpers.peso(_cartTotal),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.keyboard_arrow_up,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

        Expanded(
          child: ProductBrowserView(
            items: _saleItems,
            viewMode: _browser.viewMode,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            onTap: _selectProductItem,
            enabledBuilder: (item) => item.totalStock > 0,
            trailingBuilder: _saleTrailing,
            actionBuilder: _saleAction,
            gridFooterBuilder: _saleGridFooter,
          ),
        ),
        if (_showLegacySaleList)
          Expanded(
            child: _saleItems.isEmpty
                ? const Center(
                    child: Text(
                      'No products found.',
                      style: TextStyle(color: kGrey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _saleItems.length,
                    itemBuilder: (_, i) {
                      final item = _saleItems[i];
                      final p = item.product;
                      final stock = item.totalStock;
                      final color =
                          kCategoryColors[p.colorIndex.clamp(
                            0,
                            kCategoryColors.length - 1,
                          )];

                      return GestureDetector(
                        onTap: stock > 0
                            ? () => _selectProductItem(item)
                            : null,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
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
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  AppIcons.get(p.iconIndex),
                                  color: color,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: kDark,
                                      ),
                                    ),
                                    Text(
                                      '${item.isVariant ? 'Variant' : '${p.variants.length} variant${p.variants.length != 1 ? 's' : ''}'}'
                                      '  ·  $stock pcs',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppHelpers.stockColor(stock),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              stock == 0
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: kRedLight,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'No Stock',
                                        style: TextStyle(
                                          color: kRed,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.add_circle_outline,
                                      color: kRed,
                                      size: 22,
                                    ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
      ],
    );
  }

  // ── HISTORY VIEW ──────────────────────────────────────────
  Widget _saleTrailing(ProductDisplayItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppHelpers.peso(item.price),
          style: const TextStyle(
            color: kRed,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 2),
        item.totalStock == 0
            ? const ProductActionPill(
                icon: Icons.block_outlined,
                label: 'No Stock',
                color: kRed,
              )
            : const Icon(Icons.add_circle_outline, color: kRed, size: 22),
      ],
    );
  }

  Widget _saleAction(ProductDisplayItem item) {
    return ProductActionPill(
      icon: item.totalStock == 0 ? Icons.block_outlined : Icons.add,
      label: item.totalStock == 0 ? 'No Stock' : 'Add',
      color: kRed,
    );
  }

  Widget _saleGridFooter(ProductDisplayItem item) {
    return Row(
      children: [
        Expanded(
          child: Text(
            AppHelpers.peso(item.price),
            style: const TextStyle(
              color: kRed,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '${item.totalStock} pcs',
          style: TextStyle(
            color: AppHelpers.stockColor(item.totalStock),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildHistory() {
    final sales = _historySales;
    if (_sales.isEmpty) {
      return const Center(
        child: Text('No sales yet.', style: TextStyle(color: kGrey)),
      );
    }

    return RefreshIndicator(
      color: kRed,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sales.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) return _historyFilterBar(sales.length);
          final sale = sales[i - 1];
          return SalesHistoryCard(
            sale: sale,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ReceiptPage(sale: sale)),
            ),
            onEdit: sale.status == 'refunded' ? null : () => _editSale(sale),
            onRefund: sale.status == 'refunded'
                ? null
                : () => _confirmRefund(sale),
            onDelete: () => _confirmDelete(sale),
          );
        },
      ),
    );
  }

  Widget _historyFilterBar(int count) {
    final chips = {
      'all': 'All',
      'today': 'Today',
      'week': 'Week',
      'month': 'Month',
      'year': 'Year',
      'custom': 'Custom',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: chips.entries.map((entry) {
                  final active = _historyRange == entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () async {
                        if (entry.key == 'custom') {
                          final now = DateTime.now();
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2040),
                            initialDateRange: _historyCustomRange ??
                                DateTimeRange(start: now, end: now),
                          );
                          if (picked == null) return;
                          setState(() {
                            _historyCustomRange = picked;
                            _historyRange = 'custom';
                          });
                          return;
                        }
                        setState(() {
                          _historyRange = entry.key;
                          if (entry.key != 'custom') _historyCustomRange = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: active ? kRed : kCard,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: active ? kRed : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            color: active ? Colors.white : kGrey,
                            fontSize: 11,
                            fontWeight:
                                active ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Text('$count', style: const TextStyle(color: kGrey, fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _confirmRefund(SaleModel sale) async {
    final reasonCtrl = TextEditingController(text: 'Customer refund');
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Refund Sale?'),
        content: TextField(
          controller: reasonCtrl,
          decoration: AppInput.dialog('Refund reason'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, reasonCtrl.text.trim()),
            child: const Text('Refund', style: TextStyle(color: kRed)),
          ),
        ],
      ),
    );
    reasonCtrl.dispose();
    if (reason == null || reason.trim().isEmpty || !mounted) return;
    await SaleOperationsService.refundSale(sale, reason: reason);
    await _load();
  }

  Future<void> _editSale(SaleModel sale) async {
    final customerCtrl = TextEditingController(text: sale.customerName);
    final paidCtrl = TextEditingController(
      text: sale.amountPaid.toStringAsFixed(2),
    );
    final notesCtrl = TextEditingController(text: sale.notes);
    final reasonCtrl = TextEditingController(text: 'Sale correction');
    var paymentType = sale.paymentType;
    final editedItems = sale.items.toList();
    final qtyCtrls = sale.items
        .map((item) => TextEditingController(text: item.qty.toString()))
        .toList();
    final priceCtrls = sale.items
        .map(
          (item) => TextEditingController(text: item.price.toStringAsFixed(2)),
        )
        .toList();
    final discountCtrls = sale.items
        .map(
          (item) =>
              TextEditingController(text: item.discount.toStringAsFixed(2)),
        )
        .toList();

    SaleModel? result;
    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setD) {
          double subtotal = 0;
          double discount = 0;
          final currentItems = <SaleItemModel>[];
          for (var i = 0; i < editedItems.length; i++) {
            final qty = int.tryParse(qtyCtrls[i].text.trim()) ?? 0;
            final price = double.tryParse(priceCtrls[i].text.trim()) ?? 0;
            final disc = double.tryParse(discountCtrls[i].text.trim()) ?? 0;
            if (qty <= 0) continue;
            final item = editedItems[i].copyWith(
              qty: qty,
              price: price,
              discount: disc,
            );
            currentItems.add(item);
            subtotal += price * qty;
            discount += disc;
          }
          final total = (subtotal - discount)
              .clamp(0, double.infinity)
              .toDouble();

          return AlertDialog(
            title: const Text('Edit Sale'),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: customerCtrl,
                      decoration: AppInput.dialog('Customer name'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: paymentType,
                      decoration: AppInput.dialog('Payment type'),
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('Cash')),
                        DropdownMenuItem(value: 'utang', child: Text('Utang')),
                        DropdownMenuItem(value: 'multi', child: Text('Multi')),
                      ],
                      onChanged: (value) {
                        if (value != null) setD(() => paymentType = value);
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: paidCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setD(() {}),
                      decoration: AppInput.dialog('Amount paid'),
                    ),
                    const SizedBox(height: 12),
                    ...editedItems.asMap().entries.map((entry) {
                      final i = entry.key;
                      final item = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: kBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.productName} - ${item.variantName}'
                                    '${item.conditionName.isNotEmpty ? ' / ${item.conditionName}' : ''}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: kRed,
                                    size: 18,
                                  ),
                                  onPressed: () => setD(() {
                                    editedItems.removeAt(i);
                                    qtyCtrls.removeAt(i).dispose();
                                    priceCtrls.removeAt(i).dispose();
                                    discountCtrls.removeAt(i).dispose();
                                  }),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: qtyCtrls[i],
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setD(() {}),
                                    decoration: AppInput.dialog('Qty'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: priceCtrls[i],
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setD(() {}),
                                    decoration: AppInput.dialog('Price'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: discountCtrls[i],
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setD(() {}),
                                    decoration: AppInput.dialog('Discount'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: kRedLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          infoRow('Subtotal', AppHelpers.peso(subtotal)),
                          infoRow('Discount', AppHelpers.peso(discount)),
                          infoRow('Total', AppHelpers.peso(total)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: AppInput.dialog('Notes'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: reasonCtrl,
                      decoration: AppInput.dialog('Edit reason'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: currentItems.isEmpty
                    ? null
                    : () {
                        final paid =
                            double.tryParse(paidCtrl.text.trim()) ??
                            sale.amountPaid;
                        result = sale.copyWith(
                          customerName: customerCtrl.text.trim().isEmpty
                              ? 'Walk-in'
                              : customerCtrl.text.trim(),
                          items: currentItems,
                          subtotal: subtotal,
                          totalDiscount: discount,
                          total: total,
                          amountPaid: paid,
                          change: paid > total ? paid - total : 0,
                          paymentType: paymentType,
                          notes: notesCtrl.text.trim(),
                        );
                        Navigator.pop(ctx);
                      },
                child: const Text('Save', style: TextStyle(color: kRed)),
              ),
            ],
          );
        },
      ),
    );

    for (final ctrl in [...qtyCtrls, ...priceCtrls, ...discountCtrls]) {
      ctrl.dispose();
    }
    final reason = reasonCtrl.text.trim().isEmpty
        ? 'Sale correction'
        : reasonCtrl.text.trim();
    customerCtrl.dispose();
    paidCtrl.dispose();
    notesCtrl.dispose();
    reasonCtrl.dispose();

    final edited = result;
    if (edited == null || !mounted) return;
    await SaleOperationsService.editSale(
      original: sale,
      edited: edited,
      reason: reason,
    );
    await _load();
  }

  Future<void> _confirmDelete(SaleModel sale) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Sale?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: kRed)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      if (sale.status != 'refunded') {
        await SaleOperationsService.refundSale(
          sale,
          reason: 'Sale record deleted',
        );
      }
      await SaleRepository.delete(sale.id);
      _load();
    }
  }
}
