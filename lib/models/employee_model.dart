// Represents one employee in the store.
// Employees share one account but are tracked individually.
// They can be selected from a list OR typed freely per action.

class EmployeeModel {
  final String id;
  final String storeId;
  final String name;
  final String pin; // optional PIN for quick select
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  const EmployeeModel({
    required this.id,
    required this.storeId,
    required this.name,
    this.pin = '',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EmployeeModel.fromMap(Map<String, dynamic> m) => EmployeeModel(
    id: m['id'] ?? '',
    storeId: m['storeId'] ?? '',
    name: m['name'] ?? '',
    pin: m['pin'] ?? '',
    isActive: m['isActive'] ?? true,
    createdAt: m['createdAt'] ?? '',
    updatedAt: m['updatedAt'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'storeId': storeId,
    'name': name,
    'pin': pin,
    'isActive': isActive,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  // SQLite row (isActive stored as int)
  Map<String, dynamic> toSql() => {
    'id': id,
    'storeId': storeId,
    'name': name,
    'pin': pin,
    'isActive': isActive ? 1 : 0,
    'updatedAt': updatedAt,
  };

  factory EmployeeModel.fromSql(Map<String, dynamic> m) => EmployeeModel(
    id: m['id'] ?? '',
    storeId: m['storeId'] ?? '',
    name: m['name'] ?? '',
    pin: m['pin'] ?? '',
    isActive: (m['isActive'] ?? 1) == 1,
    createdAt: '',
    updatedAt: m['updatedAt'] ?? '',
  );

  EmployeeModel copyWith({String? name, String? pin, bool? isActive}) =>
      EmployeeModel(
        id: id,
        storeId: storeId,
        name: name ?? this.name,
        pin: pin ?? this.pin,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
