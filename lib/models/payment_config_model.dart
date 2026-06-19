class PaymentConfigModel {
  final bool paystackEnabled;
  final String activeGateway;
  final double rideBaseFare;
  final double ridePricePerKm;
  final double deliveryBaseFare;
  final double deliveryPricePerKm;
  final String paystackPublicKey;
  final List<String> enabledGateways;

  const PaymentConfigModel({
    required this.paystackEnabled,
    required this.activeGateway,
    required this.rideBaseFare,
    required this.ridePricePerKm,
    required this.deliveryBaseFare,
    required this.deliveryPricePerKm,
    required this.paystackPublicKey,
    required this.enabledGateways,
  });

  factory PaymentConfigModel.fromMap(Map<String, dynamic>? map) {
    final data = map ?? {};

    return PaymentConfigModel(
      paystackEnabled: (data['paystackEnabled'] ?? true) == true,
      activeGateway: (data['activeGateway'] ?? 'paystack').toString(),
      rideBaseFare: ((data['rideBaseFare'] ?? 500) as num).toDouble(),
      ridePricePerKm: ((data['ridePricePerKm'] ?? 100) as num).toDouble(),
      deliveryBaseFare: ((data['deliveryBaseFare'] ?? 700) as num).toDouble(),
      deliveryPricePerKm:
          ((data['deliveryPricePerKm'] ?? 120) as num).toDouble(),
      paystackPublicKey:
          (data['paystackPublicKey'] ?? '').toString().trim(),
      enabledGateways: List<String>.from(
        data['enabledGateways'] ?? const ['paystack'],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'paystackEnabled': paystackEnabled,
      'activeGateway': activeGateway,
      'rideBaseFare': rideBaseFare,
      'ridePricePerKm': ridePricePerKm,
      'deliveryBaseFare': deliveryBaseFare,
      'deliveryPricePerKm': deliveryPricePerKm,
      'paystackPublicKey': paystackPublicKey,
      'enabledGateways': enabledGateways,
    };
  }
}
