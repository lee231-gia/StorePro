import 'dart:async';
import 'package:flutter/material.dart';
import 'package:storepro/widgets/sale_widgets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/enums/product_browser_enums.dart';
import '../../core/utils/app_helpers.dart';
import '../../core/utils/session.dart';
import '../../core/services/sync_service.dart';
import '../../features/sales/services/sale_operations_service.dart';
import '../../models/product_model.dart';
import '../../models/sale_model.dart';
import '../../models/utang_model.dart';
import '../../repositories/product_repository.dart';
import '../../repositories/sale_repository.dart';
import '../../repositories/utang_repository.dart';
import '../../shared/controllers/product_browser_controller.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/employee_picker.dart';
import '../../widgets/product_card.dart';
import 'sales_sheets.dart';
import 'receipt_page.dart';
part 'sales_history.dart';

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
  String _search = '', _sortBy = 'a-z';
  String _catFilter = 'All';
  bool _groupVariants = false;
  bool _loading = true;

  List<ProductModel> _products = [];
  List<String> _categories = ['All'];
  List<SaleModel> _sales = [];
  final List<CartItem> _cart = [];

  final _searchCtrl = TextEditingController();
  final _customerCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  late final ProductBrowserController _browser;
  StreamSubscription<String>? _changeSub;

  @override
  void initState() {
    super.initState();
    _browser = ProductBrowserController(
      sortOption: ProductSortOption.nameAsc,
      groupVariants: _groupVariants,
    );
    _changeSub = SyncService.changes.listen((collection) {
      if (collection == 'products' || collection == 'sales') _load();
    });
    _load();
  }

  @override
  void dispose() {
    _changeSub?.cancel();
    _browser.dispose();
    _searchCtrl.dispose();
    _customerCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    List<ProductModel> products = [];
    List<SaleModel> sales = [];

    try {
      final results = await Future.wait([
        ProductRepository.getAll(),
        SaleRepository.getAll(),
      ]).timeout(const Duration(seconds: 3));

      products = results[0] as List<ProductModel>;
      sales = results[1] as List<SaleModel>;
    } catch (_) {}

    if (mounted) {
      setState(() {
        _products = products;
        _categories = [
          'All',
          ...products
              .map((p) => p.categoryName)
              .where((c) => c.isNotEmpty)
              .toSet(),
        ];
        _sales = sales;
        _loading = false;
      });
    }

    // Background Firebase sync
    ProductRepository.syncInBackground((fresh) {
      if (mounted) setState(() => _products = fresh);
    });
    SaleRepository.syncInBackground((fresh) {
      if (mounted) setState(() => _sales = fresh);
    });
  }

  // ── CART COMPUTED ─────────────────────────────────────────
  double get _cartTotal => _cart.fold(0.0, (s, i) => s + i.subtotal);
  double get _discTotal => _cart.fold(0.0, (s, i) => s + i.itemDiscount);
  int get _cartCount => _cart.fold(0, (s, i) => s + i.qty);

  List<ProductModel> get _searchResults {
    _browser
      ..search = _search
      ..categoryFilter = _catFilter
      ..sortOption = ProductSortOption.fromValue(_sortBy)
      ..groupVariants = _groupVariants;
    return _browser.apply(_products);
  }

  List<ProductDisplayItem> get _saleItems => ProductDisplayItem.fromProducts(
    _searchResults,
    groupVariants: _groupVariants,
  );

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
    setState(() => _cart[index].itemDiscount = disc);
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
      onPay:
          ({
            required String paymentType,
            required double amountPaid,
            required double change,
            required String customerId,
            required String customerPhone,
            required String customerAddress,
          }) async {
            final ok = await pickEmployee(context);
            if (!ok || !mounted) return;

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
    final linkedCustomer = await SaleOperationsService.linkCustomerPurchase(
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      amount: _cartTotal,
    );

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
      final paidSoFar = paymentType == 'multi' ? amountPaid : 0.0;
      final utang = UtangModel(
        id: '',
        storeId: Session.storeId,
        customerId: linkedCustomer?.id ?? customerId,
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
    } else {
      // Cash sale — update customer if named
      if (customerName != 'Walk-in') {}
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
        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _search = v),
                      decoration: AppInput.field(
                        'Search product...',
                        icon: Icons.search,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.sort, color: kGrey),
                    onSelected: (v) => setState(() => _sortBy = v),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'a-z', child: Text('Name A-Z')),
                      PopupMenuItem(value: 'z-a', child: Text('Name Z-A')),
                      PopupMenuItem(
                        value: 'stock-high',
                        child: Text('Stock: High-Low'),
                      ),
                      PopupMenuItem(
                        value: 'stock-low',
                        child: Text('Stock: Low-High'),
                      ),
                      PopupMenuItem(
                        value: 'price-low',
                        child: Text('Price: Low-High'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 30,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (_, i) {
                    final category = _categories[i];
                    final active = _catFilter == category;
                    return GestureDetector(
                      onTap: () => setState(() => _catFilter = category),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: active ? kRed : kCard,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: active ? kRed : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 11,
                            color: active ? Colors.white : kGrey,
                            fontWeight: active
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Row(
                children: [
                  VariantToggleButton(
                    grouped: _groupVariants,
                    onChanged: (value) =>
                        setState(() => _groupVariants = value),
                  ),
                  const Spacer(),
                  Text(
                    '${_saleItems.length} item'
                    '${_saleItems.length != 1 ? 's' : ''}',
                    style: const TextStyle(color: kGrey, fontSize: 12),
                  ),
                ],
              ),
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

        // Product list
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
                      onTap: stock > 0 ? () => _selectProductItem(item) : null,
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
}
