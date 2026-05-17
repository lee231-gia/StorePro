import 'dart:async';

import 'package:flutter/material.dart';
import 'package:storepro/widgets/sale_widgets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/utils/app_helpers.dart';
import '../../core/utils/session.dart';
import '../../core/services/sync_service.dart';
import '../../models/product_model.dart';
import '../../models/sale_model.dart';
import '../../models/utang_model.dart';
import '../../models/customer_model.dart';
import '../../models/inventory_model.dart';
import '../../repositories/product_repository.dart';
import '../../repositories/sale_repository.dart';
import '../../repositories/utang_repository.dart';
import '../../repositories/customer_repository.dart';
import '../../repositories/inventory_repository.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/employee_picker.dart';
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
  int _tab = 0; // 0=summary, 1=new sale, 2=history
  String _search = '';
  bool _loading = true;

  List<ProductModel> _products = [];
  List<SaleModel> _sales = [];
  final List<CartItem> _cart = [];

  final _searchCtrl = TextEditingController();
  final _customerCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  StreamSubscription<String>? _changeSub;

  @override
  void initState() {
    super.initState();
    _changeSub = SyncService.changes.listen((collection) {
      if (collection == 'products' || collection == 'sales') _load();
    });
    _load();
  }

  @override
  void dispose() {
    _changeSub?.cancel();
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
    if (_search.trim().isEmpty) return _products;
    return _products
        .where((p) => p.name.toLowerCase().contains(_search.toLowerCase()))
        .toList();
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
      employeeId: Session.activeEmployeeId,
      employeeName: Session.activeEmployeeName,
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
                label: 'Summary',
                isActive: _tab == 0,
                onTap: () => setState(() => _tab = 0),
              ),
              SalesTabButton(
                label: 'New Sale',
                isActive: _tab == 1,
                onTap: () => setState(() => _tab = 1),
              ),
              SalesTabButton(
                label: 'History',
                isActive: _tab == 2,
                onTap: () => setState(() => _tab = 2),
              ),
            ],
          ),
        ),
      ),
      drawer: AppDrawer(
        changeTab: widget.changeTab,
        currentIndex: widget.currentIndex,
      ),
      floatingActionButton: _tab == 0
          ? FloatingActionButton.small(
              heroTag: 'sales_add_fab',
              backgroundColor: kRed,
              foregroundColor: Colors.white,
              onPressed: () => setState(() => _tab = 1),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(color: kRed),
          Expanded(
            child: [
              const SalesSummaryView(),
              _buildNewSale(),
              _buildHistory(),
            ][_tab],
          ),
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
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _search = v),
            decoration: AppInput.field('Search product...', icon: Icons.search),
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
          child: _searchResults.isEmpty
              ? const Center(
                  child: Text(
                    'No products found.',
                    style: TextStyle(color: kGrey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _searchResults.length,
                  itemBuilder: (_, i) {
                    final p = _searchResults[i];
                    final stock = p.totalStock;
                    final color =
                        kCategoryColors[p.colorIndex.clamp(
                          0,
                          kCategoryColors.length - 1,
                        )];

                    return GestureDetector(
                      onTap: stock > 0 ? () => _showVariantPicker(p) : null,
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
                                    p.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: kDark,
                                    ),
                                  ),
                                  Text(
                                    '${p.variants.length} variant'
                                    '${p.variants.length != 1 ? 's' : ''}'
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
  Widget _buildHistory() {
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
        itemCount: _sales.length,
        itemBuilder: (_, i) {
          final sale = _sales[i];
          return SalesHistoryCard(
            sale: sale,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ReceiptPage(sale: sale)),
            ),
            onDelete: () => _confirmDelete(i),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(int index) async {
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
      final sale = _sales[index];
      await _restoreSaleStock(sale);
      await SaleRepository.delete(sale.id);
      _load();
    }
  }

  Future<void> _restoreSaleStock(SaleModel sale) async {
    for (final item in sale.items) {
      final product = await ProductRepository.getOne(item.productId);
      if (product == null) continue;
      final variantIndex = product.variants.indexWhere(
        (variant) => variant.id == item.variantId,
      );
      if (variantIndex < 0) continue;

      final variant = product.variants[variantIndex];
      final restoredBatch = BatchModel(
        id: 'refund_${DateTime.now().microsecondsSinceEpoch}',
        qty: item.qty,
        costPrice: item.costPrice,
        addedOn: AppHelpers.todayStr(),
      );
      final variants = List<VariantModel>.from(product.variants);
      variants[variantIndex] = variant.copyWith(
        batches: [...variant.batches, restoredBatch],
      );
      await ProductRepository.save(product.copyWith(variants: variants));
      await InventoryRepository.log(
        InventoryLogModel(
          id: '',
          storeId: Session.storeId,
          productId: product.id,
          productName: product.name,
          variantId: variant.id,
          variantName: variant.name,
          type: 'refund',
          qty: item.qty,
          costPrice: item.costPrice,
          reason: 'sale_deleted_refund',
          date: AppHelpers.todayStr(),
          updatedAt: AppHelpers.nowStr(),
        ),
      );
    }
  }
}
