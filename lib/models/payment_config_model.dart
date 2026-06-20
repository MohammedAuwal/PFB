class PaymentConfigModel {
  final bool paystackEnabled;
  final String activeGateway;

  // Legacy movement pricing (kept ONLY for backward compatibility)
  final double rideBaseFare;
  final double ridePricePerKm;

  // Delivery pricing (still used)
  final double deliveryBaseFare;
  final double deliveryPricePerKm;

  // Paystack
  final String paystackPublicKey;
  final List<String> enabledGateways;

  // Textile commerce extensions (safe defaults)
  final double freeDeliveryThreshold;
  final double minimumOrderAmount;
  final double maximumCouponDiscount;

  const PaymentConfigModel({
    required this.paystackEnabled,
    required this.activeGateway,
    required this.rideBaseFare,
    required this.ridePricePerKm,
    required this.deliveryBaseFare,
    required this.deliveryPricePerKm,
    required this.paystackPublicKey,
    required this.enabledGateways,
    required this.freeDeliveryThreshold,
    required this.minimumOrderAmount,
    required this.maximumCouponDiscount,
  });

  factory PaymentConfigModel.fromMap(Map<String, dynamic>? map) {
    final data = map ?? {};

    return PaymentConfigModel(
      paystackEnabled: (data['paystackEnabled'] ?? true) == true,
      activeGateway: (data['activeGateway'] ?? 'paystack').toString(),

      // Legacy fields (still read if present)
      rideBaseFare: ((data['rideBaseFare'] ?? 0) as num).toDouble(),
      ridePricePerKm: ((data['ridePricePerKm'] ?? 0) as num).toDouble(),

      // Delivery fields
      deliveryBaseFare: ((data['deliveryBaseFare'] ?? 1500) as num).toDouble(),
      deliveryPricePerKm: ((data['deliveryPricePerKm'] ?? 0) as num).toDouble(),

      paystackPublicKey: (data['paystackPublicKey'] ?? '').toString().trim(),
      enabledGateways: List<String>.from(
        data['enabledGateways'] ?? const ['paystack'],
      ),

      // Textile extensions
      freeDeliveryThreshold: ((data['freeDeliveryThreshold'] ?? 25000) as num).toDouble(),
      minimumOrderAmount: ((data['minimumOrderAmount'] ?? 1000) as num).toDouble(),
      maximumCouponDiscount: ((data['maximumCouponDiscount'] ?? 5000) as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'paystackEnabled': paystackEnabled,
      'activeGateway': activeGateway,

      // Legacy keys kept to avoid breaking PaymentService/settings screens
      'rideBaseFare': rideBaseFare,
      'ridePricePerKm': ridePricePerKm,

      'deliveryBaseFare': deliveryBaseFare,
      'deliveryPricePerKm': deliveryPricePerKm,

      'paystackPublicKey': paystackPublicKey,
      'enabledGateways': enabledGateways,

      // Textile extensions
      'freeDeliveryThreshold': freeDeliveryThreshold,
      'minimumOrderAmount': minimumOrderAmount,
      'maximumCouponDiscount': maximumCouponDiscount,
    };
  }
}
