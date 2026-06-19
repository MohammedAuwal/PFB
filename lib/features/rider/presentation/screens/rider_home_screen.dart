import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/config/routes/route_names.dart';
import 'package:pfb/core/theme/app_theme.dart';
import 'package:pfb/features/auth/presentation/screens/login_screen.dart';
import 'package:pfb/features/rider/presentation/screens/ride_detail_screen.dart';
import 'package:pfb/features/rider/presentation/screens/ride_estimate_map_preview_screen.dart';
import 'package:pfb/features/rider/presentation/screens/ride_map_screen.dart';
import 'package:pfb/features/rider/presentation/widgets/location_search_field.dart';
import 'package:pfb/features/shared/presentation/widgets/empty_state_card.dart';
import 'package:pfb/models/place_suggestion_model.dart';
import 'package:pfb/models/ride_model.dart';
import 'package:pfb/services/firebase_service.dart';
import 'package:pfb/services/location_service.dart';

class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  final firebaseService = FirebaseService();
  final locationService = LocationService();

  final _pickupCtrl = TextEditingController();
  final _destinationCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String _rideType = 'car';
  bool _loadingEstimate = false;
  bool _bookingRide = false;
  bool _loadingCurrentLocation = false;
  String? _estimateError;
  MovementEstimate? _estimate;

  PlaceSuggestionModel? _selectedPickup;
  PlaceSuggestionModel? _selectedDestination;
  bool _pickupValid = false;
  bool _destinationValid = false;

  bool get _isGuest => FirebaseAuth.instance.currentUser == null;

  Future<void> _goToLogin() async {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(
          redirectTo: RouteNames.redirectRider,
        ),
      ),
    );
  }

  Future<void> _showGuestRidePrompt() async {
    final go = await showDialog<bool>(
          context: context,
          builder: (ctx) {
            final colors = AppTheme.colorsOf(ctx);

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Text(
                'Sign in required',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              content: Text(
                'Please sign in or create an account to confirm a ride and track it properly.',
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  height: 1.5,
                  color: colors.textSecondary,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(
                    'Later',
                    style: GoogleFonts.poppins(),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(
                    'Sign In',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!go) return;
    await _goToLogin();
  }

  Future<void> _useCurrentLocationForPickup() async {
    if (_loadingCurrentLocation) return;

    setState(() => _loadingCurrentLocation = true);

    try {
      final result = await locationService.getCurrentResolvedLocation();

      final suggestion = PlaceSuggestionModel(
        displayName: result.displayName,
        latitude: result.latitude,
        longitude: result.longitude,
      );

      _pickupCtrl.text = suggestion.displayName;
      _pickupCtrl.selection = TextSelection.fromPosition(
        TextPosition(offset: _pickupCtrl.text.length),
      );

      setState(() {
        _selectedPickup = suggestion;
        _pickupValid = true;
        _estimate = null;
        _estimateError = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to use current location: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loadingCurrentLocation = false);
      }
    }
  }

  bool _canProceedLocationCheck() {
    if (_pickupCtrl.text.trim().isEmpty || _destinationCtrl.text.trim().isEmpty) {
      setState(() {
        _estimateError = 'Pickup and destination are required';
      });
      return false;
    }

    if (!_pickupValid || _selectedPickup == null) {
      setState(() {
        _estimateError = 'Please select pickup from suggestion list';
      });
      return false;
    }

    if (!_destinationValid || _selectedDestination == null) {
      setState(() {
        _estimateError = 'Please select destination from suggestion list';
      });
      return false;
    }

    return true;
  }

  Future<void> _estimateRide() async {
    if (!_canProceedLocationCheck()) return;

    final pickup = _pickupCtrl.text.trim();
    final destination = _destinationCtrl.text.trim();

    setState(() {
      _loadingEstimate = true;
      _estimateError = null;
    });

    try {
      final result = await firebaseService.estimateMovement(
        type: 'ride',
        pickup: pickup,
        destination: destination,
      );

      if (!mounted) return;
      setState(() {
        _estimate = result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _estimate = null;
        _estimateError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _loadingEstimate = false);
      }
    }
  }

  Future<void> _bookRide() async {
    if (_isGuest) {
      await _showGuestRidePrompt();
      return;
    }

    if (!_canProceedLocationCheck()) return;

    final pickup = _pickupCtrl.text.trim();
    final destination = _destinationCtrl.text.trim();
    final note = _noteCtrl.text.trim();

    setState(() => _bookingRide = true);

    try {
      await firebaseService.createRide(
        pickup: pickup,
        destination: destination,
        rideType: _rideType,
        price: _estimate?.price ?? 0,
        note: note,
      );

      _pickupCtrl.clear();
      _destinationCtrl.clear();
      _noteCtrl.clear();

      setState(() {
        _estimateError = null;
        _estimate = null;
        _selectedPickup = null;
        _selectedDestination = null;
        _pickupValid = false;
        _destinationValid = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride booked successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _bookingRide = false);
    }
  }

  @override
  void dispose() {
    _pickupCtrl.dispose();
    _destinationCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return Scaffold(
      backgroundColor: colors.scaffold,
      appBar: AppBar(
        title: Text(
          'Book a Ride',
          style: GoogleFonts.poppins(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: StreamBuilder<List<RideModel>>(
        stream: firebaseService.watchUserRides(),
        builder: (context, snapshot) {
          final rides = snapshot.data ?? [];
          RideModel? activeRide;

          try {
            activeRide = rides.firstWhere(
              (r) => r.isActive && r.type == 'ride',
            );
          } catch (_) {
            activeRide = null;
          }

          final history = rides
              .where((r) => !r.isActive && r.type == 'ride')
              .toList();

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      if (_isGuest)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.brandPrimary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: colors.brandPrimary.withOpacity(0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.person_outline_rounded,
                                color: colors.brown,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'You can check route estimates as a guest. Sign in to confirm and track rides.',
                                  style: GoogleFonts.poppins(
                                    color: colors.brown,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (activeRide != null)
                        _RideStatusCard(
                          ride: activeRide,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    RideDetailScreen(ride: activeRide!),
                              ),
                            );
                          },
                          onOpenMap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => RideMapScreen(ride: activeRide!),
                              ),
                            );
                          },
                          onCancel: () async {
                            await firebaseService.cancelRide(activeRide!.id);
                          },
                        )
                      else
                        const EmptyStateCard(
                          icon: Icons.local_taxi_outlined,
                          title: 'No active ride',
                          subtitle:
                              'Book a ride to get moving quickly and safely anywhere in Nigeria.',
                        ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: colors.card,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: colors.shadow,
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: colors.borderSoft),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ride Booking',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Stack(
                              children: [
                                LocationSearchField(
                                  controller: _pickupCtrl,
                                  hintText: 'Pickup anywhere in Nigeria',
                                  prefixIcon: Icons.my_location_rounded,
                                  showCurrentLocationAction: true,
                                  onUseCurrentLocation:
                                      _useCurrentLocationForPickup,
                                  onSelectionValidityChanged: (isValid) {
                                    setState(() => _pickupValid = isValid);
                                  },
                                  onSuggestionSelected: (suggestion) {
                                    setState(() {
                                      _selectedPickup = suggestion;
                                      _pickupValid = true;
                                      _estimate = null;
                                      _estimateError = null;
                                    });
                                  },
                                ),
                                if (_loadingCurrentLocation)
                                  Positioned(
                                    right: 48,
                                    top: 14,
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            LocationSearchField(
                              controller: _destinationCtrl,
                              hintText: 'Destination anywhere in Nigeria',
                              prefixIcon: Icons.location_on_outlined,
                              onSelectionValidityChanged: (isValid) {
                                setState(() => _destinationValid = isValid);
                              },
                              onSuggestionSelected: (suggestion) {
                                setState(() {
                                  _selectedDestination = suggestion;
                                  _destinationValid = true;
                                  _estimate = null;
                                  _estimateError = null;
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _noteCtrl,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Special note (optional)',
                                prefixIcon:
                                    const Icon(Icons.note_alt_outlined),
                                filled: true,
                                fillColor: colors.surfaceAlt,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Ride Type',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: ChoiceChip(
                                    label: const Text('Bike'),
                                    selected: _rideType == 'bike',
                                    onSelected: (_) =>
                                        setState(() => _rideType = 'bike'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ChoiceChip(
                                    label: const Text('Car'),
                                    selected: _rideType == 'car',
                                    onSelected: (_) =>
                                        setState(() => _rideType = 'car'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_estimateError != null)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: colors.error.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _estimateError!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: colors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            if (_estimate != null)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: colors.paleOrange,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: colors.brandPrimary.withOpacity(0.25),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Live Estimate',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: colors.brown,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Pickup: ${_estimate!.pickupLabel}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Destination: ${_estimate!.destinationLabel}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Distance: ${_estimate!.distanceKm.toStringAsFixed(1)} km',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'ETA: ${_estimate!.eta}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Fare: ₦${_estimate!.price.toStringAsFixed(0)}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: colors.brandPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  RideEstimateMapPreviewScreen(
                                                estimate: _estimate!,
                                                title: 'Ride Route Preview',
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.map_outlined),
                                        label: const Text(
                                          'Preview Route on Map',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed:
                                        _loadingEstimate ? null : _estimateRide,
                                    child: _loadingEstimate
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text('Check Route'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SizedBox(
                                    height: 52,
                                    child: ElevatedButton.icon(
                                      onPressed:
                                          activeRide == null && !_bookingRide
                                              ? _bookRide
                                              : null,
                                      icon: _bookingRide
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.local_taxi_rounded,
                                            ),
                                      label: Text(
                                        _isGuest
                                            ? 'Sign In to Ride'
                                            : (activeRide == null
                                                ? 'Confirm Ride'
                                                : 'Active Ride Exists'),
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            colors.brandSecondary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Ride History',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              if (history.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'No past rides yet',
                      style: GoogleFonts.poppins(color: colors.textSecondary),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final ride = history[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: colors.card,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: colors.shadow,
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: colors.borderSoft),
                          ),
                          child: ListTile(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      RideDetailScreen(ride: ride),
                                ),
                              );
                            },
                            leading: CircleAvatar(
                              backgroundColor: colors.brandPrimary,
                              child: const Icon(
                                Icons.history_rounded,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              '${ride.pickup} → ${ride.destination}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              '${ride.status} • ${ride.distanceKm.toStringAsFixed(1)} km • ${ride.eta}',
                              style: GoogleFonts.poppins(
                                color: ride.status == 'completed'
                                    ? colors.success
                                    : colors.error,
                              ),
                            ),
                            trailing: Text(
                              '₦${ride.price.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                color: colors.brandPrimary,
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: history.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RideStatusCard extends StatelessWidget {
  final RideModel ride;
  final VoidCallback onCancel;
  final VoidCallback onTap;
  final VoidCallback onOpenMap;

  const _RideStatusCard({
    required this.ride,
    required this.onCancel,
    required this.onTap,
    required this.onOpenMap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final isDelivery = ride.type == 'delivery';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: colors.shadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: colors.borderSoft),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isDelivery ? '📦 Delivery in Progress' : '🚗 Ride in Progress',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'From: ${ride.pickup}',
              style: GoogleFonts.poppins(color: colors.textPrimary),
            ),
            Text(
              'To: ${ride.destination}',
              style: GoogleFonts.poppins(color: colors.textPrimary),
            ),
            const SizedBox(height: 10),
            Text(
              'Status: ${ride.status}',
              style: GoogleFonts.poppins(
                color: colors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Distance: ${ride.distanceKm.toStringAsFixed(1)} km',
              style: GoogleFonts.poppins(color: colors.textPrimary),
            ),
            Text(
              'ETA: ${ride.eta}',
              style: GoogleFonts.poppins(color: colors.textPrimary),
            ),
            if (ride.driver != null) ...[
              const SizedBox(height: 6),
              Text(
                'Driver: ${ride.driver}',
                style: GoogleFonts.poppins(color: colors.textPrimary),
              ),
            ],
            if (ride.note.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Note: ${ride.note}',
                style: GoogleFonts.poppins(color: colors.textPrimary),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              'Fare: ₦${ride.price.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: colors.brandPrimary,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onOpenMap,
                    child: const Text('Open Map'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    child: const Text('Cancel Ride'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
