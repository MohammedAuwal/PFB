import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/models/order_model.dart';
import 'package:pfb/models/ride_model.dart';
import 'package:pfb/services/firebase_service.dart';
import 'package:pfb/shared/widgets/app_page_scaffold.dart';
import 'package:pfb/shared/widgets/app_surface_card.dart';
import 'package:pfb/core/theme/build_context_theme_x.dart';

class OrderDetailScreen extends StatelessWidget {
  final OrderModel order;

  const OrderDetailScreen({
    super.key,
    required this.order,
  });

  Color _statusColor(String status, dynamic colors) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return colors.success;
      case 'cancelled':
        return colors.error;
      case 'processing':
        return colors.info;
      default:
        return colors.warning;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      case 'processing':
        return Icons.sync_rounded;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();
    final colors = context.appColors;
    final statusColor = _statusColor(order.status, colors);
    final statusIcon = _statusIcon(order.status);

    final shortId = order.id.length > 16
        ? order.id.substring(0, 16).toUpperCase()
        : order.id.toUpperCase();

    return AppPageScaffold(
      title: 'Order Details',
      body: StreamBuilder<List<RideModel>>(
        stream: firebaseService.watchUserRides(),
        builder: (context, snapshot) {
          final rides = snapshot.data ?? [];

          RideModel? deliveryRide;
          try {
            deliveryRide = rides.firstWhere(
              (ride) =>
                  ride.id == order.deliveryRideId ||
                  ride.orderId == order.id,
            );
          } catch (_) {
            deliveryRide = null;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Order ID + Status Header ───────────────────────
              AppSurfaceCard(
                padding: const EdgeInsets.all(18),
                borderRadius: BorderRadius.circular(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            statusIcon,
                            color: statusColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'IsmailTex Order',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: colors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '#$shortId',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Copy Order ID
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: order.id),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Order ID copied'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.copy_rounded,
                            size: 18,
                            color: colors.textSecondary,
                          ),
                          tooltip: 'Copy Order ID',
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Status Badge
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: statusColor.withOpacity(0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(statusIcon, color: statusColor, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Status: ${order.status.toUpperCase()}',
                            style: GoogleFonts.poppins(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (order.deliveryAddress.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            color: colors.textSecondary,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              order.deliveryAddress,
                              style: GoogleFonts.poppins(
                                color: colors.textPrimary,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── Delivery Tracking Card ────────────────────────
              if (deliveryRide != null) ...[
                AppSurfaceCard(
                  padding: const EdgeInsets.all(18),
                  borderRadius: BorderRadius.circular(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors.brandPrimary
                                  .withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.delivery_dining_rounded,
                              color: colors.brandPrimary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Delivery Tracking',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _TrackingRow(
                        icon: Icons.circle_rounded,
                        label: 'Status',
                        value: deliveryRide.status.toUpperCase(),
                        valueColor: colors.brandPrimary,
                        colors: colors,
                      ),
                      const SizedBox(height: 8),
                      _TrackingRow(
                        icon: Icons.timer_outlined,
                        label: 'ETA',
                        value: deliveryRide.eta.isEmpty
                            ? 'Calculating...'
                            : deliveryRide.eta,
                        colors: colors,
                      ),
                      const SizedBox(height: 8),
                      _TrackingRow(
                        icon: Icons.straighten_rounded,
                        label: 'Distance',
                        value:
                            '${deliveryRide.distanceKm.toStringAsFixed(1)} km',
                        colors: colors,
                      ),
                      const SizedBox(height: 8),
                      _TrackingRow(
                        icon: Icons.payments_outlined,
                        label: 'Delivery Fare',
                        value:
                            '₦${deliveryRide.price.toStringAsFixed(0)}',
                        colors: colors,
                      ),
                      if (deliveryRide.driver != null &&
                          deliveryRide.driver!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _TrackingRow(
                          icon: Icons.person_rounded,
                          label: 'Driver',
                          value: deliveryRide.driver!,
                          colors: colors,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // ── Order Items ───────────────────────────────────
              AppSurfaceCard(
                padding: const EdgeInsets.all(18),
                borderRadius: BorderRadius.circular(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.brandPrimary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.inventory_2_outlined,
                            color: colors.brandPrimary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Order Items',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: colors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${order.items.length} item${order.items.length == 1 ? '' : 's'}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...order.items.asMap().entries.map((entry) {
                      final i = entry.key;
                      final item = entry.value;
                      final itemTotal =
                          (((item['price'] ?? 0) as num).toDouble() *
                              ((item['qty'] ?? 1) as int));
                      final isLast = i == order.items.length - 1;

                      return Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: colors.brandPrimary
                                      .withOpacity(0.10),
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    '${i + 1}',
                                    style: GoogleFonts.poppins(
                                      color: colors.brandPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (item['name'] ?? '').toString(),
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        color: colors.textPrimary,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    Text(
                                      '₦${((item['price'] ?? 0) as num).toDouble().toStringAsFixed(2)} × ${item['qty']}',
                                      style: GoogleFonts.poppins(
                                        color: colors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '₦${itemTotal.toStringAsFixed(2)}',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  color: colors.brandPrimary,
                                  fontSize: 13.5,
                                ),
                              ),
                            ],
                          ),
                          if (!isLast)
                            Divider(
                              height: 20,
                              color: colors.borderSoft,
                            ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── Total Summary ─────────────────────────────────
              AppSurfaceCard(
                padding: const EdgeInsets.all(18),
                borderRadius: BorderRadius.circular(22),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          'Items Total',
                          style: GoogleFonts.poppins(
                            color: colors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '₦${order.totalAmount.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    if (deliveryRide != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Delivery Fee',
                            style: GoogleFonts.poppins(
                              color: colors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '₦${deliveryRide.price.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: colors.brandPrimary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Grand Total',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: colors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '₦${(order.totalAmount + (deliveryRide?.price ?? 0)).toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: colors.brandPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── ITEX Footer ───────────────────────────────────
              Center(
                child: Text(
                  'IsmailTex · ITEX · Powered by Paystack',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: colors.textSecondary.withOpacity(0.6),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}

// ── Tracking Row Helper ────────────────────────────────────────────────────────

class _TrackingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final dynamic colors;
  final Color? valueColor;

  const _TrackingRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: colors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            color: colors.textSecondary,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: valueColor ?? colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
