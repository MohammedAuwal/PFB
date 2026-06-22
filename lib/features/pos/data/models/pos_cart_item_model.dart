// lib/features/pos/data/models/pos_cart_item_model.dart
import 'package:pfb/models/product_model.dart';

class PosCartItemModel {
  final String productId;
  final String productName;
  final String category;
  final String fabricType;
  final String imageUrl;
  final double unitPrice;
  int quantity;
  double yardQuantity;

  PosCartItemModel({
    required this.productId,
    required this.productName,
    required this.category,
    required this.fabricType,
    required this.imageUrl,
    required this.unitPrice,
    this.quantity = 1,
    this.yardQuantity = 1.0,
  });

  /// Builds from ProductModel — handles nullable fabricType
  factory PosCartItemModel.fromProduct(
      ProductModel product) {
    return PosCartItemModel(
      productId: product.id,
      productName: product.name,
      category: product.category,
      // ── fabricType is String? in ProductModel ──
      fabricType: product.fabricType?.isNotEmpty == true
          ? product.fabricType!
          : 'General',
      imageUrl: product.imageUrl,
      unitPrice: product.price,
      quantity: 1,
      yardQuantity: 1.0,
    );
  }

  /// Line total: unitPrice × quantity × yardQuantity
  double get lineTotal =>
      unitPrice * quantity * yardQuantity;

  PosCartItemModel copyWith({
    int? quantity,
    double? yardQuantity,
  }) {
    return PosCartItemModel(
      productId: productId,
      productName: productName,
      category: category,
      fabricType: fabricType,
      imageUrl: imageUrl,
      unitPrice: unitPrice,
      quantity: quantity ?? this.quantity,
      yardQuantity: yardQuantity ?? this.yardQuantity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'category': category,
      'fabricType': fabricType,
      'imageUrl': imageUrl,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'yardQuantity': yardQuantity,
      'lineTotal': lineTotal,
    };
  }

  factory PosCartItemModel.fromMap(
      Map<String, dynamic> map) {
    return PosCartItemModel(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      category: map['category'] ?? '',
      fabricType: map['fabricType'] ?? 'General',
      imageUrl: map['imageUrl'] ?? '',
      unitPrice:
          (map['unitPrice'] as num?)?.toDouble() ??
              0.0,
      quantity:
          (map['quantity'] as num?)?.toInt() ?? 1,
      yardQuantity:
          (map['yardQuantity'] as num?)?.toDouble() ??
              1.0,
    );
  }
}