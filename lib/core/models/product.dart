class Product {
  final String id;
  final String name;
  final String sku;
  final String category;
  final String unit;
  final double purchasePrice;
  final double salePrice;
  final double stock;
  final double lowStockAt;
  final DateTime updatedAt;

  const Product({
    required this.id,
    required this.name,
    this.sku = '',
    this.category = 'General',
    this.unit = 'pcs',
    this.purchasePrice = 0,
    required this.salePrice,
    this.stock = 0,
    this.lowStockAt = 5,
    required this.updatedAt,
  });

  bool get isLowStock => stock <= lowStockAt;
  bool get isOutOfStock => stock <= 0;

  Product copyWith({
    String? name,
    String? sku,
    String? category,
    String? unit,
    double? purchasePrice,
    double? salePrice,
    double? stock,
    double? lowStockAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salePrice: salePrice ?? this.salePrice,
      stock: stock ?? this.stock,
      lowStockAt: lowStockAt ?? this.lowStockAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sku': sku,
    'category': category,
    'unit': unit,
    'purchasePrice': purchasePrice,
    'salePrice': salePrice,
    'stock': stock,
    'lowStockAt': lowStockAt,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Product.fromJson(Map<String, dynamic> j) => Product(
    id: j['id'] as String,
    name: j['name'] as String? ?? '',
    sku: j['sku'] as String? ?? '',
    category: j['category'] as String? ?? 'General',
    unit: j['unit'] as String? ?? 'pcs',
    purchasePrice: (j['purchasePrice'] as num? ?? 0).toDouble(),
    salePrice: (j['salePrice'] as num? ?? 0).toDouble(),
    stock: (j['stock'] as num? ?? 0).toDouble(),
    lowStockAt: (j['lowStockAt'] as num? ?? 5).toDouble(),
    updatedAt:
        DateTime.tryParse(j['updatedAt'] as String? ?? '') ?? DateTime.now(),
  );
}
