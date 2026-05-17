// Tracks every stock adjustment (add, remove, replenish, waste, loss)

class InventoryLogModel {
  final String id;
  final String storeId;
  final String productId;
  final String productName;
  final String variantId;
  final String variantName;
  final String type; // 'add'|'remove'|'waste'|'loss'|'adjustment'|'sale'
  final int qty; // positive = added, negative = removed
  final double costPrice;
  final String reason; // 'replenishment'|'damage'|'personal'|'missing'|'sale'
  final String employeeId;
  final String employeeName;
  final String date;
  final String updatedAt;

  const InventoryLogModel({
    required this.id,
    required this.storeId,
    required this.productId,
    required this.productName,
    required this.variantId,
    required this.variantName,
    required this.type,
    required this.qty,
    this.costPrice = 0.0,
    this.reason = '',
    this.employeeId = '',
    this.employeeName = '',
    required this.date,
    required this.updatedAt,
  });

  factory InventoryLogModel.fromMap(Map<String, dynamic> m) =>
      InventoryLogModel(
        id: m['id'] ?? '',
        storeId: m['storeId'] ?? '',
        productId: m['productId'] ?? '',
        productName: m['productName'] ?? '',
        variantId: m['variantId'] ?? '',
        variantName: m['variantName'] ?? '',
        type: m['type'] ?? 'add',
        qty: m['qty'] ?? 0,
        costPrice: (m['costPrice'] ?? 0.0).toDouble(),
        reason: m['reason'] ?? '',
        employeeId: m['employeeId'] ?? '',
        employeeName: m['employeeName'] ?? '',
        date: m['date'] ?? '',
        updatedAt: m['updatedAt'] ?? '',
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'storeId': storeId,
    'productId': productId,
    'productName': productName,
    'variantId': variantId,
    'variantName': variantName,
    'type': type,
    'qty': qty,
    'costPrice': costPrice,
    'reason': reason,
    'employeeId': employeeId,
    'employeeName': employeeName,
    'date': date,
    'updatedAt': updatedAt,
  };

  Map<String, dynamic> toSql() => toMap();
}
