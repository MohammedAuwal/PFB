class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String createdBy;
  final DateTime createdAt;
  final String category;
  final List<String> categories;
  final bool featured;
  final bool isTrending;
  final bool inStock;
  final int stockQuantity;
  final List<String> variants;
  final String promoText;
  final double promoDiscountPercent;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.createdBy,
    required this.createdAt,
    this.category = 'General',
    this.categories = const ['General'],
    this.featured = false,
    this.isTrending = false,
    this.inStock = true,
    this.stockQuantity = 0,
    this.variants = const [],
    this.promoText = '',
    this.promoDiscountPercent = 0,
  });

  List<String> get normalizedCategories {
    final raw = <String>[
      ...categories,
      category,
      if (featured) 'Featured',
      if (isTrending) 'Trending',
    ];

    final cleaned = raw
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    if (cleaned.isEmpty) {
      return ['General'];
    }

    return cleaned;
  }

  bool hasCategory(String value) {
    final query = value.trim().toLowerCase();
    if (query.isEmpty) return false;
    return normalizedCategories.any((e) => e.toLowerCase() == query);
  }

  String get primaryCategory {
    if (normalizedCategories.isNotEmpty) {
      return normalizedCategories.first;
    }
    return 'General';
  }

  factory ProductModel.fromMap(String id, Map<String, dynamic> map) {
    final rawCategories = map['categories'];
    List<String> parsedCategories = [];

    if (rawCategories is List) {
      parsedCategories = rawCategories
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    final fallbackCategory = (map['category'] ?? 'General').toString().trim();
    final featured = (map['featured'] ?? false) == true;
    final isTrending = (map['isTrending'] ?? map['trending'] ?? featured) == true;

    if (parsedCategories.isEmpty && fallbackCategory.isNotEmpty) {
      parsedCategories = [fallbackCategory];
    }

    if (featured && !parsedCategories.any((e) => e.toLowerCase() == 'featured')) {
      parsedCategories.add('Featured');
    }

    if (isTrending &&
        !parsedCategories.any((e) => e.toLowerCase() == 'trending')) {
      parsedCategories.add('Trending');
    }

    final finalCategories = parsedCategories
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    return ProductModel(
      id: id,
      name: (map['name'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      price: ((map['price'] ?? 0) as num).toDouble(),
      imageUrl: ((map['imageUrl'] ?? map['image'] ?? map['photoUrl'] ?? '')).toString(),
      createdBy: (map['createdBy'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((map['createdAt'] ?? '').toString()) ?? DateTime.now(),
      category: fallbackCategory.isEmpty ? 'General' : fallbackCategory,
      categories: finalCategories.isEmpty ? ['General'] : finalCategories,
      featured: featured,
      isTrending: isTrending,
      inStock: (map['inStock'] ?? true) == true,
      stockQuantity: ((map['stockQuantity'] ?? 0) as num).toInt(),
      variants: List<String>.from(map['variants'] ?? const []),
      promoText: (map['promoText'] ?? '').toString(),
      promoDiscountPercent:
          ((map['promoDiscountPercent'] ?? 0) as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    final finalCategories = normalizedCategories;

    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'category': primaryCategory,
      'categories': finalCategories,
      'featured': featured,
      'isTrending': isTrending,
      'inStock': inStock,
      'stockQuantity': stockQuantity,
      'variants': variants,
      'promoText': promoText,
      'promoDiscountPercent': promoDiscountPercent,
    };
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? createdBy,
    DateTime? createdAt,
    String? category,
    List<String>? categories,
    bool? featured,
    bool? isTrending,
    bool? inStock,
    int? stockQuantity,
    List<String>? variants,
    String? promoText,
    double? promoDiscountPercent,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      categories: categories ?? this.categories,
      featured: featured ?? this.featured,
      isTrending: isTrending ?? this.isTrending,
      inStock: inStock ?? this.inStock,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      variants: variants ?? this.variants,
      promoText: promoText ?? this.promoText,
      promoDiscountPercent:
          promoDiscountPercent ?? this.promoDiscountPercent,
    );
  }
}
