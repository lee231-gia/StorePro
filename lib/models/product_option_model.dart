class ProductOptionModel {
  final String id;
  final String storeId;
  final String type;
  final String value;
  final int pcsPerUnit;
  final String updatedAt;

  const ProductOptionModel({
    required this.id,
    required this.storeId,
    required this.type,
    required this.value,
    this.pcsPerUnit = 1,
    required this.updatedAt,
  });

  factory ProductOptionModel.fromMap(Map<String, dynamic> m) =>
      ProductOptionModel(
        id: m['id'] ?? '',
        storeId: m['storeId'] ?? '',
        type: m['type'] ?? '',
        value: m['value'] ?? '',
        pcsPerUnit: m['pcsPerUnit'] ?? 1,
        updatedAt: m['updatedAt'] ?? '',
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'storeId': storeId,
    'type': type,
    'value': value,
    'pcsPerUnit': pcsPerUnit,
    'updatedAt': updatedAt,
  };

  Map<String, dynamic> toSql() => toMap();
}
