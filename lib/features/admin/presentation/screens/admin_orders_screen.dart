import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/core/constants/app_constants.dart';
import 'package:pfb/features/admin/presentation/screens/admin_reassignment_screen.dart';
import 'package:pfb/models/order_model.dart';
import 'package:pfb/models/ride_model.dart';
import 'package:pfb/services/firebase_service.dart';
import 'package:pfb/shared/widgets/app_page_scaffold.dart';
import 'package:pfb/shared/widgets/app_status_chip.dart';
import 'package:pfb/shared/widgets/app_surface_card.dart';
import 'package:pfb/core/theme/build_context_theme_x.dart';

class AdminOrdersScreen extends StatelessWidget {
  AdminOrdersScreen({super.key});

  final firebaseService = FirebaseService();

  RideModel? _findDeliveryRide(List<RideModel> rides, OrderModel order) {
    try {
      return rides.firstWhere(
        (ride) => ride.id == order.deliveryRideId || ride.orderId == order.id,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isSuperAdmin = AppConstants.isSuperAdminUid(
      FirebaseAuth.instance.currentUser?.uid,
    );

    return AppPageScaffold(
      title: isSuperAdmin ? 'Manage All Orders' : 'My Assigned Orders',
      body: FutureBuilder<bool>(
        future: firebaseService.isAdmin(),
        builder: (context, adminSnapshot) {
          if (adminSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final isAdmin = adminSnapshot.data ?? false;

          if (!isAdmin && !isSuperAdmin) {
            return Center(
              child: Text(
                'You do not have access to orders',
                style: GoogleFonts.poppins(color: colors.textSecondary),
              ),
            );
          }

          final ordersStream = isSuperAdmin
              ? firebaseService.watchAllOrders()
              : firebaseService.watchAssignedOrdersForAdmin();

          final ridesStream = isSuperAdmin
              ? firebaseService.watchAllRides()
              : firebaseService.watchAssignedRidesForAdmin();

          return StreamBuilder<List<OrderModel>>(
            stream: ordersStream,
            builder: (context, snapshot) {
              final orders = snapshot.data ?? [];

              if (orders.isEmpty) {
                return Center(
                  child: Text(
                    isSuperAdmin
                        ? 'No orders yet'
                        : 'No assigned orders yet',
                    style: GoogleFonts.poppins(color: colors.textSecondary),
                  ),
                );
              }

              return StreamBuilder<List<RideModel>>(
                stream: ridesStream,
                builder: (context, rideSnapshot) {
                  final rides = rideSnapshot.data ?? [];

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.length,
                    itemBuilder: (_, i) {
                      final order = orders[i];
                      final deliveryRide = _findDeliveryRide(rides, order);

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
                                  order.id,
                                  style: GoogleFonts.poppins(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (order.escalatedToSuperAdmin)
                                  const AppStatusChip(
                                    label: 'Escalated',
                                    tone: AppStatusChipTone.error,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Total: ₦${order.totalAmount.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                color: colors.brandPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Order Status: ${order.status}',
                              style: GoogleFonts.poppins(
                                color: colors.textSecondary,
                              ),
                            ),
                            if (order.assignedAdminName.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Assigned Admin: ${order.assignedAdminName}',
                                style: GoogleFonts.poppins(
                                  color: colors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            if (order.assignmentMethod.isNotEmpty)
                              Text(
                                'Assignment: ${order.assignmentMethod}',
                                style: GoogleFonts.poppins(
                                  color: colors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            Text(
                              'Admin Load Snapshot: ${order.activeAdminLoad}',
                              style: GoogleFonts.poppins(
                                color: colors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                            if (order.deliveryAddress.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Delivery Address: ${order.deliveryAddress}',
                                style: GoogleFonts.poppins(
                                  color: colors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            if (deliveryRide != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Delivery Status: ${deliveryRide.status}',
                                style: GoogleFonts.poppins(
                                  color: colors.info,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'ETA: ${deliveryRide.eta} • ${deliveryRide.distanceKm.toStringAsFixed(1)} km',
                                style: GoogleFonts.poppins(
                                  color: colors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _statusButton(context, order.id, 'pending'),
                                _statusButton(context, order.id, 'processing'),
                                _statusButton(context, order.id, 'delivered'),
                                if (isSuperAdmin)
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              AdminReassignmentScreen(order: order),
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
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _statusButton(BuildContext context, String orderId, String status) {
    return ElevatedButton(
      onPressed: () async {
        await firebaseService.updateOrderStatus(
          orderId: orderId,
          status: status,
        );
      },
      child: Text(status),
    );
  }
}
