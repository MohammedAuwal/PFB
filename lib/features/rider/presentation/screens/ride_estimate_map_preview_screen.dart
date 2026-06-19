import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:pfb/core/theme/app_theme.dart';
import 'package:pfb/services/firebase_service.dart';

class RideEstimateMapPreviewScreen extends StatelessWidget {
  final MovementEstimate estimate;
  final String title;

  const RideEstimateMapPreviewScreen({
    super.key,
    required this.estimate,
    this.title = 'Route Preview',
  });

  List<LatLng> _decodeRoute(String geometry) {
    if (geometry.trim().isEmpty) return [];

    try {
      final map = jsonDecode(geometry) as Map<String, dynamic>;
      final coords = List<List<dynamic>>.from(map['coordinates'] ?? []);
      return coords
          .where((c) => c.length >= 2)
          .map(
            (c) => LatLng(
              (c[1] as num).toDouble(),
              (c[0] as num).toDouble(),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  LatLngBounds? _boundsFor(List<LatLng> points) {
    if (points.isEmpty) return null;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    final routePoints = _decodeRoute(estimate.routeGeometry);
    final pickup = LatLng(estimate.pickupLat, estimate.pickupLng);
    final destination = LatLng(estimate.destinationLat, estimate.destinationLng);

    final points = <LatLng>[
      pickup,
      destination,
      ...routePoints,
    ];

    final bounds = _boundsFor(points);

    return Scaffold(
      backgroundColor: colors.scaffold,
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: pickup,
                initialZoom: 6,
                initialCameraFit: bounds != null
                    ? CameraFit.bounds(
                        bounds: bounds,
                        padding: const EdgeInsets.all(36),
                      )
                    : null,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.maamahsmix.app',
                ),
                if (routePoints.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: routePoints,
                        color: colors.warning,
                        strokeWidth: 5,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: pickup,
                      width: 44,
                      height: 44,
                      child: Icon(
                        Icons.my_location,
                        color: colors.success,
                        size: 36,
                      ),
                    ),
                    Marker(
                      point: destination,
                      width: 44,
                      height: 44,
                      child: Icon(
                        Icons.location_on,
                        color: colors.error,
                        size: 36,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(top: BorderSide(color: colors.borderSoft)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pickup: ${estimate.pickupLabel}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Destination: ${estimate.destinationLabel}',
                  style: GoogleFonts.poppins(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Distance: ${estimate.distanceKm.toStringAsFixed(1)} km',
                  style: GoogleFonts.poppins(
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  'ETA: ${estimate.eta}',
                  style: GoogleFonts.poppins(
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  'Estimated Fare: ₦${estimate.price.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: colors.brandPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
