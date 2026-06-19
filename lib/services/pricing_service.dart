class PricingService {
  static const double rideBaseFare = 500;
  static const double ridePricePerKm = 100;

  static const double deliveryBaseFare = 700;
  static const double deliveryPricePerKm = 120;

  double calculateFare({
    required String type,
    required double distanceKm,
  }) {
    final isDelivery = type == 'delivery';

    final baseFare = isDelivery ? deliveryBaseFare : rideBaseFare;
    final pricePerKm = isDelivery ? deliveryPricePerKm : ridePricePerKm;

    return baseFare + (distanceKm * pricePerKm);
  }

  String formatEta(double durationMin) {
    if (durationMin <= 0) return 'Pending';
    return '${durationMin.ceil()} mins';
  }
}
