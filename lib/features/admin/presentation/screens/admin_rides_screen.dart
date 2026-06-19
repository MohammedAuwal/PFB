import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/core/constants/app_constants.dart';
import 'package:pfb/features/admin/presentation/screens/admin_reassignment_screen.dart';
import 'package:pfb/features/rider/presentation/screens/driver_mode_screen.dart';
import 'package:pfb/features/rider/presentation/screens/ride_detail_screen.dart';
import 'package:pfb/models/ride_model.dart';
import 'package:pfb/services/firebase_service.dart';
import 'package:pfb/shared/widgets/app_page_scaffold.dart';
import 'package:pfb/shared/widgets/app_status_chip.dart';
import 'package:pfb/shared/widgets/app_surface_card.dart';
import 'package:pfb/core/theme/build_context_theme_x.dart';

class AdminRidesScreen extends StatelessWidget {
  AdminRidesScreen({super.key});

  final firebaseService = FirebaseService();

  Color _statusColor(BuildContext context, String status) {
    final colors = context.appColors;

    switch (status) {
      case 'completed':
        return colors.success;
      case 'cancelled':
        return colors.error;
      case 'ride_in_progress':
      case 'delivery_in_progress':
        return colors.info;
      case 'on_the_way':
        return colors.warning;
      default:
        return colors.brandPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return FutureBuilder<bool>(
      future: firebaseService.isAdmin(),
      builder: (context, adminSnapshot) {
        if (adminSnapshot.connectionState == ConnectionState.waiting) {
          return AppPageScaffold(
            title: 'Manage Rides & Deliveries',
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final isAdmin = adminSnapshot.data ?? false;
        final isSuperAdmin = AppConstants.isSuperAdminUid(
          FirebaseAuth.instance.currentUser?.uid,
        );

        if (!isAdmin && !isSuperAdmin) {
          return AppPageScaffold(
            title: 'Manage Rides & Deliveries',
            body: Center(
              child: Text(
                'You do not have access to rides',
                style: GoogleFonts.poppins(color: colors.textSecondary),
              ),
            ),
          );
        }

        final stream = isSuperAdmin
            ? firebaseService.watchAllRides()
            : firebaseService.watchAssignedRidesForAdmin();

        return AppPageScaffold(
          title: isSuperAdmin
              ? 'Manage All Rides & Deliveries'
              : 'My Assigned Rides & Deliveries',
          body: StreamBuilder<List<RideModel>>(
            stream: stream,
            builder: (context, snapshot) {
              final rides = snapshot.data ?? [];

              if (rides.isEmpty) {
                return Center(
                  child: Text(
                    isSuperAdmin
                        ? 'No rides yet'
                        : 'No assigned rides yet',
                    style: GoogleFonts.poppins(color: colors.textSecondary),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: rides.length,
                itemBuilder: (_, i) {
                  final ride = rides[i];
                  final isDelivery = ride.type == 'delivery';

                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RideDetailScreen(ride: ride),
                        ),
                      );
                    },
                    child: AppSurfaceCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                '${isDelivery ? 'Delivery' : 'Ride'} ID: ${ride.id}',
                                style: GoogleFonts.poppins(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              AppStatusChip(
                                label: isDelivery ? 'Delivery' : 'Ride',
                                tone: isDelivery
                                    ? AppStatusChipTone.info
                                    : AppStatusChipTone.primary,
                              ),
                              if (ride.escalatedToSuperAdmin)
                                const AppStatusChip(
                                  label: 'Escalated',
                                  tone: AppStatusChipTone.error,
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'From: ${ride.pickup}',
                            style: GoogleFonts.poppins(color: colors.textSecondary),
                          ),
                          Text(
                            'To: ${ride.destination}',
                            style: GoogleFonts.poppins(color: colors.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Ride Type: ${ride.rideType}',
                            style: GoogleFonts.poppins(color: colors.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Distance: ${ride.distanceKm.toStringAsFixed(1)} km • ETA: ${ride.eta}',
                            style: GoogleFonts.poppins(color: colors.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Fare: ₦${ride.price.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              color: colors.brandPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Status: ${ride.status}',
                            style: GoogleFonts.poppins(
                              color: _statusColor(context, ride.status),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if ((ride.assignedAdminName ?? '').isNotEmpty)
                            Text(
                              'Assigned Admin: ${ride.assignedAdminName}',
                              style: GoogleFonts.poppins(color: colors.textSecondary),
                            ),
                          if ((ride.assignmentMethod ?? '').isNotEmpty)
                            Text(
                              'Assignment: ${ride.assignmentMethod}',
                              style: GoogleFonts.poppins(
                                color: colors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          if (ride.activeAdminLoad != null)
                            Text(
                              'Admin Load Snapshot: ${ride.activeAdminLoad}',
                              style: GoogleFonts.poppins(
                                color: colors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          if (ride.driver != null)
                            Text(
                              'Driver: ${ride.driver}',
                              style: GoogleFonts.poppins(color: colors.textSecondary),
                            ),
                          if (ride.orderId != null && ride.orderId!.isNotEmpty)
                            Text(
                              'Order: ${ride.orderId}',
                              style: GoogleFonts.poppins(color: colors.textSecondary),
                            ),
                          if (ride.note.isNotEmpty)
                            Text(
                              'Note: ${ride.note}',
                              style: GoogleFonts.poppins(color: colors.textSecondary),
                            ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _statusButton(context, ride.id, 'searching'),
                              _statusButton(context, ride.id, 'on_the_way'),
                              _statusButton(
                                context,
                                ride.id,
                                isDelivery ? 'delivery_in_progress' : 'ride_in_progress',
                              ),
                              _statusButton(context, ride.id, 'completed'),
                              _statusButton(context, ride.id, 'cancelled'),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => DriverModeScreen(
                                        ride: ride,
                                        driverName: ride.driver ?? 'Musa',
                                      ),
                                    ),
                                  );
                                },
                                child: Text(isDelivery ? 'Delivery Mode' : 'Driver Mode'),
                              ),
                              if (isSuperAdmin)
                                OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            AdminReassignmentScreen(ride: ride),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.swap_horiz_rounded),
                                  label: const Text('Reassign'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _statusButton(BuildContext context, String rideId, String status) {
    return ElevatedButton(
      onPressed: () async {
        await firebaseService.updateRideStatus(
          rideId: rideId,
          status: status,
        );
      },
      child: Text(status),
    );
  }
}
