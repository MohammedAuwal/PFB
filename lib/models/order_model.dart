class OrderModel {
  final String id;
  final String userId;
  final List<Map<String, dynamic>> items;
  final double totalAmount;
  final String status;
  final String createdAt; // ISO string — consistent with OrderDetailScreen
  final String deliveryAddress;
  final String assignedAdminUid;
  final String assignedAdminEmail;
  final String assignedAdminName;
  final double assignedAdminDistanceKm;
  final String assignedAdminState;
  final String assignedAdminArea;
  final String assignmentMethod;
  final int activeAdminLoad;
  final bool escalatedToSuperAdmin;

  // ── Textile Commerce Fields ──────────────────────────────────────────────
  final String? paymentReference;
  final String? paymentStatus;
  final double? deliveryFee;
  final double? couponDiscount;
  final String? couponCode;
  final String? notes;
  final String? trackingNumber;

  // Legacy field — kept for backward compatibility
  final String deliveryRideId;

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.deliveryAddress = '',
    this.assignedAdminUid = '',
    this.assignedAdminEmail = '',
    this.assignedAdminName = '',
    this.assignedAdminDistanceKm = 0,
    this.assignedAdminState = '',
    this.assignedAdminArea = '',
    this.assignmentMethod = '',
    this.activeAdminLoad = 0,
    this.escalatedToSuperAdmin = false,
    this.deliveryRideId = '',
    // New textile fields
    this.paymentReference,
    this.paymentStatus,
    this.deliveryFee,
    this.couponDiscount,
    this.couponCode,
    this.notes,
    this.trackingNumber,
  });

  // ── fromMap ───────────────────────────────────────────────────────────────

  factory OrderModel.fromMap(String id, Map<String, dynamic> map) {
    // Handle createdAt — support both DateTime and String
    String createdAtStr;
    final rawCreatedAt = map['createdAt'];
    if (rawCreatedAt is String && rawCreatedAt.isNotEmpty) {
      createdAtStr = rawCreatedAt;
    } else {
      createdAtStr = DateTime.now().toIso8601String();
    }

    return OrderModel(
      id: id,
      userId: (map['userId'] ?? '').toString(),
      items: List<Map<String, dynamic>>.from(map['items'] ?? []),
      totalAmount: ((map['totalAmount'] ?? 0) as num).toDouble(),
      status: (map['status'] ?? 'pending').toString(),
      createdAt: createdAtStr,
      deliveryAddress: (map['deliveryAddress'] ?? '').toString(),
      assignedAdminUid: (map['assignedAdminUid'] ?? '').toString(),
      assignedAdminEmail: (map['assignedAdminEmail'] ?? '').toString(),
      assignedAdminName: (map['assignedAdminName'] ?? '').toString(),
      assignedAdminDistanceKm:
          ((map['assignedAdminDistanceKm'] ?? 0) as num).toDouble(),
      assignedAdminState: (map['assignedAdminState'] ?? '').toString(),
      assignedAdminArea: (map['assignedAdminArea'] ?? '').toString(),
      assignmentMethod: (map['assignmentMethod'] ?? '').toString(),
      activeAdminLoad: ((map['activeAdminLoad'] ?? 0) as num).toInt(),
      escalatedToSuperAdmin:
          (map['escalatedToSuperAdmin'] ?? false) == true,
      deliveryRideId: (map['deliveryRideId'] ?? '').toString(),
      // New textile fields
      paymentReference:
          map['paymentReference']?.toString(),
      paymentStatus:
          map['paymentStatus']?.toString(),
      deliveryFee: map['deliveryFee'] != null
          ? ((map['deliveryFee']) as num).toDouble()
          : null,
      couponDiscount: map['couponDiscount'] != null
          ? ((map['couponDiscount']) as num).toDouble()
          : null,
      couponCode: map['couponCode']?.toString(),
      notes: map['notes']?.toString(),
      trackingNumber: map['trackingNumber']?.toString(),
    );
  }

  // ── toMap ─────────────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'items': items,
      'totalAmount': totalAmount,
      'status': status,
      'createdAt': createdAt,
      'deliveryAddress': deliveryAddress,
      'assignedAdminUid': assignedAdminUid,
      'assignedAdminEmail': assignedAdminEmail,
      'assignedAdminName': assignedAdminName,
      'assignedAdminDistanceKm': assignedAdminDistanceKm,
      'assignedAdminState': assignedAdminState,
      'assignedAdminArea': assignedAdminArea,
      'assignmentMethod': assignmentMethod,
      'activeAdminLoad': activeAdminLoad,
      'escalatedToSuperAdmin': escalatedToSuperAdmin,
      'deliveryRideId': deliveryRideId,
      // New textile fields
      if (paymentReference != null)
        'paymentReference': paymentReference,
      if (paymentStatus != null)
        'paymentStatus': paymentStatus,
      if (deliveryFee != null) 'deliveryFee': deliveryFee,
      if (couponDiscount != null)
        'couponDiscount': couponDiscount,
      if (couponCode != null) 'couponCode': couponCode,
      if (notes != null) 'notes': notes,
      if (trackingNumber != null)
        'trackingNumber': trackingNumber,
    };
  }

  // ── copyWith ──────────────────────────────────────────────────────────────

  OrderModel copyWith({
    String? id,
    String? userId,
    List<Map<String, dynamic>>? items,
    double? totalAmount,
    String? status,
    String? createdAt,
    String? deliveryAddress,
    String? assignedAdminUid,
    String? assignedAdminEmail,
    String? assignedAdminName,
    double? assignedAdminDistanceKm,
    String? assignedAdminState,
    String? assignedAdminArea,
    String? assignmentMethod,
    int? activeAdminLoad,
    bool? escalatedToSuperAdmin,
    String? deliveryRideId,
    String? paymentReference,
    String? paymentStatus,
    double? deliveryFee,
    double? couponDiscount,
    String? couponCode,
    String? notes,
    String? trackingNumber,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      assignedAdminUid: assignedAdminUid ?? this.assignedAdminUid,
      assignedAdminEmail:
          assignedAdminEmail ?? this.assignedAdminEmail,
      assignedAdminName:
          assignedAdminName ?? this.assignedAdminName,
      assignedAdminDistanceKm:
          assignedAdminDistanceKm ?? this.assignedAdminDistanceKm,
      assignedAdminState:
          assignedAdminState ?? this.assignedAdminState,
      assignedAdminArea:
          assignedAdminArea ?? this.assignedAdminArea,
      assignmentMethod: assignmentMethod ?? this.assignmentMethod,
      activeAdminLoad: activeAdminLoad ?? this.activeAdminLoad,
      escalatedToSuperAdmin:
          escalatedToSuperAdmin ?? this.escalatedToSuperAdmin,
      deliveryRideId: deliveryRideId ?? this.deliveryRideId,
      paymentReference: paymentReference ?? this.paymentReference,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      couponDiscount: couponDiscount ?? this.couponDiscount,
      couponCode: couponCode ?? this.couponCode,
      notes: notes ?? this.notes,
      trackingNumber: trackingNumber ?? this.trackingNumber,
    );
  }

  // ── Computed helpers ──────────────────────────────────────────────────────

  /// Human-readable short ID for display
  String get shortId {
    if (id.length > 12) return '#${id.substring(0, 12).toUpperCase()}';
    return '#${id.toUpperCase()}';
  }

  /// Formatted date string
  String get formattedDate {
    try {
      final date = DateTime.parse(createdAt);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return createdAt;
    }
  }

  /// Whether order is still active (not delivered or cancelled)
  bool get isActive =>
      status.toLowerCase() != 'delivered' &&
      status.toLowerCase() != 'cancelled';

  /// Items subtotal before fees and discounts
  double get itemsSubtotal {
    return items.fold<double>(
      0,
      (sum, item) =>
          sum +
          (((item['price'] ?? 0) as num).toDouble() *
              ((item['qty'] ?? 1) as int)),
    );
  }
}
