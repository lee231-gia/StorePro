import 'dart:async';

import 'package:flutter/material.dart';
import 'package:storepro/widgets/sale_widgets.dart';
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
import '../../widgets/product_card.dart';
import '../../widgets/shared_widgets.dart';
import '../../features/sales/services/sale_operations_service.dart';
import 'sales_sheets.dart';
import 'receipt_page.dart';

class SalesController extends ChangeNotifier {
  int tab = 0;
  bool loading = true;
  late final ProductBrowserController browser;

  List<ProductModel> products = [];
  List<SaleModel> sales = [];
  List<CustomerModel> customers = [];
  List<String> categories = ['All'];
  final List<CartItem> cart = [];
  String historyRange = 'all';
  DateTimeRange? historyCustomRange;

  final searchCtrl = TextEditingController();
  final customerCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  StreamSubscription<String>? changeSub;
  bool checkoutInProgress = false;
  bool _disposed = false;

  double get cartTotal => cart.fold(0.0, (s, i) => s + i.subtotal);
  double get discTotal => cart.fold(0.0, (s, i) => s + i.itemDiscount);
  int get cartCount => cart.fold(0, (s, i) => s + i.qty);

  List<String> _categoryNames(List<ProductModel> products) =>
      {'All', ...products.map((product) => product.categoryName)}.toList();

  List<ProductDisplayItem> get saleItems => browser.displayItems(products);
  bool get showLegacySaleList => false;

  List<SaleModel> get historySales {
    final now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    switch (historyRange) {
      case 'today':
        start = DateTime(now.year, now.month, now.day);
        break;
      case 'week':
        start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: now.weekday - 1));
        break;
      case 'month':
        start = DateTime(now.year, now.month);
        break;
      case 'year':
        start = DateTime(now.year);
        break;
      case 'custom':
        final range = historyCustomRange;
        if (range == null) return sales;
        start = DateTime(range.start.year, range.start.month, range.start.day);
        end = DateTime(
          range.end.year,
          range.end.month,
          range.end.day,
          23,
          59,
          59,
        );
        break;
      default:
        return sales;
    }
    return sales.where((sale) {
      final dt = DateTime.tryParse(
        sale.timestamp.isNotEmpty ? sale.timestamp : sale.date,
      );
      if (dt == null) return false;
      return !dt.isBefore(start) && !dt.isAfter(end);
    }).toList();
  }

  void init() {
    browser = ProductBrowserController(
      viewMode: ProductViewMode.list,
      sortOption: ProductSortOption.nameAsc,
      groupVariants: false,
    )..addListener(_onBrowserChanged);
    changeSub = SyncService.changes.listen((collection) {
      if (collection == 'products' || collection == 'sales') load();
    });
  }

  void _onBrowserChanged() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    loading = true;
    notifyListeners();

    Future<T> safe<T>(Future<T> future, T fallback) async {
      try {
        return await future.timeout(const Duration(seconds: 5));
      } catch (_) {
        return fallback;
      }
    }
    final fetchedProducts = await safe(ProductRepository.getAll(), <ProductModel>[]);
    final fetchedSales = await safe(SaleRepository.getAll(), <SaleModel>[]);
    final fetchedCustomers = await safe(CustomerRepository.getAll(), <CustomerModel>[]);

    if (!_disposed) {
      products = fetchedProducts;
      sales = fetchedSales;
      customers = fetchedCustomers;
      categories = _categoryNames(products);
      loading = false;
      notifyListeners();
    }

    ProductRepository.syncInBackground((fresh) {
      if (!_disposed) {
        products = fresh;
        categories = _categoryNames(fresh);
        notifyListeners();
      }
    });
    SaleRepository.syncInBackground((fresh) {
      if (!_disposed) {
        sales = fresh;
        notifyListeners();
      }
    });
  }

  void addToCart(CartItem item) {
    final index = cart.indexWhere((c) => c.key == item.key);
    if (index >= 0) {
      cart[index].qty++;
    } else {
      cart.add(item);
    }
    notifyListeners();
  }

  void changeQty(int index, int delta) {
    final newQty = cart[index].qty + delta;
    if (newQty <= 0) {
      cart.removeAt(index);
    } else {
      cart[index].qty = newQty;
    }
    notifyListeners();
  }

  void removeItem(int index) {
    cart.removeAt(index);
    notifyListeners();
  }

  void setItemDiscount(int index, double disc) {
    final maxDiscount = cart[index].price * cart[index].qty;
    cart[index].itemDiscount = disc.clamp(0, maxDiscount).toDouble();
    notifyListeners();
  }

  void showVariantPicker(BuildContext context, ProductModel product) {
    final variants = product.variants;
    if (variants.isEmpty) return;

    if (variants.length == 1 && variants.first.conditions.isEmpty) {
      addToCart(
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
      onAdd: addToCart,
    );
  }

  void selectProductItem(BuildContext context, ProductDisplayItem item) {
    final variant = item.variant;
    if (variant != null && variant.conditions.isEmpty) {
      if (variant.totalStock <= 0) return;
      addToCart(
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
    if (item.totalStock > 0) showVariantPicker(context, item.product);
  }

  Future<void> openCart(BuildContext context) async {
    if (cart.isEmpty || checkoutInProgress) return;
    checkoutInProgress = true;
    try {
      final proceed = await showCartSheet(
        context: context,
        cart: cart,
        customerCtrl: customerCtrl,
        notesCtrl: notesCtrl,
        customers: customers,
        onChangeQty: changeQty,
        onRemove: removeItem,
        onItemDiscount: setItemDiscount,
      );
      if (_disposed || !proceed || cart.isEmpty) return;
      await openPayment(context);
    } finally {
      checkoutInProgress = false;
    }
  }

  Future<void> openPayment(BuildContext context) async {
    if (_disposed || cart.isEmpty) return;
    await showPaymentSheet(
      context: context,
      total: cartTotal,
      customerCtrl: customerCtrl,
      customers: customers,
      onPay: ({
        required String paymentType,
        required double amountPaid,
        required double change,
        required String customerId,
        required String customerPhone,
        required String customerAddress,
      }) async {
        await completeSale(
          context: context,
          paymentType: paymentType,
          amountPaid: amountPaid,
          change: change,
          customerId: customerId,
          customerName: customerCtrl.text.trim().isEmpty
              ? 'Walk-in'
              : customerCtrl.text.trim(),
          customerPhone: customerPhone,
          customerAddress: customerAddress,
        );
      },
    );
  }

  Future<void> completeSale({
    required BuildContext context,
    required String paymentType,
    required double amountPaid,
    required double change,
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String customerAddress,
  }) async {
    if (cart.isEmpty) return;

    final cartSnapshot = cart.toList();
    final total = cartTotal;
    final discount = discTotal;
    final normalizedCustomerName = customerName.trim().isEmpty
        ? 'Walk-in'
        : customerName.trim();

    final items = cartSnapshot
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

    late final SaleModel saved;
    try {
      final customer = await _syncSaleCustomer(
        customerId: customerId,
        customerName: normalizedCustomerName,
        customerPhone: customerPhone,
        customerAddress: customerAddress,
      );

      final sale = SaleModel(
        id: '',
        storeId: Session.storeId,
        customerId: customer?.id ?? '',
        customerName: customer?.name ?? normalizedCustomerName,
        employeeId: Session.safeEmployeeId,
        employeeName: Session.safeEmployeeName,
        items: items,
        subtotal: total + discount,
        totalDiscount: discount,
        total: total,
        amountPaid: amountPaid,
        change: change,
        paymentType: paymentType,
        status: paymentType == 'utang' ||
                (paymentType == 'multi' && amountPaid < total)
            ? 'partial'
            : 'completed',
        notes: notesCtrl.text.trim(),
        date: AppHelpers.todayStr(),
        timestamp: AppHelpers.nowStr(),
        updatedAt: AppHelpers.nowStr(),
      );

      saved = await SaleRepository.save(sale);

      for (final item in cartSnapshot) {
        await ProductRepository.deductFifo(
          item.productId,
          item.variantId,
          item.qty,
        );
      }

      if (paymentType == 'utang' ||
          (paymentType == 'multi' && amountPaid < total)) {
        final paidSoFar = paymentType == 'multi' ? amountPaid : 0.0;
        final utang = UtangModel(
          id: '',
          storeId: Session.storeId,
          customerId: customer?.id ?? '',
          customerName: customer?.name ?? normalizedCustomerName,
          customerPhone: customer?.phone ?? customerPhone,
          saleId: saved.id,
          items: cartSnapshot
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
          totalAmount: total,
          amountPaid: paidSoFar,
          startDate: AppHelpers.todayStr(),
          status: paidSoFar >= total
              ? 'paid'
              : paidSoFar > 0
              ? 'partial'
              : 'pending',
          updatedAt: AppHelpers.nowStr(),
        );
        await UtangRepository.save(utang);

        if (customer != null) {
          await CustomerRepository.addPurchase(customer.id, total);
        }
      } else {
        if (customerName != 'Walk-in') {
          final custList = await CustomerRepository.getAll();
          final match = custList.where((c) => c.name == customerName).toList();
          if (match.isNotEmpty) {
            await CustomerRepository.addPurchase(match.first.id, total);
          }
        }
      }
    } catch (e) {
      if (!_disposed) {
        showSnack(context, 'Payment failed: $e', isError: true);
      }
      return;
    }

    if (_disposed) return;

    sales = [saved, ...sales.where((sale) => sale.id != saved.id)];
    cart.clear();
    customerCtrl.clear();
    notesCtrl.clear();
    notifyListeners();

    load().ignore();

    if (!_disposed) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ReceiptPage(sale: saved)),
      );
    }
  }

  Future<CustomerModel?> _syncSaleCustomer({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String customerAddress,
  }) async {
    final name = customerName.trim();
    if (name.isEmpty || name.toLowerCase() == 'walk-in') return null;

    final customers = await CustomerRepository.getAll();
    CustomerModel? customer;
    final id = customerId.trim();
    if (id.isNotEmpty) {
      final idMatches = customers.where((c) => c.id == id).toList();
      if (idMatches.isNotEmpty) customer = idMatches.first;
    }

    final nameMatches = customers
        .where((c) => c.name.trim().toLowerCase() == name.toLowerCase())
        .toList();
    customer ??= nameMatches.isEmpty ? null : nameMatches.first;

    if (customer == null) {
      return CustomerRepository.save(
        CustomerModel(
          id: '',
          storeId: Session.storeId,
          name: name,
          phone: customerPhone.trim(),
          address: customerAddress.trim(),
          createdAt: AppHelpers.nowStr(),
          updatedAt: AppHelpers.nowStr(),
        ),
      );
    }

    final phone = customerPhone.trim();
    final address = customerAddress.trim();
    final shouldUpdate =
        customer.name != name ||
        (phone.isNotEmpty && phone != customer.phone) ||
        (address.isNotEmpty && address != customer.address);
    if (!shouldUpdate) return customer;

    return CustomerRepository.save(
      customer.copyWith(
        name: name,
        phone: phone.isEmpty ? customer.phone : phone,
        address: address.isEmpty ? customer.address : address,
      ),
    );
  }

  Future<void> confirmRefund(BuildContext context, SaleModel sale) async {
    final reasonCtrl = TextEditingController(text: 'Customer refund');
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Refund Sale?'),
        content: TextField(
          controller: reasonCtrl,
          decoration: AppInput.dialog(context, 'Refund reason'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, reasonCtrl.text.trim()),
            child: Text(
              'Refund',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
    );
    reasonCtrl.dispose();
    if (reason == null || reason.trim().isEmpty || _disposed) return;
    await SaleOperationsService.refundSale(sale, reason: reason);
    await load();
  }

  Future<void> confirmDelete(BuildContext context, SaleModel sale) async {
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
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
    );
    if (confirm == true && !_disposed) {
      if (sale.status != 'refunded') {
        await SaleOperationsService.refundSale(
          sale,
          reason: 'Sale record deleted',
        );
      }
      await SaleRepository.delete(sale.id);
      await load();
    }
  }

  void setHistoryRange(String range) {
    historyRange = range;
    if (range != 'custom') historyCustomRange = null;
    notifyListeners();
  }

  void setHistoryCustomRange(DateTimeRange range) {
    historyCustomRange = range;
    historyRange = 'custom';
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    changeSub?.cancel();
    browser
      ..removeListener(_onBrowserChanged)
      ..dispose();
    searchCtrl.dispose();
    customerCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }
}
