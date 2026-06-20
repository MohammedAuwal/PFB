class PlaceSuggestionModel {
  final String displayName;
  final double latitude;
  final double longitude;

  const PlaceSuggestionModel({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });

  factory PlaceSuggestionModel.fromMap(Map<String, dynamic> map) {
    return PlaceSuggestionModel(
      displayName: (map['display_name'] ?? '').toString(),
      latitude: double.tryParse((map['lat'] ?? '').toString()) ?? 0,
      longitude: double.tryParse((map['lon'] ?? '').toString()) ?? 0,
    );
  }

  bool get isValid =>
      displayName.trim().isNotEmpty && latitude != 0 && longitude != 0;
}
