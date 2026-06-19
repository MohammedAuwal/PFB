import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/models/payment_config_model.dart';
import 'package:pfb/services/payment_service.dart';
import 'package:pfb/shared/widgets/app_page_scaffold.dart';
import 'package:pfb/shared/widgets/app_section_title.dart';
import 'package:pfb/shared/widgets/app_surface_card.dart';
import 'package:pfb/core/theme/build_context_theme_x.dart';

class PaymentSettingsScreen extends StatefulWidget {
  const PaymentSettingsScreen({super.key});

  @override
  State<PaymentSettingsScreen> createState() => _PaymentSettingsScreenState();
}

class _PaymentSettingsScreenState extends State<PaymentSettingsScreen> {
  final PaymentService _paymentService = PaymentService();

  final _rideBaseFareCtrl = TextEditingController();
  final _ridePricePerKmCtrl = TextEditingController();
  final _deliveryBaseFareCtrl = TextEditingController();
  final _deliveryPricePerKmCtrl = TextEditingController();
  final _paystackPublicKeyCtrl = TextEditingController();

  bool _paystackEnabled = true;
  bool _loading = false;
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    _paymentService.seedPaymentConfigIfMissing();
  }

  Future<void> _save() async {
    final rideBaseFare = double.tryParse(_rideBaseFareCtrl.text.trim());
    final ridePricePerKm =
        double.tryParse(_ridePricePerKmCtrl.text.trim());
    final deliveryBaseFare =
        double.tryParse(_deliveryBaseFareCtrl.text.trim());
    final deliveryPricePerKm =
        double.tryParse(_deliveryPricePerKmCtrl.text.trim());

    if (rideBaseFare == null ||
        ridePricePerKm == null ||
        deliveryBaseFare == null ||
        deliveryPricePerKm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid numeric pricing values'),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await _paymentService.updatePaymentConfig(
        paystackEnabled: _paystackEnabled,
        activeGateway: 'paystack',
        rideBaseFare: rideBaseFare,
        ridePricePerKm: ridePricePerKm,
        deliveryBaseFare: deliveryBaseFare,
        deliveryPricePerKm: deliveryPricePerKm,
        paystackPublicKey: _paystackPublicKeyCtrl.text.trim(),
        enabledGateways: ['paystack'],
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment and pricing settings updated'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update settings: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _rideBaseFareCtrl.dispose();
    _ridePricePerKmCtrl.dispose();
    _deliveryBaseFareCtrl.dispose();
    _deliveryPricePerKmCtrl.dispose();
    _paystackPublicKeyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppPageScaffold(
      title: 'Payment & Pricing Settings',
      body: StreamBuilder<PaymentConfigModel>(
        stream: _paymentService.watchPaymentConfig(),
        builder: (context, snapshot) {
          final config = snapshot.data;

          if (config != null && !_seeded) {
            _seeded = true;
            _paystackEnabled = config.paystackEnabled;
            _rideBaseFareCtrl.text = config.rideBaseFare.toStringAsFixed(0);
            _ridePricePerKmCtrl.text = config.ridePricePerKm.toStringAsFixed(0);
            _deliveryBaseFareCtrl.text =
                config.deliveryBaseFare.toStringAsFixed(0);
            _deliveryPricePerKmCtrl.text =
                config.deliveryPricePerKm.toStringAsFixed(0);
            _paystackPublicKeyCtrl.text = config.paystackPublicKey;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppSurfaceCard(
                padding: const EdgeInsets.all(18),
                borderRadius: BorderRadius.circular(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppSectionTitle(
                      title: 'Live Pricing & Payment Control',
                      subtitle:
                          'Update payment gateway behavior and pricing from one place. Users will use the latest values without requiring a full app update.',
                      spacingBottom: 16,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: colors.brandPrimary,
                      value: _paystackEnabled,
                      onChanged: (value) {
                        setState(() => _paystackEnabled = value);
                      },
                      title: Text(
                        'Enable Paystack',
                        style: GoogleFonts.poppins(color: colors.textPrimary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _Field(
                      controller: _paystackPublicKeyCtrl,
                      hint: 'Paystack public key',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _Field(
                            controller: _rideBaseFareCtrl,
                            hint: 'Ride base fare',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _Field(
                            controller: _ridePricePerKmCtrl,
                            hint: 'Ride / km',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _Field(
                            controller: _deliveryBaseFareCtrl,
                            hint: 'Delivery base fare',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _Field(
                            controller: _deliveryPricePerKmCtrl,
                            hint: 'Delivery / km',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _save,
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                'Save Settings',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(color: colors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: colors.textSecondary),
        filled: true,
        fillColor: colors.surfaceAlt,
      ),
    );
  }
}
