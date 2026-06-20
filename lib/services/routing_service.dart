import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteResult {
  final double distanceKm;
  final double durationMin;
  final List<LatLng> points;
  final String geometry;

  const RouteResult({
    required this.distanceKm,
    required this.durationMin,
    required this.points,
    required this.geometry,
  });
}

class RoutingService {
  static const _baseUrl = 'https://router.project-osrm.org/route/v1/driving';

  Future<RouteResult> getRoute({
    required double pickupLat,
    required double pickupLng,
    required double destinationLat,
    required double destinationLng,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/$pickupLng,$pickupLat;$destinationLng,$destinationLat?overview=full&geometries=geojson',
    );

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch route');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final routes = decoded['routes'];

    if (routes is! List || routes.isEmpty) {
      throw Exception('No route found for the selected locations');
    }

    final route = Map<String, dynamic>.from(routes.first);
    final distanceMeters = ((route['distance'] ?? 0) as num).toDouble();
    final durationSeconds = ((route['duration'] ?? 0) as num).toDouble();

    final geometryMap = Map<String, dynamic>.from(route['geometry'] ?? {});
    final coords = List<List<dynamic>>.from(geometryMap['coordinates'] ?? []);

    final points = coords
        .where((c) => c.length >= 2)
        .map(
          (c) => LatLng(
            (c[1] as num).toDouble(),
            (c[0] as num).toDouble(),
          ),
        )
        .toList();

    return RouteResult(
      distanceKm: distanceMeters / 1000,
      durationMin: durationSeconds / 60,
      points: points,
      geometry: jsonEncode(geometryMap),
    );
  }
}
