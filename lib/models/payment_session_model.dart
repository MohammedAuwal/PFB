class PaymentSessionModel {
  final String reference;
  final String userUid;
  final String email;
  final double amountNaira;
  final String currency;
  final List<Map<String, dynamic>> items;
  final Map<String, dynamic> metadata;

  const PaymentSessionModel({
    required this.reference,
    required this.userUid,
    required this.email,
    required this.amountNaira,
    required this.currency,
    required this.items,
    required this.metadata,
  });
}
