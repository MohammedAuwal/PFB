class OrderModel {
  final String id;
  final String userId;
  final List<Map<String, dynamic>> items;
  final double totalAmount;
  final String status;
  final DateTime createdAt;
  final String deliveryRideId;
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

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.deliveryRideId = '',
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
  });

  factory OrderModel.fromMap(String id, Map<String, dynamic> map) {
    return OrderModel(
      id: id,
      userId: (map['userId'] ?? '').toString(),
      items: List<Map<String, dynamic>>.from(map['items'] ?? []),
      totalAmount: ((map['totalAmount'] ?? 0) as num).toDouble(),
      status: (map['status'] ?? 'pending').toString(),
      createdAt:
          DateTime.tryParse((map['createdAt'] ?? '').toString()) ??
              DateTime.now(),
      deliveryRideId: (map['deliveryRideId'] ?? '').toString(),
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
      escalatedToSuperAdmin: (map['escalatedToSuperAdmin'] ?? false) == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'items': items,
      'totalAmount': totalAmount,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'deliveryRideId': deliveryRideId,
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
    };
  }

  OrderModel copyWith({
    String? id,
    String? userId,
    List<Map<String, dynamic>>? items,
    double? totalAmount,
    String? status,
    DateTime? createdAt,
    String? deliveryRideId,
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
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      deliveryRideId: deliveryRideId ?? this.deliveryRideId,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      assignedAdminUid: assignedAdminUid ?? this.assignedAdminUid,
      assignedAdminEmail: assignedAdminEmail ?? this.assignedAdminEmail,
      assignedAdminName: assignedAdminName ?? this.assignedAdminName,
      assignedAdminDistanceKm:
          assignedAdminDistanceKm ?? this.assignedAdminDistanceKm,
      assignedAdminState: assignedAdminState ?? this.assignedAdminState,
      assignedAdminArea: assignedAdminArea ?? this.assignedAdminArea,
      assignmentMethod: assignmentMethod ?? this.assignmentMethod,
      activeAdminLoad: activeAdminLoad ?? this.activeAdminLoad,
      escalatedToSuperAdmin:
          escalatedToSuperAdmin ?? this.escalatedToSuperAdmin,
    );
  }
}
