import 'dart:convert';

// One payment entry in the utang ledger
class UtangPaymentModel {
  final String id;
  final double amount;
  final String method; // 'cash' | 'item'
  final String paidItemId; // variantId if paying specific item
  final String paidItemName;
  final int paidQty;
  final String date;
  final String employeeName;

  const UtangPaymentModel({
    required this.id,
    required this.amount,
    this.method = 'cash',
    this.paidItemId = '',
    this.paidItemName = '',
    this.paidQty = 0,
    required this.date,
    this.employeeName = '',
  });

  factory UtangPaymentModel.fromMap(Map<String, dynamic> m) =>
      UtangPaymentModel(
        id: m['id'] ?? '',
        amount: (m['amount'] ?? 0.0).toDouble(),
        method: m['method'] ?? 'cash',
        paidItemId: m['paidItemId'] ?? '',
        paidItemName: m['paidItemName'] ?? '',
        paidQty: m['paidQty'] ?? 0,
        date: m['date'] ?? '',
        employeeName: m['employeeName'] ?? '',
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'amount': amount,
    'method': method,
    'paidItemId': paidItemId,
    'paidItemName': paidItemName,
    'paidQty': paidQty,
    'date': date,
    'employeeName': employeeName,
  };
}

// ── UTANG MODEL ───────────────────────────────────────────────
class UtangModel {
  final String id;
  final String storeId;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String saleId;
  final List<Map<String, dynamic>> items; // snapshot of cart items
  final double totalAmount;
  final double amountPaid;
  final String startDate;
  final String dueDate;
  final String status; // 'pending'|'partial'|'paid'
  final List<UtangPaymentModel> payments;
  final String notes;
  final String updatedAt;

  const UtangModel({
    required this.id,
    required this.storeId,
    required this.customerId,
    required this.customerName,
    this.customerPhone = '',
    required this.saleId,
    required this.items,
    required this.totalAmount,
    this.amountPaid = 0.0,
    required this.startDate,
    this.dueDate = '',
    this.status = 'pending',
    this.payments = const [],
    this.notes = '',
    required this.updatedAt,
  });

  double get balance =>
      (totalAmount - amountPaid).clamp(0, double.infinity).toDouble();

  factory UtangModel.fromMap(Map<String, dynamic> m) => UtangModel(
    id: m['id'] ?? '',
    storeId: m['storeId'] ?? '',
    customerId: m['customerId'] ?? '',
    customerName: m['customerName'] ?? '',
    customerPhone: m['customerPhone'] ?? '',
    saleId: m['saleId'] ?? '',
    items: (m['items'] as List? ?? [])
        .map((i) => Map<String, dynamic>.from(i))
        .toList(),
    totalAmount: (m['totalAmount'] ?? 0.0).toDouble(),
    amountPaid: (m['amountPaid'] ?? 0.0).toDouble(),
    startDate: m['startDate'] ?? '',
    dueDate: m['dueDate'] ?? '',
    status: m['status'] ?? 'pending',
    payments: (m['payments'] as List? ?? [])
        .map((p) => UtangPaymentModel.fromMap(p))
        .toList(),
    notes: m['notes'] ?? '',
    updatedAt: m['updatedAt'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'storeId': storeId,
    'customerId': customerId,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'saleId': saleId,
    'items': items,
    'totalAmount': totalAmount,
    'amountPaid': amountPaid,
    'startDate': startDate,
    'dueDate': dueDate,
    'status': status,
    'payments': payments.map((p) => p.toMap()).toList(),
    'notes': notes,
    'updatedAt': updatedAt,
  };

  Map<String, dynamic> toSql() => {
    'id': id,
    'storeId': storeId,
    'customerId': customerId,
    'customerName': customerName,
    'saleId': saleId,
    'totalAmount': totalAmount,
    'amountPaid': amountPaid,
    'balance': balance,
    'startDate': startDate,
    'dueDate': dueDate,
    'status': status,
    'updatedAt': updatedAt,
    'dataJson': jsonEncode(toMap()),
  };

  factory UtangModel.fromSql(Map<String, dynamic> m) {
    final full = jsonDecode(m['dataJson'] ?? '{}') as Map<String, dynamic>;
    return UtangModel.fromMap({'id': m['id'], ...full});
  }
}
