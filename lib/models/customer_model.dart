class CustomerModel {
  final String id;
  final String storeId;
  final String name;
  final String phone;
  final String address;
  final String notes;
  final double totalPurchases;
  final String createdAt;
  final String updatedAt;

  const CustomerModel({
    required this.id,
    required this.storeId,
    required this.name,
    this.phone = '',
    this.address = '',
    this.notes = '',
    this.totalPurchases = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomerModel.fromMap(Map<String, dynamic> m) => CustomerModel(
    id: m['id'] ?? '',
    storeId: m['storeId'] ?? '',
    name: m['name'] ?? '',
    phone: m['phone'] ?? '',
    address: m['address'] ?? '',
    notes: m['notes'] ?? '',
    totalPurchases: (m['totalPurchases'] ?? 0.0).toDouble(),
    createdAt: m['createdAt'] ?? '',
    updatedAt: m['updatedAt'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'storeId': storeId,
    'name': name,
    'phone': phone,
    'address': address,
    'notes': notes,
    'totalPurchases': totalPurchases,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  Map<String, dynamic> toSql() => toMap();

  CustomerModel copyWith({
    String? name,
    String? phone,
    String? address,
    String? notes,
    double? totalPurchases,
  }) => CustomerModel(
    id: id,
    storeId: storeId,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    address: address ?? this.address,
    notes: notes ?? this.notes,
    totalPurchases: totalPurchases ?? this.totalPurchases,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
