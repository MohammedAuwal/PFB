import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/models/ride_model.dart';
import 'package:pfb/services/firebase_service.dart';
import 'package:pfb/shared/widgets/app_page_scaffold.dart';
import 'package:pfb/shared/widgets/app_surface_card.dart';
import 'package:pfb/core/theme/build_context_theme_x.dart';

class RideDetailScreen extends StatelessWidget {
  final RideModel ride;

  const RideDetailScreen({
    super.key,
    required this.ride,
  });

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();
    final isDelivery = ride.type == 'delivery';
    final colors = context.appColors;

    return AppPageScaffold(
      title: isDelivery ? 'Delivery Details' : 'Ride Details',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppSurfaceCard(
            padding: const EdgeInsets.all(18),
            borderRadius: BorderRadius.circular(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${isDelivery ? 'Delivery' : 'Ride'} #${ride.id}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                _info(context, 'Type', ride.type),
                _info(context, 'Pickup', ride.pickup),
                _info(context, 'Destination', ride.destination),
                _info(context, 'Ride Type', ride.rideType),
                _info(context, 'Status', ride.status),
                _info(context, 'Driver', ride.driver ?? 'Not assigned yet'),
                _info(context, 'ETA', ride.eta.isEmpty ? 'Pending' : ride.eta),
                _info(context, 'Distance', '${ride.distanceKm.toStringAsFixed(1)} km'),
                _info(context, 'Duration', '${ride.durationMin.ceil()} mins'),
                _info(context, 'Fare', '₦${ride.price.toStringAsFixed(0)}'),
                if (ride.orderId != null && ride.orderId!.isNotEmpty)
                  _info(context, 'Order', ride.orderId!),
                if (ride.productId != null && ride.productId!.isNotEmpty)
                  _info(context, 'Product', ride.productId!),
                if (ride.note.isNotEmpty) _info(context, 'Note', ride.note),
                const SizedBox(height: 18),
                if (ride.status != 'completed' && ride.status != 'cancelled')
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        await firebaseService.cancelRide(ride.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isDelivery
                                    ? 'Delivery cancelled'
                                    : 'Ride cancelled',
                              ),
                            ),
                          );
                          Navigator.of(context).pop();
                        }
                      },
                      child: Text(isDelivery ? 'Cancel Delivery' : 'Cancel Ride'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _info(BuildContext context, String label, String value) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.poppins(
            color: colors.textPrimary,
            fontSize: 14,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
