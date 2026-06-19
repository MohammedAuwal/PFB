import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/models/payment_session_model.dart';
import 'package:pfb/services/firebase_service.dart';
import 'package:pfb/services/payment_service.dart';
import 'package:pfb/shared/widgets/app_page_scaffold.dart';
import 'package:pfb/shared/widgets/app_surface_card.dart';
import 'package:pfb/core/theme/build_context_theme_x.dart';

class PaystackVerificationScreen extends StatefulWidget {
  final PaymentSessionModel session;

  const PaystackVerificationScreen({
    super.key,
    required this.session,
  });

  @override
  State<PaystackVerificationScreen> createState() =>
      _PaystackVerificationScreenState();
}

class _PaystackVerificationScreenState
    extends State<PaystackVerificationScreen> {
  final PaymentService _paymentService = PaymentService();
  final FirebaseService _firebaseService = FirebaseService();

  bool _verifying = false;
  String? _statusText;

  Future<void> _verifyNow() async {
    if (_verifying) return;

    setState(() {
      _verifying = true;
      _statusText = null;
    });

    try {
      final attempt =
          await _paymentService.getPaymentAttempt(widget.session.reference);

      if (attempt == null) {
        setState(() {
          _statusText = 'Payment attempt not found. Please try again.';
        });
        return;
      }

      await _paymentService.confirmManualPaymentSuccess(widget.session);
      await _firebaseService.placeOrder(widget.session.items);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment confirmed. Order placed successfully.'),
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusText = 'Verification failed: $e';
      });
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppPageScaffold(
      title: 'Verify Payment',
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: AppSurfaceCard(
            padding: const EdgeInsets.all(22),
            borderRadius: BorderRadius.circular(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_rounded,
                  color: colors.brandPrimary,
                  size: 42,
                ),
                const SizedBox(height: 14),
                Text(
                  'Complete Your Payment',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'After completing payment in Paystack, come back here and tap the button below to continue.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: colors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.paleOrange,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reference: ${widget.session.reference}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Amount: ₦${widget.session.amountNaira.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_statusText != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _statusText!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: colors.error,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _verifying ? null : _verifyNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.brandSecondary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _verifying
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'I Have Completed Payment',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
