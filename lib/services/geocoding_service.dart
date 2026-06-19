import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pfb/models/place_suggestion_model.dart';

class GeocodingResult {
  final String displayName;
  final double latitude;
  final double longitude;

  const GeocodingResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });
}

class GeocodingService {
  static const _searchBaseUrl = 'https://nominatim.openstreetmap.org/search';
  static const _reverseBaseUrl = 'https://nominatim.openstreetmap.org/reverse';

  Map<String, String> get _headers => const {
        'User-Agent': 'MixApp/1.0 (OpenStreetMap Nominatim Usage)',
        'Accept': 'application/json',
      };

  bool _looksNigerian(Map<String, dynamic> item) {
    final address = Map<String, dynamic>.from(item['address'] ?? {});
    final countryCode = (address['country_code'] ?? '').toString().toLowerCase();
    final displayName = (item['display_name'] ?? '').toString().toLowerCase();

    return countryCode == 'ng' ||
        displayName.contains('nigeria') ||
        displayName.contains('abuja') ||
        displayName.contains('lagos') ||
        displayName.contains('kano') ||
        displayName.contains('port harcourt') ||
        displayName.contains('enugu') ||
        displayName.contains('ibadan') ||
        displayName.contains('kaduna') ||
        displayName.contains('jos') ||
        displayName.contains('maiduguri') ||
        displayName.contains('ilorin') ||
        displayName.contains('benin') ||
        displayName.contains('owerri') ||
        displayName.contains('uyo') ||
        displayName.contains('calabar') ||
        displayName.contains('onitsha') ||
        displayName.contains('aba');
  }

  Future<List<PlaceSuggestionModel>> _runSuggestionQuery(
    String query, {
    String? countryCodes,
    int limit = 6,
  }) async {
    final params = <String, String>{
      'q': query,
      'format': 'jsonv2',
      'limit': '$limit',
      'addressdetails': '1',
    };

    if (countryCodes != null && countryCodes.trim().isNotEmpty) {
      params['countrycodes'] = countryCodes;
    }

    final uri = Uri.parse(_searchBaseUrl).replace(queryParameters: params);

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode != 200) {
      return [];
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List || decoded.isEmpty) {
      return [];
    }

    final mapped = decoded
        .map((e) => Map<String, dynamic>.from(e))
        .where(_looksNigerian)
        .map((e) => PlaceSuggestionModel.fromMap(e))
        .where((e) => e.isValid)
        .toList();

    return mapped;
  }

  Future<List<PlaceSuggestionModel>> searchSuggestions(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return [];

    final attempts = <Future<List<PlaceSuggestionModel>>>[
      _runSuggestionQuery('$trimmed, Nigeria', countryCodes: 'ng', limit: 8),
      _runSuggestionQuery(trimmed, countryCodes: 'ng', limit: 8),
      _runSuggestionQuery('$trimmed, Nigeria', limit: 8),
      _runSuggestionQuery(trimmed, limit: 8),
    ];

    for (final attempt in attempts) {
      final results = await attempt;
      if (results.isNotEmpty) {
        final unique = <String, PlaceSuggestionModel>{};
        for (final item in results) {
          unique[item.displayName] = item;
        }
        return unique.values.toList();
      }
    }

    return [];
  }

  Future<GeocodingResult> searchLocation(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      throw Exception('Location cannot be empty');
    }

    final suggestions = await searchSuggestions(trimmed);

    if (suggestions.isNotEmpty) {
      final best = suggestions.first;
      return GeocodingResult(
        displayName: best.displayName,
        latitude: best.latitude,
        longitude: best.longitude,
      );
    }

    // Final broad fallback attempt:
    final broadFallback = await _runSuggestionQuery(
      '$trimmed Nigeria',
      limit: 10,
    );

    if (broadFallback.isNotEmpty) {
      final best = broadFallback.first;
      return GeocodingResult(
        displayName: best.displayName,
        latitude: best.latitude,
        longitude: best.longitude,
      );
    }

    throw Exception(
      'Location not found. Try adding a nearby town, state, bus stop, landmark, or full Nigerian address.',
    );
  }

  Future<GeocodingResult> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(
      '$_reverseBaseUrl?lat=$latitude&lon=$longitude&format=jsonv2&addressdetails=1',
    );

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to resolve current location');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final displayName = (decoded['display_name'] ?? '').toString().trim();

    if (displayName.isEmpty) {
      throw Exception('Could not identify current location');
    }

    return GeocodingResult(
      displayName: displayName,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
