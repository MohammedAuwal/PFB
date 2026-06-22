enum PosDiscountType { none, percentage, fixed }

enum PosPaymentMethod { cash, bankTransfer, posTerminal, mixed }

extension PosPaymentMethodX on PosPaymentMethod {
  String get label {
    switch (this) {
      case PosPaymentMethod.cash:
        return 'Cash';
      case PosPaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PosPaymentMethod.posTerminal:
        return 'POS Terminal';
      case PosPaymentMethod.mixed:
        return 'Mixed Payment';
    }
  }

  String get firestoreValue {
    switch (this) {
      case PosPaymentMethod.cash:
        return 'cash';
      case PosPaymentMethod.bankTransfer:
        return 'bank_transfer';
      case PosPaymentMethod.posTerminal:
        return 'pos_terminal';
      case PosPaymentMethod.mixed:
        return 'mixed';
    }
  }

  static PosPaymentMethod fromString(String value) {
    switch (value) {
      case 'bank_transfer':
        return PosPaymentMethod.bankTransfer;
      case 'pos_terminal':
        return PosPaymentMethod.posTerminal;
      case 'mixed':
        return PosPaymentMethod.mixed;
      default:
        return PosPaymentMethod.cash;
    }
  }
}

class PosMixedPayment {
  final double cashAmount;
  final double transferAmount;
  final double posAmount;

  const PosMixedPayment({
    this.cashAmount = 0,
    this.transferAmount = 0,
    this.posAmount = 0,
  });

  double get total => cashAmount + transferAmount + posAmount;

  Map<String, dynamic> toMap() => {
        'cashAmount': cashAmount,
        'transferAmount': transferAmount,
        'posAmount': posAmount,
        'total': total,
      };

  factory PosMixedPayment.fromMap(Map<String, dynamic> map) {
    return PosMixedPayment(
      cashAmount: (map['cashAmount'] as num?)?.toDouble() ?? 0,
      transferAmount: (map['transferAmount'] as num?)?.toDouble() ?? 0,
      posAmount: (map['posAmount'] as num?)?.toDouble() ?? 0,
    );
  }
}

class PosSaleModel {
  final String id;
  final String receiptId;

  // Branch support (future-ready)
  final String branchId;
  final String branchName;

  // Cashier / Admin
  final String cashierUid;
  final String cashierName;
  final String cashierEmail;

  // Customer (optional for walk-in)
  final String customerName;
  final String customerPhone;

  // Items
  final List<Map<String, dynamic>> items;

  // Financials
  final double subtotal;
  final double discountValue;
  final PosDiscountType discountType;
  final String discountReason;
  final double finalTotal;

  // Payment
  final PosPaymentMethod paymentMethod;
  final PosMixedPayment? mixedPayment;
  final double amountTendered;
  final double changeGiven;

  // Analytics fields
  final String saleChannel; // 'physical_shop' | 'online'
  final DateTime createdAt;
  final String status; // 'completed' | 'voided'

  const PosSaleModel({
    required this.id,
    required this.receiptId,
    required this.branchId,
    required this.branchName,
    required this.cashierUid,
    required this.cashierName,
    required this.cashierEmail,
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
    this.saleChannel = 'physical_shop',
    required this.createdAt,
    this.status = 'completed',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'receiptId': receiptId,
      'branchId': branchId,
      'branchName': branchName,
      'cashierUid': cashierUid,
      'cashierName': cashierName,
      'cashierEmail': cashierEmail,
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
      'saleChannel': saleChannel,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      // Analytics denormalization
      'createdAtDate': _dateOnly(createdAt),
      'createdAtWeek': _weekKey(createdAt),
      'createdAtMonth': _monthKey(createdAt),
      'createdAtYear': createdAt.year,
    };
  }

  factory PosSaleModel.fromMap(String id, Map<String, dynamic> map) {
    return PosSaleModel(
      id: id,
      receiptId: map['receiptId'] ?? '',
      branchId: map['branchId'] ?? 'main',
      branchName: map['branchName'] ?? 'Main Branch',
      cashierUid: map['cashierUid'] ?? '',
      cashierName: map['cashierName'] ?? '',
      cashierEmail: map['cashierEmail'] ?? '',
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
      saleChannel: map['saleChannel'] ?? 'physical_shop',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      status: map['status'] ?? 'completed',
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

  static String _dateOnly(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  static String _weekKey(DateTime dt) {
    final firstDayOfYear = DateTime(dt.year, 1, 1);
    final week = ((dt.difference(firstDayOfYear).inDays) / 7).ceil();
    return '${dt.year}-W${week.toString().padLeft(2, '0')}';
  }

  static String _monthKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
}