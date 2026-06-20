import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/models/order_model.dart';
import 'package:pfb/services/firebase_service.dart';
import 'package:pfb/shared/widgets/app_page_scaffold.dart';
import 'package:pfb/shared/widgets/app_section_title.dart';
import 'package:pfb/shared/widgets/app_surface_card.dart';
import 'package:pfb/core/theme/build_context_theme_x.dart';

// ── Admin Reassignment Screen ──────────────────────────────────────────────────
// Orders only — no ride/RideModel references.

class AdminReassignmentScreen extends StatelessWidget {
  final OrderModel order;

  AdminReassignmentScreen({
    super.key,
    required this.order,
  });

  final FirebaseService _firebaseService = FirebaseService();

  Future<void> _reassignTo(
    BuildContext context,
    Map<String, dynamic> admin,
  ) async {
    final uid = (admin['uid'] ?? '').toString();
    final email = (admin['email'] ?? '').toString();
    final name =
        (admin['displayName'] ?? email).toString();

    if (uid.isEmpty) return;

    try {
      await _firebaseService.reassignOrderToAdmin(
        orderId: order.id,
        adminUid: uid,
        adminName: name,
        adminEmail: email,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order reassigned to $name successfully',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: context.appColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reassignment failed: $e'),
          backgroundColor: context.appColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppPageScaffold(
      title: 'Reassign Order',
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firebaseService.watchAdmins(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final admins = snapshot.data ?? [];

          if (admins.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    size: 56,
                    color: colors.textSecondary.withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Admins Available',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add admin accounts before reassigning orders.',
                    style: GoogleFonts.poppins(
                      color: colors.textSecondary,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Order summary card ─────────────────────────
              AppSurfaceCard(
                margin: const EdgeInsets.only(bottom: 20),
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                colors.brandPrimary.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.receipt_long_rounded,
                            color: colors.brandPrimary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order #${order.shortId}',
                                style: GoogleFonts.poppins(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                'Total: ₦${order.totalAmount.toStringAsFixed(0)}',
                                style: GoogleFonts.poppins(
                                  color: colors.brandPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (order.deliveryAddress.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: colors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              order.deliveryAddress,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (order.assignedAdminName.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colors.warning.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colors.warning.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.swap_horiz_rounded,
                              size: 14,
                              color: colors.warning,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Currently assigned to: ${order.assignedAdminName}',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: colors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Admin list header ──────────────────────────
              const AppSectionTitle(
                title: 'Select New Admin',
                spacingBottom: 12,
              ),

              // ── Admin cards ────────────────────────────────
              ...admins.map((admin) {
                final displayName =
                    (admin['displayName'] ?? admin['email'] ?? '')
                        .toString();
                final email = (admin['email'] ?? '').toString();
                final baseAddress =
                    (admin['baseAddress'] ?? '').toString();
                final isActive =
                    (admin['isActive'] ?? true) == true;
                final maxLoad =
                    ((admin['maxActiveAssignments'] ?? 20) as num)
                        .toInt();
                final coverageStates = List<String>.from(
                    admin['coverageStates'] ?? []);

                final isCurrentAdmin =
                    (admin['uid'] ?? '') == order.assignedAdminUid;

                return AppSurfaceCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  borderRadius: BorderRadius.circular(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 22,
                            backgroundColor:
                                colors.brandPrimary.withOpacity(0.12),
                            child: Text(
                              displayName.isNotEmpty
                                  ? displayName[0].toUpperCase()
                                  : 'A',
                              style: GoogleFonts.poppins(
                                color: colors.brandPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        displayName,
                                        style: GoogleFonts.poppins(
                                          color: colors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    if (isCurrentAdmin) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colors.brandPrimary
                                              .withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Current',
                                          style: GoogleFonts.poppins(
                                            color: colors.brandPrimary,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  email,
                                  style: GoogleFonts.poppins(
                                    color: colors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Status row
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _InfoChip(
                            icon: isActive
                                ? Icons.check_circle_rounded
                                : Icons.pause_circle_rounded,
                            label: isActive ? 'Active' : 'Paused',
                            color: isActive
                                ? colors.success
                                : colors.warning,
                          ),
                          _InfoChip(
                            icon: Icons.work_outline_rounded,
                            label: 'Max: $maxLoad orders',
                            color: colors.info,
                          ),
                          if (coverageStates.isNotEmpty)
                            _InfoChip(
                              icon: Icons.map_outlined,
                              label: coverageStates.take(2).join(', '),
                              color: colors.textSecondary,
                            ),
                        ],
                      ),

                      if (baseAddress.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: colors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                baseAddress,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: colors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 12),

                      // Assign button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isCurrentAdmin
                              ? null
                              : () => _reassignTo(context, admin),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isCurrentAdmin
                                ? colors.surfaceAlt
                                : colors.brandPrimary,
                            foregroundColor: isCurrentAdmin
                                ? colors.textSecondary
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: Icon(
                            isCurrentAdmin
                                ? Icons.check_rounded
                                : Icons.assignment_ind_rounded,
                            size: 16,
                          ),
                          label: Text(
                            isCurrentAdmin
                                ? 'Already Assigned'
                                : 'Assign This Admin',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
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

// ── Info Chip ──────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
