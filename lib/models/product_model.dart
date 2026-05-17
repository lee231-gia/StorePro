import 'dart:convert';

// ── PRODUCT LIFE INDICATOR ────────────────────────────────────
// Tracks one date label on a batch (e.g. Expiry, MFG, Best Before)
class LifeIndicator {
  final String type; // 'Expiry Date' | 'Best Before' | 'MFG' etc.
  final String date; // 'YYYY-MM-DD'

  const LifeIndicator({required this.type, required this.date});

  static const List<String> types = [
    'N/A',
    'Expiry Date',
    'Best Before',
    'Best if Used By',
    'Use-By',
    'Manufacturing Date (MFG)',
    'Production Date',
    'Packed On',
    'Sell By',
    'Period After Opening',
  ];

  factory LifeIndicator.fromMap(Map<String, dynamic> m) =>
      LifeIndicator(type: m['type'] ?? 'N/A', date: m['date'] ?? '');

  Map<String, dynamic> toMap() => {'type': type, 'date': date};
}

// ── BATCH ─────────────────────────────────────────────────────
class BatchModel {
  final String id;
  final String batchNumber;
  final int qty;
  final double costPrice;
  final List<LifeIndicator> indicators; // multiple life indicators
  final String addedOn;

  const BatchModel({
    required this.id,
    this.batchNumber = '',
    required this.qty,
    this.costPrice = 0.0,
    this.indicators = const [],
    required this.addedOn,
  });

  // Returns the most critical expiry date
  // Priority: Expiry Date > Use-By > Best Before > others
  String get primaryExpiry {
    const priority = [
      'Expiry Date',
      'Use-By',
      'Best Before',
      'Best if Used By',
      'Sell By',
    ];
    for (final p in priority) {
      final found = indicators.where((i) => i.type == p && i.date.isNotEmpty);
      if (found.isNotEmpty) return found.first.date;
    }
    final any = indicators.where((i) => i.date.isNotEmpty);
    return any.isNotEmpty ? any.first.date : '';
  }

  factory BatchModel.fromMap(Map<String, dynamic> m) => BatchModel(
    id: m['id'] ?? '',
    batchNumber: m['batchNumber'] ?? '',
    qty: m['qty'] ?? 0,
    costPrice: (m['costPrice'] ?? 0.0).toDouble(),
    indicators: (m['indicators'] as List? ?? [])
        .map((i) => LifeIndicator.fromMap(i))
        .toList(),
    addedOn: m['addedOn'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'batchNumber': batchNumber,
    'qty': qty,
    'costPrice': costPrice,
    'indicators': indicators.map((i) => i.toMap()).toList(),
    'addedOn': addedOn,
  };
}

// ── CONDITION ─────────────────────────────────────────────────
class ConditionModel {
  final String name;
  final double additionalPrice; // added ON TOP of base price

  const ConditionModel({required this.name, this.additionalPrice = 0.0});

  double get price => additionalPrice;

  factory ConditionModel.fromMap(Map<String, dynamic> m) => ConditionModel(
    name: m['name'] ?? '',
    additionalPrice: (m['additionalPrice'] ?? 0.0).toDouble(),
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'additionalPrice': additionalPrice,
  };
}

// ── DISCOUNT ──────────────────────────────────────────────────
class DiscountModel {
  final String title;
  final String type; // '%' or '₱'
  final double value;

  const DiscountModel({
    required this.title,
    required this.type,
    required this.value,
  });

  factory DiscountModel.fromMap(Map<String, dynamic> m) => DiscountModel(
    title: m['title'] ?? '',
    type: m['type'] ?? '%',
    value: (m['value'] ?? 0.0).toDouble(),
  );

  Map<String, dynamic> toMap() => {
    'title': title,
    'type': type,
    'value': value,
  };
}

// ── VARIANT ───────────────────────────────────────────────────
class VariantModel {
  final String id;
  final String name; // e.g. 'Liter Solo'
  final String sku; // Stock Keeping Unit
  final String unit; // UOM: piece, bottle, kg...
  final String packaging; // Solo, Case, Pack...
  final int pcsPerUnit;
  final double price;
  final double originalPrice;
  final double costPrice;
  final bool hasDiscount;
  final List<DiscountModel> discounts;
  final List<ConditionModel> conditions;
  final List<BatchModel> batches;
  final String imageUrl; // variant-specific image

  const VariantModel({
    required this.id,
    required this.name,
    this.sku = '',
    required this.unit,
    this.packaging = '',
    this.pcsPerUnit = 1,
    required this.price,
    required this.originalPrice,
    this.costPrice = 0.0,
    this.hasDiscount = false,
    this.discounts = const [],
    this.conditions = const [],
    this.batches = const [],
    this.imageUrl = '',
  });

  // ── COMPUTED ───────────────────────────────────────────────
  int get totalStock => batches.fold(0, (s, b) => s + b.qty);

  String get nearestExpiry {
    final dates =
        batches.map((b) => b.primaryExpiry).where((e) => e.isNotEmpty).toList()
          ..sort();
    return dates.isEmpty ? '' : dates.first;
  }

  double get avgCostPrice {
    final total = totalStock;
    if (total == 0) return costPrice;
    double w = 0;
    for (final b in batches) {
      w += b.costPrice * b.qty;
    }
    return w / total;
  }

  // Expiry tier for 5-level classification
  String get expiryTier {
    final exp = nearestExpiry;
    if (exp.isEmpty) return 'no_date';
    try {
      final days = DateTime.parse(exp).difference(DateTime.now()).inDays;
      if (days <= 0) return 'expired'; // 0 or less
      if (days <= 30) return 'urgent'; // < 1 month
      if (days <= 90) return 'standard'; // 1–3 months
      if (days <= 180) return 'good'; // 3–6 months
      return 'excellent'; // 6+ months
    } catch (_) {
      return 'no_date';
    }
  }

  factory VariantModel.fromMap(Map<String, dynamic> m) => VariantModel(
    id: m['id'] ?? '',
    name: m['name'] ?? '',
    sku: m['sku'] ?? '',
    unit: m['unit'] ?? 'piece',
    packaging: m['packaging'] ?? '',
    pcsPerUnit: m['pcsPerUnit'] ?? 1,
    price: (m['price'] ?? 0.0).toDouble(),
    originalPrice: (m['originalPrice'] ?? 0.0).toDouble(),
    costPrice: (m['costPrice'] ?? 0.0).toDouble(),
    hasDiscount: m['hasDiscount'] ?? false,
    imageUrl: m['imageUrl'] ?? '',
    discounts: (m['discounts'] as List? ?? [])
        .map((d) => DiscountModel.fromMap(d))
        .toList(),
    conditions: (m['conditions'] as List? ?? [])
        .map((c) => ConditionModel.fromMap(c))
        .toList(),
    batches: (m['batches'] as List? ?? [])
        .map((b) => BatchModel.fromMap(b))
        .toList(),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'sku': sku,
    'unit': unit,
    'packaging': packaging,
    'pcsPerUnit': pcsPerUnit,
    'price': price,
    'originalPrice': originalPrice,
    'costPrice': costPrice,
    'hasDiscount': hasDiscount,
    'imageUrl': imageUrl,
    'discounts': discounts.map((d) => d.toMap()).toList(),
    'conditions': conditions.map((c) => c.toMap()).toList(),
    'batches': batches.map((b) => b.toMap()).toList(),
  };

  VariantModel copyWith({
    String? name,
    String? sku,
    String? unit,
    String? packaging,
    int? pcsPerUnit,
    double? price,
    double? originalPrice,
    double? costPrice,
    bool? hasDiscount,
    List<DiscountModel>? discounts,
    List<ConditionModel>? conditions,
    List<BatchModel>? batches,
    String? imageUrl,
  }) => VariantModel(
    id: id,
    name: name ?? this.name,
    sku: sku ?? this.sku,
    unit: unit ?? this.unit,
    packaging: packaging ?? this.packaging,
    pcsPerUnit: pcsPerUnit ?? this.pcsPerUnit,
    price: price ?? this.price,
    originalPrice: originalPrice ?? this.originalPrice,
    costPrice: costPrice ?? this.costPrice,
    hasDiscount: hasDiscount ?? this.hasDiscount,
    discounts: discounts ?? this.discounts,
    conditions: conditions ?? this.conditions,
    batches: batches ?? this.batches,
    imageUrl: imageUrl ?? this.imageUrl,
  );
}

// ── PRODUCT ───────────────────────────────────────────────────
class ProductModel {
  final String id;
  final String storeId;
  final String name;
  final String description; // NEW
  final String categoryId;
  final String categoryName;
  final bool hasVariants; // NEW — grouped or single
  final int iconIndex;
  final int colorIndex;
  final String imageUrl;
  final List<VariantModel> variants;
  final String addedOn;
  final String updatedAt;

  const ProductModel({
    required this.id,
    required this.storeId,
    required this.name,
    this.description = '',
    required this.categoryId,
    required this.categoryName,
    this.hasVariants = false,
    this.iconIndex = 0,
    this.colorIndex = 0,
    this.imageUrl = '',
    this.variants = const [],
    required this.addedOn,
    required this.updatedAt,
  });

  // ── COMPUTED ───────────────────────────────────────────────
  int get totalStock => variants.fold(0, (s, v) => s + v.totalStock);

  double get lowestPrice => variants.isEmpty
      ? 0
      : variants.map((v) => v.price).reduce((a, b) => a < b ? a : b);

  String get nearestExpiry {
    final dates =
        variants.map((v) => v.nearestExpiry).where((e) => e.isNotEmpty).toList()
          ..sort();
    return dates.isEmpty ? '' : dates.first;
  }

  factory ProductModel.fromMap(Map<String, dynamic> m) => ProductModel(
    id: m['id'] ?? '',
    storeId: m['storeId'] ?? '',
    name: m['name'] ?? '',
    description: m['description'] ?? '',
    categoryId: m['categoryId'] ?? '',
    categoryName: m['categoryName'] ?? '',
    hasVariants: m['hasVariants'] ?? false,
    iconIndex: m['iconIndex'] ?? 0,
    colorIndex: m['colorIndex'] ?? 0,
    imageUrl: m['imageUrl'] ?? '',
    variants: (m['variants'] as List? ?? [])
        .map((v) => VariantModel.fromMap(v))
        .toList(),
    addedOn: m['addedOn'] ?? '',
    updatedAt: m['updatedAt'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'storeId': storeId,
    'name': name,
    'description': description,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'hasVariants': hasVariants,
    'iconIndex': iconIndex,
    'colorIndex': colorIndex,
    'imageUrl': imageUrl,
    'variants': variants.map((v) => v.toMap()).toList(),
    'addedOn': addedOn,
    'updatedAt': updatedAt,
  };

  Map<String, dynamic> toSql() => {
    'id': id,
    'storeId': storeId,
    'name': name,
    'description': description,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'hasVariants': hasVariants ? 1 : 0,
    'iconIndex': iconIndex,
    'colorIndex': colorIndex,
    'imageUrl': imageUrl,
    'addedOn': addedOn,
    'updatedAt': updatedAt,
    'dataJson': jsonEncode(toMap()),
  };

  factory ProductModel.fromSql(Map<String, dynamic> m) {
    final full = jsonDecode(m['dataJson'] ?? '{}') as Map<String, dynamic>;
    return ProductModel.fromMap({'id': m['id'], ...full});
  }

  ProductModel copyWith({
    String? name,
    String? description,
    String? categoryId,
    String? categoryName,
    bool? hasVariants,
    int? iconIndex,
    int? colorIndex,
    String? imageUrl,
    List<VariantModel>? variants,
    String? updatedAt,
  }) => ProductModel(
    id: id,
    storeId: storeId,
    name: name ?? this.name,
    description: description ?? this.description,
    categoryId: categoryId ?? this.categoryId,
    categoryName: categoryName ?? this.categoryName,
    hasVariants: hasVariants ?? this.hasVariants,
    iconIndex: iconIndex ?? this.iconIndex,
    colorIndex: colorIndex ?? this.colorIndex,
    imageUrl: imageUrl ?? this.imageUrl,
    variants: variants ?? this.variants,
    addedOn: addedOn,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
