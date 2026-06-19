import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/core/constants/app_constants.dart';
import 'package:pfb/features/admin/presentation/screens/admin_reassignment_screen.dart';
import 'package:pfb/models/order_model.dart';
import 'package:pfb/models/ride_model.dart';
import 'package:pfb/services/firebase_service.dart';
import 'package:pfb/shared/widgets/app_page_scaffold.dart';
import 'package:pfb/shared/widgets/app_section_title.dart';
import 'package:pfb/shared/widgets/app_status_chip.dart';
import 'package:pfb/shared/widgets/app_surface_card.dart';
import 'package:pfb/core/theme/build_context_theme_x.dart';

class AdminEscalationDashboardScreen extends StatelessWidget {
  AdminEscalationDashboardScreen({super.key});

  final FirebaseService _firebaseService = FirebaseService();

  Color _statusColor(BuildContext context, String status) {
    final colors = context.appColors;
    switch (status) {
      case 'completed':
      case 'delivered':
        return colors.success;
      case 'cancelled':
        return colors.error;
      case 'processing':
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
    final isSuperAdmin = AppConstants.isSuperAdminUid(
      _firebaseService.currentUser?.uid,
    );

    return AppPageScaffold(
      title: 'Escalation Dashboard',
      body: !isSuperAdmin
          ? Center(
              child: Text(
                'Only super admin can view escalations',
                style: GoogleFonts.poppins(color: colors.textSecondary),
              ),
            )
          : StreamBuilder<List<RideModel>>(
              stream: _firebaseService.watchEscalatedRides(),
              builder: (context, rideSnapshot) {
                final escalatedRides = rideSnapshot.data ?? [];

                return StreamBuilder<List<OrderModel>>(
                  stream: _firebaseService.watchEscalatedOrders(),
                  builder: (context, orderSnapshot) {
                    final escalatedOrders = orderSnapshot.data ?? [];

                    if (escalatedRides.isEmpty && escalatedOrders.isEmpty) {
                      return Center(
                        child: Text(
                          'No escalated requests right now',
                          style: GoogleFonts.poppins(color: colors.textSecondary),
                        ),
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        AppSurfaceCard(
                          margin: const EdgeInsets.only(bottom: 18),
                          color: colors.brandPrimary.withOpacity(0.10),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: colors.brandPrimary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Escalated requests are items that could not be assigned properly and now require super admin action.',
                                  style: GoogleFonts.poppins(
                                    color: colors.textPrimary,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (escalatedRides.isNotEmpty) ...[
                          const AppSectionTitle(
                            title: 'Escalated Rides & Deliveries',
                            spacingBottom: 12,
                          ),
                          ...escalatedRides.map((ride) {
                            final isDelivery = ride.type == 'delivery';

                            return AppSurfaceCard(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      Text(
                                        isDelivery
                                            ? 'Escalated Delivery'
                                            : 'Escalated Ride',
                                        style: GoogleFonts.poppins(
                                          color: colors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const AppStatusChip(
                                        label: 'Escalated',
                                        tone: AppStatusChipTone.error,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${ride.pickup} → ${ride.destination}',
                                    style: GoogleFonts.poppins(
                                      color: colors.textSecondary,
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
                                  Text(
                                    'Assignment Method: ${ride.assignmentMethod ?? 'unknown'}',
                                    style: GoogleFonts.poppins(
                                      color: colors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                  if ((ride.assignedAdminName ?? '').isNotEmpty)
                                    Text(
                                      'Current Owner: ${ride.assignedAdminName}',
                                      style: GoogleFonts.poppins(
                                        color: colors.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  AdminReassignmentScreen(
                                                ride: ride,
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.swap_horiz_rounded),
                                        label: const Text('Reassign'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          await _firebaseService.updateRideStatus(
                                            rideId: ride.id,
                                            status: 'searching',
                                          );

                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Ride reset to searching'),
                                            ),
                                          );
                                        },
                                        child: const Text('Reset'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                        ],
                        if (escalatedOrders.isNotEmpty) ...[
                          const AppSectionTitle(
                            title: 'Escalated Orders',
                            spacingBottom: 12,
                          ),
                          ...escalatedOrders.map((order) {
                            return AppSurfaceCard(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      Text(
                                        'Escalated Order',
                                        style: GoogleFonts.poppins(
                                          color: colors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const AppStatusChip(
                                        label: 'Escalated',
                                        tone: AppStatusChipTone.error,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Order ID: ${order.id}',
                                    style: GoogleFonts.poppins(
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    'Address: ${order.deliveryAddress}',
                                    style: GoogleFonts.poppins(
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Status: ${order.status}',
                                    style: GoogleFonts.poppins(
                                      color: _statusColor(context, order.status),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Assignment Method: ${order.assignmentMethod}',
                                    style: GoogleFonts.poppins(
                                      color: colors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (order.assignedAdminName.isNotEmpty)
                                    Text(
                                      'Current Owner: ${order.assignedAdminName}',
                                      style: GoogleFonts.poppins(
                                        color: colors.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  AdminReassignmentScreen(
                                                order: order,
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.swap_horiz_rounded),
                                        label: const Text('Reassign'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          await _firebaseService.updateOrderStatus(
                                            orderId: order.id,
                                            status: 'pending',
                                          );

                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Order reset to pending'),
                                            ),
                                          );
                                        },
                                        child: const Text('Reset'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    );
                  },
                );
              },
            ),
    );
  }
}
