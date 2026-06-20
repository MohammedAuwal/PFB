class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final List<String> additionalImages;
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

  // ── Textile-Specific Fields ──────────────────────────────────────────────
  final String fabricType;
  final String material;
  final List<String> availableColors;
  final List<String> availableSizes;
  final double yardage;
  final String gsm;
  final String careInstructions;
  final String occasion;
  final String gender;
  final String origin;
  final bool isNewArrival;
  final bool isBestSeller;
  final int soldCount;
  final double rating;
  final int reviewCount;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.additionalImages = const [],
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
    // Textile fields
    this.fabricType = '',
    this.material = '',
    this.availableColors = const [],
    this.availableSizes = const [],
    this.yardage = 0,
    this.gsm = '',
    this.careInstructions = '',
    this.occasion = '',
    this.gender = 'Unisex',
    this.origin = 'Nigeria',
    this.isNewArrival = false,
    this.isBestSeller = false,
    this.soldCount = 0,
    this.rating = 0,
    this.reviewCount = 0,
  });

  // ── Computed ─────────────────────────────────────────────────────────────

  bool get hasDiscount => promoDiscountPercent > 0;

  double get discountedPrice {
    if (!hasDiscount) return price;
    return price - (price * promoDiscountPercent / 100);
  }

  String get discountLabel =>
      hasDiscount ? '${promoDiscountPercent.toStringAsFixed(0)}% OFF' : '';

  List<String> get normalizedCategories {
    final raw = <String>[
      ...categories,
      category,
      if (featured) 'Featured',
      if (isTrending) 'Trending',
      if (isNewArrival) 'New Arrivals',
      if (isBestSeller) 'Best Sellers',
      if (fabricType.isNotEmpty) fabricType,
      if (occasion.isNotEmpty) occasion,
      if (gender.isNotEmpty && gender != 'Unisex') gender,
    ];

    final cleaned = raw
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    return cleaned.isEmpty ? ['General'] : cleaned;
  }

  bool hasCategory(String value) {
    final query = value.trim().toLowerCase();
    if (query.isEmpty) return false;
    return normalizedCategories.any((e) => e.toLowerCase() == query);
  }

  String get primaryCategory {
    if (normalizedCategories.isNotEmpty) return normalizedCategories.first;
    return 'General';
  }

  // ── fromMap ───────────────────────────────────────────────────────────────

  factory ProductModel.fromMap(String id, Map<String, dynamic> map) {
    final rawCategories = map['categories'];
    List<String> parsedCategories = [];

    if (rawCategories is List) {
      parsedCategories = rawCategories
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    final fallbackCategory =
        (map['category'] ?? 'General').toString().trim();
    final featured = (map['featured'] ?? false) == true;
    final isTrending =
        (map['isTrending'] ?? map['trending'] ?? featured) == true;
    final isNewArrival = (map['isNewArrival'] ?? false) == true;
    final isBestSeller = (map['isBestSeller'] ?? false) == true;

    if (parsedCategories.isEmpty && fallbackCategory.isNotEmpty) {
      parsedCategories = [fallbackCategory];
    }

    void _addIfMissing(List<String> list, String value) {
      if (value.isNotEmpty &&
          !list.any((e) => e.toLowerCase() == value.toLowerCase())) {
        list.add(value);
      }
    }

    if (featured) _addIfMissing(parsedCategories, 'Featured');
    if (isTrending) _addIfMissing(parsedCategories, 'Trending');
    if (isNewArrival) _addIfMissing(parsedCategories, 'New Arrivals');
    if (isBestSeller) _addIfMissing(parsedCategories, 'Best Sellers');

    final fabricType = (map['fabricType'] ?? '').toString().trim();
    if (fabricType.isNotEmpty) _addIfMissing(parsedCategories, fabricType);

    final finalCategories = parsedCategories
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    // Parse additional images
    final rawAdditional = map['additionalImages'];
    List<String> additionalImages = [];
    if (rawAdditional is List) {
      additionalImages = rawAdditional
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    // Parse colors & sizes
    List<String> _parseStringList(dynamic raw) {
      if (raw is List) {
        return raw
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return [];
    }

    return ProductModel(
      id: id,
      name: (map['name'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      price: ((map['price'] ?? 0) as num).toDouble(),
      imageUrl: (map['imageUrl'] ?? map['image'] ?? map['photoUrl'] ?? '')
          .toString(),
      additionalImages: additionalImages,
      createdBy: (map['createdBy'] ?? '').toString(),
      createdAt: DateTime.tryParse((map['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      category:
          fallbackCategory.isEmpty ? 'General' : fallbackCategory,
      categories:
          finalCategories.isEmpty ? ['General'] : finalCategories,
      featured: featured,
      isTrending: isTrending,
      inStock: (map['inStock'] ?? true) == true,
      stockQuantity: ((map['stockQuantity'] ?? 0) as num).toInt(),
      variants: List<String>.from(map['variants'] ?? const []),
      promoText: (map['promoText'] ?? '').toString(),
      promoDiscountPercent:
          ((map['promoDiscountPercent'] ?? 0) as num).toDouble(),
      // Textile fields
      fabricType: fabricType,
      material: (map['material'] ?? '').toString().trim(),
      availableColors: _parseStringList(map['availableColors']),
      availableSizes: _parseStringList(map['availableSizes']),
      yardage: ((map['yardage'] ?? 0) as num).toDouble(),
      gsm: (map['gsm'] ?? '').toString().trim(),
      careInstructions:
          (map['careInstructions'] ?? '').toString().trim(),
      occasion: (map['occasion'] ?? '').toString().trim(),
      gender: (map['gender'] ?? 'Unisex').toString().trim(),
      origin: (map['origin'] ?? 'Nigeria').toString().trim(),
      isNewArrival: isNewArrival,
      isBestSeller: isBestSeller,
      soldCount: ((map['soldCount'] ?? 0) as num).toInt(),
      rating: ((map['rating'] ?? 0) as num).toDouble(),
      reviewCount: ((map['reviewCount'] ?? 0) as num).toInt(),
    );
  }

  // ── toMap ─────────────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'additionalImages': additionalImages,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'category': primaryCategory,
      'categories': normalizedCategories,
      'featured': featured,
      'isTrending': isTrending,
      'inStock': inStock,
      'stockQuantity': stockQuantity,
      'variants': variants,
      'promoText': promoText,
      'promoDiscountPercent': promoDiscountPercent,
      // Textile fields
      'fabricType': fabricType,
      'material': material,
      'availableColors': availableColors,
      'availableSizes': availableSizes,
      'yardage': yardage,
      'gsm': gsm,
      'careInstructions': careInstructions,
      'occasion': occasion,
      'gender': gender,
      'origin': origin,
      'isNewArrival': isNewArrival,
      'isBestSeller': isBestSeller,
      'soldCount': soldCount,
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }

  // ── copyWith ──────────────────────────────────────────────────────────────

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    List<String>? additionalImages,
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
    String? fabricType,
    String? material,
    List<String>? availableColors,
    List<String>? availableSizes,
    double? yardage,
    String? gsm,
    String? careInstructions,
    String? occasion,
    String? gender,
    String? origin,
    bool? isNewArrival,
    bool? isBestSeller,
    int? soldCount,
    double? rating,
    int? reviewCount,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      additionalImages: additionalImages ?? this.additionalImages,
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
      fabricType: fabricType ?? this.fabricType,
      material: material ?? this.material,
      availableColors: availableColors ?? this.availableColors,
      availableSizes: availableSizes ?? this.availableSizes,
      yardage: yardage ?? this.yardage,
      gsm: gsm ?? this.gsm,
      careInstructions: careInstructions ?? this.careInstructions,
      occasion: occasion ?? this.occasion,
      gender: gender ?? this.gender,
      origin: origin ?? this.origin,
      isNewArrival: isNewArrival ?? this.isNewArrival,
      isBestSeller: isBestSeller ?? this.isBestSeller,
      soldCount: soldCount ?? this.soldCount,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }
}
