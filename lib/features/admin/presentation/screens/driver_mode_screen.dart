import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:pfb/models/ride_model.dart';
import 'package:pfb/services/firebase_service.dart';
import 'package:pfb/services/location_service.dart';
import 'package:pfb/shared/widgets/app_page_scaffold.dart';
import 'package:pfb/shared/widgets/app_section_title.dart';
import 'package:pfb/shared/widgets/app_status_chip.dart';
import 'package:pfb/shared/widgets/app_surface_card.dart';
import 'package:pfb/core/theme/build_context_theme_x.dart';

class DriverModeScreen extends StatefulWidget {
  final RideModel ride;
  final String driverName;

  const DriverModeScreen({
    super.key,
    required this.ride,
    required this.driverName,
  });

  @override
  State<DriverModeScreen> createState() => _DriverModeScreenState();
}

class _DriverModeScreenState extends State<DriverModeScreen> {
  final _firebaseService = FirebaseService();
  final _locationService = LocationService();

  StreamSubscription<LatLng>? _locationSub;
  bool _sharing = false;
  bool _busy = false;

  String get _inProgressStatus =>
      widget.ride.type == 'delivery' ? 'delivery_in_progress' : 'ride_in_progress';

  String get _modeTitle =>
      widget.ride.type == 'delivery' ? 'Delivery Mode' : 'Driver Mode';

  Future<void> _startSharing() async {
    if (_sharing || _busy) return;

    setState(() => _busy = true);

    try {
      await _firebaseService.updateRideStatus(
        rideId: widget.ride.id,
        status: 'driver_assigned',
        driver: widget.driverName,
        eta: widget.ride.eta.isEmpty ? 'Live' : widget.ride.eta,
      );

      _locationSub = _locationService.watchCurrentLatLng().listen(
        (latLng) async {
          await _firebaseService.updateRideStatus(
            rideId: widget.ride.id,
            status: 'on_the_way',
            driver: widget.driverName,
            eta: 'Live',
            driverLat: latLng.latitude,
            driverLng: latLng.longitude,
          );
        },
        onError: (_) {},
      );

      if (mounted) {
        setState(() => _sharing = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to share location: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _stopSharing() async {
    await _locationSub?.cancel();
    _locationSub = null;

    if (mounted) {
      setState(() => _sharing = false);
    }
  }

  Future<void> _markInProgress() async {
    await _firebaseService.updateRideStatus(
      rideId: widget.ride.id,
      status: _inProgressStatus,
      driver: widget.driverName,
      eta: 'In progress',
    );
  }

  Future<void> _markCompleted() async {
    await _firebaseService.updateRideStatus(
      rideId: widget.ride.id,
      status: 'completed',
      driver: widget.driverName,
      eta: 'Completed',
    );
    await _stopSharing();
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDelivery = widget.ride.type == 'delivery';

    return AppPageScaffold(
      title: _modeTitle,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppSurfaceCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSectionTitle(
                  title: '${isDelivery ? 'Dispatcher' : 'Driver'}: ${widget.driverName}',
                  spacingBottom: 12,
                ),
                Text(
                  '${isDelivery ? 'Delivery' : 'Ride'} ID: ${widget.ride.id}',
                  style: GoogleFonts.poppins(color: colors.textPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pickup: ${widget.ride.pickup}',
                  style: GoogleFonts.poppins(color: colors.textSecondary),
                ),
                Text(
                  'Destination: ${widget.ride.destination}',
                  style: GoogleFonts.poppins(color: colors.textSecondary),
                ),
                const SizedBox(height: 6),
                Text(
                  'Distance: ${widget.ride.distanceKm.toStringAsFixed(1)} km',
                  style: GoogleFonts.poppins(color: colors.textSecondary),
                ),
                Text(
                  'ETA: ${widget.ride.eta}',
                  style: GoogleFonts.poppins(color: colors.textSecondary),
                ),
                const SizedBox(height: 16),
                AppStatusChip(
                  label: _sharing
                      ? 'Live location sharing is ON'
                      : 'Live location sharing is OFF',
                  tone: _sharing
                      ? AppStatusChipTone.success
                      : AppStatusChipTone.warning,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_sharing || _busy) ? null : _startSharing,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.brandPrimary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      'Start Sharing Location',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _sharing ? _markInProgress : null,
                    child: Text(
                      isDelivery
                          ? 'Mark Delivery In Progress'
                          : 'Mark Ride In Progress',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _sharing ? _markCompleted : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.success,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(isDelivery ? 'Mark Delivered' : 'Mark Completed'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _sharing ? _stopSharing : null,
                    child: const Text('Stop Sharing'),
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
