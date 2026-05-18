class EmployeeModel {
  final String id;
  final String storeId;
  final String name;
  final String pin;
  final String createdAt;
  final String updatedAt;

  const EmployeeModel({
    required this.id,
    required this.storeId,
    required this.name,
    this.pin = '',
    required this.createdAt,
    required this.updatedAt,
  });

  factory EmployeeModel.fromMap(Map<String, dynamic> m) => EmployeeModel(
    id: m['id'] ?? '',
    storeId: m['storeId'] ?? '',
    name: m['name'] ?? '',
    pin: m['pin'] ?? '',
    createdAt: m['createdAt'] ?? '',
    updatedAt: m['updatedAt'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'storeId': storeId,
    'name': name,
    'pin': pin,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  Map<String, dynamic> toSql() => {
    'id': id,
    'storeId': storeId,
    'name': name,
    'pin': pin,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory EmployeeModel.fromSql(Map<String, dynamic> m) => EmployeeModel(
    id: m['id'] ?? '',
    storeId: m['storeId'] ?? '',
    name: m['name'] ?? '',
    pin: m['pin'] ?? '',
    createdAt: m['createdAt'] ?? '',
    updatedAt: m['updatedAt'] ?? '',
  );

  EmployeeModel copyWith({String? name, String? pin}) => EmployeeModel(
    id: id,
    storeId: storeId,
    name: name ?? this.name,
    pin: pin ?? this.pin,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
