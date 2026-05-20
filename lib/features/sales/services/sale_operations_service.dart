import '../../../core/services/sync_service.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../core/utils/session.dart';
import '../../../models/inventory_model.dart';
import '../../../models/product_model.dart';
import '../../../models/sale_model.dart';
import '../../../models/utang_model.dart';
import '../../../repositories/customer_repository.dart';
import '../../../repositories/inventory_repository.dart';
import '../../../repositories/product_repository.dart';
import '../../../repositories/sale_repository.dart';
import '../../../repositories/utang_repository.dart';

class SaleOperationsService {
  SaleOperationsService._();

  static Future<SaleModel> refundSale(
    SaleModel sale, {
    required String reason,
  }) async {
    if (sale.status == 'refunded') return sale;

    await restoreSaleStock(sale, reason: reason);
    await _adjustCustomerPurchases(sale, -sale.total);
    await _syncUtangForSale(
      sale.copyWith(status: 'refunded', amountPaid: 0, change: 0),
    );

    final updated = sale.copyWith(
      employeeId: Session.safeEmployeeId,
      employeeName: Session.safeEmployeeName,
      status: 'refunded',
      amountPaid: 0,
      change: 0,
      notes: [
        sale.notes,
        'Refund reason: $reason',
      ].where((value) => value.trim().isNotEmpty).join('\n'),
      updatedAt: AppHelpers.nowStr(),
      editHistory: [
        ...sale.editHistory,
        _historyEntry('refund', reason, before: sale.toMap()),
      ],
    );
    return SaleRepository.updateEdited(updated, action: 'refund_sale');
  }

  static Future<SaleModel> editSale({
    required SaleModel original,
    required SaleModel edited,
    required String reason,
  }) async {
    await _applyInventoryDelta(original.items, edited.items);
    await _adjustCustomerPurchases(original, -original.total);
    await _adjustCustomerPurchases(edited, edited.total);

    final paid = edited.amountPaid.clamp(0, double.infinity);
    final total = edited.total.clamp(0, double.infinity);
    final updated = edited.copyWith(
      employeeId: Session.safeEmployeeId,
      employeeName: Session.safeEmployeeName,
      amountPaid: paid.toDouble(),
      change: (paid > total ? paid - total : 0).toDouble(),
      status: edited.status == 'refunded'
          ? 'refunded'
          : edited.paymentType == 'utang' || paid < total
          ? 'partial'
          : 'completed',
      updatedAt: AppHelpers.nowStr(),
      editHistory: [
        ...original.editHistory,
        _historyEntry('edit', reason, before: original.toMap()),
      ],
    );

    await _syncUtangForSale(updated);
    return SaleRepository.updateEdited(updated, action: 'edit_sale');
  }

  static Future<void> restoreSaleStock(
    SaleModel sale, {
    required String reason,
  }) async {
    for (final item in sale.items) {
      await _restoreItem(item, item.qty, reason: reason);
    }
  }

  static Map<String, dynamic> _historyEntry(
    String type,
    String reason, {
    required Map<String, dynamic> before,
  }) => {
    'type': type,
    'reason': reason,
    'at': AppHelpers.nowStr(),
    'actorId': Session.safeEmployeeId,
    'actorName': Session.safeEmployeeName,
    'before': before,
  };

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
        await _restoreItem(ref, -delta, reason: 'sale_edit_return');
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
    if (qty <= 0) return;
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
          id: 'return_${DateTime.now().microsecondsSinceEpoch}',
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
        type: 'return',
        qty: qty,
        costPrice: item.costPrice,
        reason: reason,
        date: AppHelpers.todayStr(),
        updatedAt: AppHelpers.nowStr(),
      ),
    );
  }

  static Future<void> _adjustCustomerPurchases(
    SaleModel sale,
    double delta,
  ) async {
    if (sale.customerName == 'Walk-in' || delta == 0) return;
    final customers = await CustomerRepository.getAll();
    final matches = customers
        .where(
          (customer) =>
              customer.id == sale.customerId ||
              customer.name == sale.customerName,
        )
        .toList();
    if (matches.isEmpty) return;
    final customer = matches.first;
    final total = (customer.totalPurchases + delta).clamp(0, double.infinity);
    await CustomerRepository.save(
      customer.copyWith(totalPurchases: total.toDouble()),
    );
  }

  static Future<void> _syncUtangForSale(SaleModel sale) async {
    final all = await UtangRepository.getAll();
    final matches = all.where((utang) => utang.saleId == sale.id).toList();
    if (matches.isEmpty) return;

    for (final utang in matches) {
      if (sale.status == 'refunded') {
        await UtangRepository.save(
          _copyUtang(
            utang,
            totalAmount: 0,
            amountPaid: 0,
            status: 'paid',
            notes: [
              utang.notes,
              'Linked sale was refunded on ${AppHelpers.nowStr()}',
            ].where((value) => value.trim().isNotEmpty).join('\n'),
          ),
        );
        continue;
      }

      final paid = sale.paymentType == 'multi' || sale.paymentType == 'utang'
          ? sale.amountPaid
          : sale.total;
      final total = sale.total;
      await UtangRepository.save(
        _copyUtang(
          utang,
          customerId: sale.customerId,
          customerName: sale.customerName,
          items: sale.items.map((item) => item.toMap()).toList(),
          totalAmount: total,
          amountPaid: paid.clamp(0, total).toDouble(),
          status: paid >= total
              ? 'paid'
              : paid > 0
              ? 'partial'
              : 'pending',
        ),
      );
    }
    SyncService.notifyChanged('utang');
  }

  static UtangModel _copyUtang(
    UtangModel utang, {
    String? customerId,
    String? customerName,
    List<Map<String, dynamic>>? items,
    double? totalAmount,
    double? amountPaid,
    String? status,
    String? notes,
  }) => UtangModel(
    id: utang.id,
    storeId: utang.storeId,
    customerId: customerId ?? utang.customerId,
    customerName: customerName ?? utang.customerName,
    customerPhone: utang.customerPhone,
    saleId: utang.saleId,
    items: items ?? utang.items,
    totalAmount: totalAmount ?? utang.totalAmount,
    amountPaid: amountPaid ?? utang.amountPaid,
    startDate: utang.startDate,
    dueDate: utang.dueDate,
    status: status ?? utang.status,
    payments: utang.payments,
    notes: notes ?? utang.notes,
    updatedAt: AppHelpers.nowStr(),
  );
}

class _SaleLineQty {
  final SaleItemModel item;
  final int qty;

  const _SaleLineQty(this.item, this.qty);
}
