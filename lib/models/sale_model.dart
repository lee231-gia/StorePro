import 'dart:convert';

// ── SALE ITEM ─────────────────────────────────────────────────
class SaleItemModel {
  final String productId;
  final String productName;
  final String variantId;
  final String variantName;
  final String conditionName;
  final int qty;
  final double price;
  final double costPrice; // for profit calculation
  final double discount; // item-level discount amount

  const SaleItemModel({
    required this.productId,
    required this.productName,
    required this.variantId,
    required this.variantName,
    this.conditionName = '',
    required this.qty,
    required this.price,
    this.costPrice = 0.0,
    this.discount = 0.0,
  });

  double get subtotal => (price * qty) - discount;
  double get profit => (price - costPrice) * qty - discount;

  factory SaleItemModel.fromMap(Map<String, dynamic> m) => SaleItemModel(
    productId: m['productId'] ?? '',
    productName: m['productName'] ?? '',
    variantId: m['variantId'] ?? '',
    variantName: m['variantName'] ?? '',
    conditionName: m['conditionName'] ?? '',
    qty: m['qty'] ?? 0,
    price: (m['price'] ?? 0.0).toDouble(),
    costPrice: (m['costPrice'] ?? 0.0).toDouble(),
    discount: (m['discount'] ?? 0.0).toDouble(),
  );

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'productName': productName,
    'variantId': variantId,
    'variantName': variantName,
    'conditionName': conditionName,
    'qty': qty,
    'price': price,
    'costPrice': costPrice,
    'discount': discount,
  };

  SaleItemModel copyWith({
    String? productId,
    String? productName,
    String? variantId,
    String? variantName,
    String? conditionName,
    int? qty,
    double? price,
    double? costPrice,
    double? discount,
  }) => SaleItemModel(
    productId: productId ?? this.productId,
    productName: productName ?? this.productName,
    variantId: variantId ?? this.variantId,
    variantName: variantName ?? this.variantName,
    conditionName: conditionName ?? this.conditionName,
    qty: qty ?? this.qty,
    price: price ?? this.price,
    costPrice: costPrice ?? this.costPrice,
    discount: discount ?? this.discount,
  );
}

// ── SALE MODEL ────────────────────────────────────────────────
class SaleModel {
  final String id;
  final String storeId;
  final String customerId;
  final String customerName;
  final String employeeId;
  final String employeeName;
  final List<SaleItemModel> items;
  final double subtotal;
  final double totalDiscount;
  final double total;
  final double amountPaid;
  final double change;
  final String paymentType; // 'cash' | 'utang' | 'multi'
  final String status; // 'completed' | 'refunded' | 'partial'
  final String notes;
  final String date;
  final String timestamp;
  final String updatedAt;
  final List<Map<String, dynamic>> editHistory; // for refund/edit log

  const SaleModel({
    required this.id,
    required this.storeId,
    this.customerId = '',
    this.customerName = 'Walk-in',
    this.employeeId = '',
    this.employeeName = '',
    required this.items,
    required this.subtotal,
    this.totalDiscount = 0.0,
    required this.total,
    required this.amountPaid,
    this.change = 0.0,
    this.paymentType = 'cash',
    this.status = 'completed',
    this.notes = '',
    required this.date,
    required this.timestamp,
    required this.updatedAt,
    this.editHistory = const [],
  });

  double get profit => items.fold(0.0, (sum, i) => sum + i.profit);

  factory SaleModel.fromMap(Map<String, dynamic> m) => SaleModel(
    id: m['id'] ?? '',
    storeId: m['storeId'] ?? '',
    customerId: m['customerId'] ?? '',
    customerName: m['customerName'] ?? 'Walk-in',
    employeeId: m['employeeId'] ?? '',
    employeeName: m['employeeName'] ?? '',
    items: (m['items'] as List? ?? [])
        .map((i) => SaleItemModel.fromMap(i))
        .toList(),
    subtotal: (m['subtotal'] ?? 0.0).toDouble(),
    totalDiscount: (m['totalDiscount'] ?? 0.0).toDouble(),
    total: (m['total'] ?? 0.0).toDouble(),
    amountPaid: (m['amountPaid'] ?? 0.0).toDouble(),
    change: (m['change'] ?? 0.0).toDouble(),
    paymentType: m['paymentType'] ?? 'cash',
    status: m['status'] ?? 'completed',
    notes: m['notes'] ?? '',
    date: m['date'] ?? '',
    timestamp: m['timestamp'] ?? '',
    updatedAt: m['updatedAt'] ?? '',
    editHistory: (m['editHistory'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList(),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'storeId': storeId,
    'customerId': customerId,
    'customerName': customerName,
    'employeeId': employeeId,
    'employeeName': employeeName,
    'items': items.map((i) => i.toMap()).toList(),
    'subtotal': subtotal,
    'totalDiscount': totalDiscount,
    'total': total,
    'amountPaid': amountPaid,
    'change': change,
    'paymentType': paymentType,
    'status': status,
    'notes': notes,
    'date': date,
    'timestamp': timestamp,
    'updatedAt': updatedAt,
    'editHistory': editHistory,
  };

  Map<String, dynamic> toSql() => {
    'id': id,
    'storeId': storeId,
    'customerId': customerId,
    'customerName': customerName,
    'employeeId': employeeId,
    'employeeName': employeeName,
    'date': date,
    'status': status,
    'total': total,
    'amountPaid': amountPaid,
    'change': change,
    'paymentType': paymentType,
    'notes': notes,
    'updatedAt': updatedAt,
    'dataJson': jsonEncode(toMap()),
  };

  factory SaleModel.fromSql(Map<String, dynamic> m) {
    final full = jsonDecode(m['dataJson'] ?? '{}') as Map<String, dynamic>;
    return SaleModel.fromMap({'id': m['id'], ...full});
  }

  SaleModel copyWith({
    String? customerId,
    String? customerName,
    String? employeeId,
    String? employeeName,
    List<SaleItemModel>? items,
    double? subtotal,
    double? totalDiscount,
    double? total,
    double? amountPaid,
    double? change,
    String? paymentType,
    String? status,
    String? notes,
    String? updatedAt,
    List<Map<String, dynamic>>? editHistory,
  }) => SaleModel(
    id: id,
    storeId: storeId,
    customerId: customerId ?? this.customerId,
    customerName: customerName ?? this.customerName,
    employeeId: employeeId ?? this.employeeId,
    employeeName: employeeName ?? this.employeeName,
    items: items ?? this.items,
    subtotal: subtotal ?? this.subtotal,
    totalDiscount: totalDiscount ?? this.totalDiscount,
    total: total ?? this.total,
    amountPaid: amountPaid ?? this.amountPaid,
    change: change ?? this.change,
    paymentType: paymentType ?? this.paymentType,
    status: status ?? this.status,
    notes: notes ?? this.notes,
    date: date,
    timestamp: timestamp,
    updatedAt: updatedAt ?? this.updatedAt,
    editHistory: editHistory ?? this.editHistory,
  );
}
