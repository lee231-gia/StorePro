class CategoryModel {
  final String id;
  final String storeId;
  final String name;
  final String details;
  final int iconIndex;
  final int colorIndex;
  final String imageUrl;
  final String updatedAt;

  const CategoryModel({
    required this.id,
    required this.storeId,
    required this.name,
    this.details = '',
    this.iconIndex = 0,
    this.colorIndex = 0,
    this.imageUrl = '',
    required this.updatedAt,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> m) => CategoryModel(
    id: m['id'] ?? '',
    storeId: m['storeId'] ?? '',
    name: m['name'] ?? '',
    details: m['details'] ?? '',
    iconIndex: m['iconIndex'] ?? 0,
    colorIndex: m['colorIndex'] ?? 0,
    imageUrl: m['imageUrl'] ?? '',
    updatedAt: m['updatedAt'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'storeId': storeId,
    'name': name,
    'details': details,
    'iconIndex': iconIndex,
    'colorIndex': colorIndex,
    'imageUrl': imageUrl,
    'updatedAt': updatedAt,
  };

  Map<String, dynamic> toSql() => toMap();

  CategoryModel copyWith({
    String? name,
    String? details,
    int? iconIndex,
    int? colorIndex,
    String? imageUrl,
  }) => CategoryModel(
    id: id,
    storeId: storeId,
    name: name ?? this.name,
    details: details ?? this.details,
    iconIndex: iconIndex ?? this.iconIndex,
    colorIndex: colorIndex ?? this.colorIndex,
    imageUrl: imageUrl ?? this.imageUrl,
    updatedAt: updatedAt,
  );
}
