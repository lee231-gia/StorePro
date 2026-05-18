import '../../../core/utils/app_helpers.dart';
import '../../../core/utils/session.dart';
import '../../../models/inventory_model.dart';
import '../../../models/product_model.dart';
import '../../../models/sale_model.dart';
import '../../../models/customer_model.dart';
import '../../../repositories/customer_repository.dart';
import '../../../repositories/inventory_repository.dart';
import '../../../repositories/product_repository.dart';
import '../../../repositories/sale_repository.dart';

class SaleOperationsService {
  SaleOperationsService._();

  static Future<CustomerModel?> linkCustomerPurchase({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    required double amount,
  }) async {
    if (customerName == 'Walk-in' || customerName.trim().isEmpty) return null;
    final customers = await CustomerRepository.getAll();
    CustomerModel? customer;
    if (customerId.isNotEmpty) {
      final matches = customers.where((c) => c.id == customerId).toList();
      if (matches.isNotEmpty) customer = matches.first;
    }
    if (customer == null) {
      final matches = customers
          .where((c) => c.name.toLowerCase() == customerName.toLowerCase())
          .toList();
      if (matches.isNotEmpty) customer = matches.first;
    }
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
    await CustomerRepository.addPurchase(customer.id, amount);
    return customer;
  }

  static Future<SaleModel> refundSale(
    SaleModel sale, {
    required String reason,
  }) async {
    await restoreSaleStock(sale, reason: reason);
    final edited = SaleModel(
      id: sale.id,
      storeId: sale.storeId,
      customerId: sale.customerId,
      customerName: sale.customerName,
      employeeId: Session.safeEmployeeId,
      employeeName: Session.safeEmployeeName,
      items: sale.items,
      subtotal: sale.subtotal,
      totalDiscount: sale.totalDiscount,
      total: sale.total,
      amountPaid: sale.amountPaid,
      change: sale.change,
      paymentType: sale.paymentType,
      status: 'refunded',
      notes: [
        sale.notes,
        'Refund reason: $reason',
      ].where((value) => value.trim().isNotEmpty).join('\n'),
      date: sale.date,
      timestamp: sale.timestamp,
      updatedAt: AppHelpers.nowStr(),
      editHistory: [
        ...sale.editHistory,
        {
          'type': 'refund',
          'reason': reason,
          'at': AppHelpers.nowStr(),
          'employeeId': Session.safeEmployeeId,
          'employeeName': Session.safeEmployeeName,
        },
      ],
    );
    return SaleRepository.refund(sale, edited);
  }

  static Future<SaleModel> editSale({
    required SaleModel original,
    required SaleModel edited,
    required String reason,
  }) async {
    await _applyInventoryDelta(original.items, edited.items);
    final history = [
      ...original.editHistory,
      {
        'type': 'edit',
        'reason': reason,
        'at': AppHelpers.nowStr(),
        'employeeId': Session.safeEmployeeId,
        'employeeName': Session.safeEmployeeName,
        'before': original.toMap(),
      },
    ];
    return SaleRepository.updateEdited(
      edited.copyWith(
        employeeId: Session.safeEmployeeId,
        employeeName: Session.safeEmployeeName,
        updatedAt: AppHelpers.nowStr(),
        editHistory: history,
      ),
    );
  }

  static Future<void> restoreSaleStock(
    SaleModel sale, {
    required String reason,
  }) async {
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
          reason: reason,
          date: AppHelpers.todayStr(),
          updatedAt: AppHelpers.nowStr(),
        ),
      );
    }
  }

  static Future<void> _applyInventoryDelta(
    List<SaleItemModel> oldItems,
    List<SaleItemModel> newItems,
  ) async {
    final oldQty = _qtyByLine(oldItems);
    final newQty = _qtyByLine(newItems);
    final keys = {...oldQty.keys, ...newQty.keys};
    for (final key in keys) {
      final oldItem = oldQty[key]?.item;
      final newItem = newQty[key]?.item;
      final ref = newItem ?? oldItem;
      if (ref == null) continue;
      final delta = (newQty[key]?.qty ?? 0) - (oldQty[key]?.qty ?? 0);
      if (delta > 0) {
        await ProductRepository.deductFifo(ref.productId, ref.variantId, delta);
      } else if (delta < 0) {
        await _restoreItem(ref, -delta, reason: 'sale_edit_adjustment');
      }
    }
  }

  static Map<String, _SaleLineQty> _qtyByLine(List<SaleItemModel> items) {
    final result = <String, _SaleLineQty>{};
    for (final item in items) {
      final key = '${item.productId}|${item.variantId}|${item.conditionName}';
      final existing = result[key];
      result[key] = _SaleLineQty(item, (existing?.qty ?? 0) + item.qty);
    }
    return result;
  }

  static Future<void> _restoreItem(
    SaleItemModel item,
    int qty, {
    required String reason,
  }) async {
    final product = await ProductRepository.getOne(item.productId);
    if (product == null) return;
    final variantIndex = product.variants.indexWhere(
      (variant) => variant.id == item.variantId,
    );
    if (variantIndex < 0) return;
    final variant = product.variants[variantIndex];
    final variants = List<VariantModel>.from(product.variants);
    variants[variantIndex] = variant.copyWith(
      batches: [
        ...variant.batches,
        BatchModel(
          id: 'edit_${DateTime.now().microsecondsSinceEpoch}',
          qty: qty,
          costPrice: item.costPrice,
          addedOn: AppHelpers.todayStr(),
        ),
      ],
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
        type: 'edit',
        qty: qty,
        costPrice: item.costPrice,
        reason: reason,
        date: AppHelpers.todayStr(),
        updatedAt: AppHelpers.nowStr(),
      ),
    );
  }
}

class _SaleLineQty {
  final SaleItemModel item;
  final int qty;

  const _SaleLineQty(this.item, this.qty);
}
