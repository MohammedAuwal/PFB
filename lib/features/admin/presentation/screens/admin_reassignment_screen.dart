import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/models/order_model.dart';
import 'package:pfb/models/ride_model.dart';
import 'package:pfb/services/firebase_service.dart';
import 'package:pfb/shared/widgets/app_page_scaffold.dart';
import 'package:pfb/shared/widgets/app_section_title.dart';
import 'package:pfb/shared/widgets/app_surface_card.dart';
import 'package:pfb/core/theme/build_context_theme_x.dart';

class AdminReassignmentScreen extends StatelessWidget {
  final RideModel? ride;
  final OrderModel? order;

  AdminReassignmentScreen({
    super.key,
    this.ride,
    this.order,
  }) : assert(ride != null || order != null);

  final FirebaseService _firebaseService = FirebaseService();

  Future<void> _reassignTo(
    BuildContext context,
    Map<String, dynamic> admin,
  ) async {
    final uid = (admin['uid'] ?? '').toString();
    final email = (admin['email'] ?? '').toString();
    final name = (admin['displayName'] ?? email).toString();

    if (uid.isEmpty) return;

    if (ride != null) {
      await _firebaseService.reassignRideToAdmin(
        rideId: ride!.id,
        adminUid: uid,
        adminName: name,
        adminEmail: email,
      );
    }

    if (order != null) {
      await _firebaseService.reassignOrderToAdmin(
        orderId: order!.id,
        adminUid: uid,
        adminName: name,
        adminEmail: email,
      );
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Request reassigned successfully'),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final title = ride != null
        ? (ride!.type == 'delivery' ? 'Reassign Delivery' : 'Reassign Ride')
        : 'Reassign Order';

    final subtitle = ride != null
        ? '${ride!.pickup} → ${ride!.destination}'
        : order!.deliveryAddress;

    return AppPageScaffold(
      title: title,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firebaseService.watchAdmins(),
        builder: (context, snapshot) {
          final admins = snapshot.data ?? [];

          if (admins.isEmpty) {
            return Center(
              child: Text(
                'No admins available',
                style: GoogleFonts.poppins(color: colors.textSecondary),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppSurfaceCard(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppSectionTitle(
                      title: 'Request Details',
                      spacingBottom: 8,
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              AppSectionTitle(
                title: 'Choose Admin',
                spacingBottom: 12,
              ),
              ...admins.map((admin) {
                final displayName =
                    (admin['displayName'] ?? admin['email'] ?? '').toString();
                final email = (admin['email'] ?? '').toString();
                final baseAddress = (admin['baseAddress'] ?? '').toString();
                final isActive = (admin['isActive'] ?? true) == true;
                final maxLoad =
                    ((admin['maxActiveAssignments'] ?? 20) as num).toInt();

                return AppSurfaceCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(14),
                    title: Text(
                      displayName,
                      style: GoogleFonts.poppins(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: GoogleFonts.poppins(
                            color: colors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        if (baseAddress.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              baseAddress,
                              style: GoogleFonts.poppins(
                                color: colors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            isActive
                                ? 'Active • Max load: $maxLoad'
                                : 'Paused • Max load: $maxLoad',
                            style: GoogleFonts.poppins(
                              color: isActive
                                  ? colors.success
                                  : colors.warning,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => _reassignTo(context, admin),
                      child: Text(
                        'Assign',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
