import 'package:pfb/features/pos/data/models/pos_sale_model.dart';

class ReceiptModel {
  final String receiptId;
  final String saleId;
  final String branchId;
  final String branchName;
  final String cashierName;
  final String cashierUid;
  final String customerName;
  final String customerPhone;
  final List<Map<String, dynamic>> items;
  final double subtotal;
  final double discountValue;
  final PosDiscountType discountType;
  final String discountReason;
  final double finalTotal;
  final PosPaymentMethod paymentMethod;
  final PosMixedPayment? mixedPayment;
  final double amountTendered;
  final double changeGiven;
  final DateTime issuedAt;

  const ReceiptModel({
    required this.receiptId,
    required this.saleId,
    required this.branchId,
    required this.branchName,
    required this.cashierName,
    required this.cashierUid,
    this.customerName = '',
    this.customerPhone = '',
    required this.items,
    required this.subtotal,
    required this.discountValue,
    required this.discountType,
    this.discountReason = '',
    required this.finalTotal,
    required this.paymentMethod,
    this.mixedPayment,
    this.amountTendered = 0,
    this.changeGiven = 0,
    required this.issuedAt,
  });

  /// Build receipt directly from a completed sale
  factory ReceiptModel.fromSale(PosSaleModel sale) {
    return ReceiptModel(
      receiptId: sale.receiptId,
      saleId: sale.id,
      branchId: sale.branchId,
      branchName: sale.branchName,
      cashierName: sale.cashierName,
      cashierUid: sale.cashierUid,
      customerName: sale.customerName,
      customerPhone: sale.customerPhone,
      items: sale.items,
      subtotal: sale.subtotal,
      discountValue: sale.discountValue,
      discountType: sale.discountType,
      discountReason: sale.discountReason,
      finalTotal: sale.finalTotal,
      paymentMethod: sale.paymentMethod,
      mixedPayment: sale.mixedPayment,
      amountTendered: sale.amountTendered,
      changeGiven: sale.changeGiven,
      issuedAt: sale.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'receiptId': receiptId,
      'saleId': saleId,
      'branchId': branchId,
      'branchName': branchName,
      'cashierName': cashierName,
      'cashierUid': cashierUid,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'items': items,
      'subtotal': subtotal,
      'discountValue': discountValue,
      'discountType': discountType.name,
      'discountReason': discountReason,
      'finalTotal': finalTotal,
      'paymentMethod': paymentMethod.firestoreValue,
      'mixedPayment': mixedPayment?.toMap(),
      'amountTendered': amountTendered,
      'changeGiven': changeGiven,
      'issuedAt': issuedAt.toIso8601String(),
    };
  }

  factory ReceiptModel.fromMap(Map<String, dynamic> map) {
    return ReceiptModel(
      receiptId: map['receiptId'] ?? '',
      saleId: map['saleId'] ?? '',
      branchId: map['branchId'] ?? 'main',
      branchName: map['branchName'] ?? 'Main Branch',
      cashierName: map['cashierName'] ?? '',
      cashierUid: map['cashierUid'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      items: List<Map<String, dynamic>>.from(map['items'] ?? []),
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
      discountValue: (map['discountValue'] as num?)?.toDouble() ?? 0,
      discountType: _parseDiscountType(map['discountType']),
      discountReason: map['discountReason'] ?? '',
      finalTotal: (map['finalTotal'] as num?)?.toDouble() ?? 0,
      paymentMethod: PosPaymentMethodX.fromString(map['paymentMethod'] ?? ''),
      mixedPayment: map['mixedPayment'] != null
          ? PosMixedPayment.fromMap(
              Map<String, dynamic>.from(map['mixedPayment']))
          : null,
      amountTendered: (map['amountTendered'] as num?)?.toDouble() ?? 0,
      changeGiven: (map['changeGiven'] as num?)?.toDouble() ?? 0,
      issuedAt: DateTime.tryParse(map['issuedAt'] ?? '') ?? DateTime.now(),
    );
  }

  static PosDiscountType _parseDiscountType(dynamic value) {
    switch (value?.toString()) {
      case 'percentage':
        return PosDiscountType.percentage;
      case 'fixed':
        return PosDiscountType.fixed;
      default:
        return PosDiscountType.none;
    }
  }
}