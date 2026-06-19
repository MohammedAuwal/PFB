import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/config/routes/route_names.dart';
import 'package:pfb/core/theme/app_theme.dart';
import 'package:pfb/features/auth/presentation/screens/login_screen.dart';
import 'package:pfb/features/cart/presentation/screens/paystack_verification_screen.dart';
import 'package:pfb/features/rider/presentation/screens/ride_estimate_map_preview_screen.dart';
import 'package:pfb/models/payment_session_model.dart';
import 'package:pfb/services/firebase_service.dart';
import 'package:pfb/services/payment_service.dart';

class CartScreen extends StatefulWidget {
  final bool showScaffold;

  const CartScreen({super.key, this.showScaffold = true});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final FirebaseService firebaseService = FirebaseService();
  final PaymentService paymentService = PaymentService();

  bool _loadingDeliveryEstimate = false;
  bool _processingCheckout = false;
  String? _deliveryEstimateError;
  MovementEstimate? _deliveryEstimate;
  String _lastEstimatedAddress = '';
  String _vendorPickupAddress = '';

  bool get _isGuest => FirebaseAuth.instance.currentUser == null;

  bool _hasValidImage(String url) {
    final value = url.trim();
    return value.isNotEmpty &&
        (value.startsWith('http://') || value.startsWith('https://'));
  }

  Future<void> _goToLogin() async {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(
          redirectTo: RouteNames.redirectCart,
        ),
      ),
    );
  }

  Future<void> _showGuestCheckoutPrompt() async {
    final go = await showDialog<bool>(
          context: context,
          builder: (ctx) {
            final colors = AppTheme.colorsOf(ctx);

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    color: colors.brandPrimary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sign In Required',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              content: Text(
                'Please sign in or create an IsmailTex account to continue with checkout and delivery tracking.',
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  height: 1.5,
                  color: colors.textSecondary,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('Later', style: GoogleFonts.poppins()),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.brandPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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

  Future<void> _estimateDelivery(String selectedAddress) async {
    if (_isGuest) {
      await _showGuestCheckoutPrompt();
      return;
    }

    if (selectedAddress.trim().isEmpty) {
      setState(() {
        _deliveryEstimate = null;
        _deliveryEstimateError =
            'Please select a saved delivery address before checkout';
      });
      return;
    }

    setState(() {
      _loadingDeliveryEstimate = true;
      _deliveryEstimateError = null;
    });

    try {
      final vendorPickup = await firebaseService.getVendorPickupAddress();

      final estimate = await firebaseService.estimateMovement(
        type: 'delivery',
        pickup: vendorPickup,
        destination: selectedAddress,
      );

      if (!mounted) return;
      setState(() {
        _deliveryEstimate = estimate;
        _lastEstimatedAddress = selectedAddress;
        _vendorPickupAddress = vendorPickup;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _deliveryEstimate = null;
        _deliveryEstimateError = e.toString();
      });
    } finally {
      if (mounted) setState(() => _loadingDeliveryEstimate = false);
    }
  }

  Future<void> _checkout(
    List<Map<String, dynamic>> cartItems,
    double grandTotal,
    double itemsTotal,
  ) async {
    if (_isGuest) {
      await _showGuestCheckoutPrompt();
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || (user.email ?? '').trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A valid signed-in email is required for payment'),
        ),
      );
      return;
    }

    if (_deliveryEstimate == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please check delivery estimate before checkout'),
        ),
      );
      return;
    }

    setState(() => _processingCheckout = true);

    try {
      final result = await paymentService.initializeCheckout(
        userUid: user.uid,
        email: user.email!,
        amountNaira: grandTotal,
        items: cartItems,
        metadata: {
          'type': 'cart_checkout',
          'userId': user.uid,
          'itemsCount': cartItems.length,
          'itemsTotal': itemsTotal,
          'deliveryFee': _deliveryEstimate!.price,
          'distanceKm': _deliveryEstimate!.distanceKm,
          'eta': _deliveryEstimate!.eta,
        },
      );

      if (!result.success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
        return;
      }

      final opened = await paymentService
          .openCheckoutUrl(result.authorizationUrl);

      if (!opened) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open Paystack checkout'),
          ),
        );
        return;
      }

      if (!mounted) return;

      final session = PaymentSessionModel(
        reference: result.reference,
        userUid: user.uid,
        email: user.email!,
        amountNaira: grandTotal,
        currency: 'NGN',
        items: cartItems,
        metadata: {
          'type': 'cart_checkout',
          'userId': user.uid,
          'itemsCount': cartItems.length,
          'itemsTotal': itemsTotal,
          'deliveryFee': _deliveryEstimate!.price,
          'distanceKm': _deliveryEstimate!.distanceKm,
          'eta': _deliveryEstimate!.eta,
        },
      );

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PaystackVerificationScreen(session: session),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checkout failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _processingCheckout = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    final content = StreamBuilder<List<Map<String, dynamic>>>(
      stream: firebaseService.watchCart(),
      builder: (context, snapshot) {
        final cartItems = snapshot.data ?? [];

        final total = cartItems.fold<double>(
          0,
          (sum, item) =>
              sum +
              (((item['price'] ?? 0) as num).toDouble() *
                  ((item['qty'] ?? 1) as int)),
        );

        // ── Empty Cart ───────────────────────────────────────────
        if (cartItems.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: colors.brandPrimary.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shopping_cart_outlined,
                      size: 48,
                      color: colors.brandPrimary.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Your cart is empty',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add products from the IsmailTex store to get started.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: colors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return StreamBuilder<String>(
          stream: firebaseService.watchSelectedAddress(),
          builder: (context, addressSnapshot) {
            final selectedAddress = addressSnapshot.data ?? '';

            if (_lastEstimatedAddress != selectedAddress &&
                _deliveryEstimate != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() {
                  _deliveryEstimate = null;
                  _deliveryEstimateError = null;
                });
              });
            }

            final deliveryFee = _deliveryEstimate?.price ?? 0;
            final grandTotal = total + deliveryFee;

            return CustomScrollView(
              slivers: [
                // ── Guest Banner ─────────────────────────────────
                if (_isGuest)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colors.brandPrimary.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colors.brandPrimary.withOpacity(0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: colors.brandPrimary
                                    .withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person_outline_rounded,
                                color: colors.brown,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Shopping as guest. Sign in to complete checkout, save addresses, and track orders on IsmailTex.',
                                style: GoogleFonts.poppins(
                                  color: colors.brown,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: _goToLogin,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                              ),
                              child: Text(
                                'Sign In',
                                style: GoogleFonts.poppins(
                                  color: colors.brandPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // ── Cart Item Count Header ────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 18,
                          decoration: BoxDecoration(
                            color: colors.brandPrimary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${cartItems.length} item${cartItems.length == 1 ? '' : 's'} in cart',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Cart Items List ───────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final item = cartItems[i];
                        final qty = (item['qty'] ?? 1) as int;
                        final imageUrl =
                            (item['imageUrl'] ?? '').toString();
                        final itemTotal =
                            ((item['price'] ?? 0) as num).toDouble() *
                                qty;

                        return Container(
                          margin:
                              const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colors.card,
                            borderRadius: BorderRadius.circular(18),
                            border:
                                Border.all(color: colors.borderSoft),
                            boxShadow: [
                              BoxShadow(
                                color: colors.shadow,
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Product Image
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: _hasValidImage(imageUrl)
                                      ? Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (_, __, ___) =>
                                                  Container(
                                            color: colors.brandPrimary
                                                .withOpacity(0.15),
                                            child: Icon(
                                              Icons
                                                  .shopping_bag_outlined,
                                              color:
                                                  colors.brandPrimary,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          color: colors.brandPrimary
                                              .withOpacity(0.15),
                                          child: Icon(
                                            Icons.shopping_bag_outlined,
                                            color: colors.brandPrimary,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Product Info
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
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '₦${((item['price'] ?? 0) as num).toDouble().toStringAsFixed(2)} each',
                                      style: GoogleFonts.poppins(
                                        color: colors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Subtotal: ₦${itemTotal.toStringAsFixed(2)}',
                                      style: GoogleFonts.poppins(
                                        color: colors.brandPrimary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Qty Controls
                              Container(
                                decoration: BoxDecoration(
                                  color: colors.surfaceAlt,
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  border: Border.all(
                                      color: colors.borderSoft),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InkWell(
                                      onTap: () async {
                                        await firebaseService
                                            .updateCartQty(
                                          productId: item['productId']
                                              .toString(),
                                          qty: qty - 1,
                                        );
                                      },
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.all(8),
                                        child: Icon(
                                          Icons
                                              .remove_rounded,
                                          size: 18,
                                          color: qty <= 1
                                              ? colors.textSecondary
                                              : colors.brandPrimary,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets
                                          .symmetric(horizontal: 8),
                                      child: Text(
                                        '$qty',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w700,
                                          color: colors.textPrimary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () async {
                                        await firebaseService
                                            .updateCartQty(
                                          productId: item['productId']
                                              .toString(),
                                          qty: qty + 1,
                                        );
                                      },
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.all(8),
                                        child: Icon(
                                          Icons.add_rounded,
                                          size: 18,
                                          color: colors.brandPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: cartItems.length,
                    ),
                  ),
                ),

                // ── Order Summary + Checkout ──────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: colors.borderSoft),
                      boxShadow: [
                        BoxShadow(
                          color: colors.shadow,
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colors.brandPrimary
                                    .withOpacity(0.12),
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.summarize_rounded,
                                color: colors.brandPrimary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Order Summary',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Delivery Address Row
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (_isGuest ||
                                    selectedAddress.isEmpty)
                                ? colors.error.withOpacity(0.07)
                                : colors.brandPrimary
                                    .withOpacity(0.07),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: (_isGuest ||
                                      selectedAddress.isEmpty)
                                  ? colors.error.withOpacity(0.25)
                                  : colors.brandPrimary
                                      .withOpacity(0.20),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                (_isGuest || selectedAddress.isEmpty)
                                    ? Icons.location_off_outlined
                                    : Icons.location_on_rounded,
                                color: (_isGuest ||
                                        selectedAddress.isEmpty)
                                    ? colors.error
                                    : colors.brandPrimary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _isGuest
                                      ? 'Sign in to select a delivery address'
                                      : (selectedAddress.isEmpty
                                          ? 'No delivery address selected — go to Profile'
                                          : selectedAddress),
                                  style: GoogleFonts.poppins(
                                    color: (_isGuest ||
                                            selectedAddress.isEmpty)
                                        ? colors.error
                                        : colors.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Estimate Error
                        if (_deliveryEstimateError != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin:
                                const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: colors.error.withOpacity(0.08),
                              borderRadius:
                                  BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    colors.error.withOpacity(0.25),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  color: colors.error,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _deliveryEstimateError!,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: colors.error,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Delivery Estimate Card
                        if (_deliveryEstimate != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            margin:
                                const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: colors.paleOrange
                                  .withOpacity(0.5),
                              borderRadius:
                                  BorderRadius.circular(16),
                              border: Border.all(
                                color: colors.brandPrimary
                                    .withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons
                                          .delivery_dining_rounded,
                                      color: colors.brandPrimary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Delivery Estimate',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                _EstimateRow(
                                  icon: Icons.store_outlined,
                                  label: 'IsmailTex Pickup',
                                  value:
                                      _deliveryEstimate!.pickupLabel,
                                  colors: colors,
                                ),
                                const SizedBox(height: 6),
                                _EstimateRow(
                                  icon: Icons.flag_outlined,
                                  label: 'Destination',
                                  value: _deliveryEstimate!
                                      .destinationLabel,
                                  colors: colors,
                                ),
                                const SizedBox(height: 6),
                                _EstimateRow(
                                  icon: Icons.straighten_rounded,
                                  label: 'Distance',
                                  value:
                                      '${_deliveryEstimate!.distanceKm.toStringAsFixed(1)} km',
                                  colors: colors,
                                ),
                                _EstimateRow(
                                  icon: Icons.timer_outlined,
                                  label: 'ETA',
                                  value: _deliveryEstimate!.eta,
                                  colors: colors,
                                ),
                                const SizedBox(height: 4),
                                _EstimateRow(
                                  icon: Icons.payments_outlined,
                                  label: 'Delivery Fee',
                                  value:
                                      '₦${_deliveryEstimate!.price.toStringAsFixed(0)}',
                                  colors: colors,
                                  highlight: true,
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              RideEstimateMapPreviewScreen(
                                            estimate:
                                                _deliveryEstimate!,
                                            title:
                                                'Delivery Route Preview',
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                        Icons.map_outlined,
                                        size: 18),
                                    label: Text(
                                      'Preview Delivery Route',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Check Delivery Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _loadingDeliveryEstimate
                                ? null
                                : () =>
                                    _estimateDelivery(selectedAddress),
                            icon: _loadingDeliveryEstimate
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colors.brandPrimary,
                                    ),
                                  )
                                : const Icon(
                                    Icons.local_shipping_outlined,
                                    size: 18,
                                  ),
                            label: Text(
                              _loadingDeliveryEstimate
                                  ? 'Estimating...'
                                  : (_isGuest
                                      ? 'Sign In to Estimate'
                                      : (_deliveryEstimate != null
                                          ? 'Re-check Delivery'
                                          : 'Check Delivery Estimate')),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 12),

                        // Price Breakdown
                        _PriceRow(
                          label: 'Items Total',
                          value: '₦${total.toStringAsFixed(2)}',
                          colors: colors,
                        ),
                        const SizedBox(height: 8),
                        _PriceRow(
                          label: 'Delivery Fee',
                          value: _deliveryEstimate == null
                              ? (_isGuest
                                  ? 'Sign in first'
                                  : 'Estimate required')
                              : '₦${deliveryFee.toStringAsFixed(2)}',
                          colors: colors,
                          valueColor: _deliveryEstimate == null
                              ? colors.textSecondary
                              : colors.brandPrimary,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: colors.brandPrimary
                                .withOpacity(0.07),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Grand Total',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '₦${grandTotal.toStringAsFixed(2)}',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                  color: colors.brandPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Checkout Button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: _processingCheckout
                                ? null
                                : () => _checkout(
                                      cartItems,
                                      grandTotal,
                                      total,
                                    ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.brandPrimary,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(16),
                              ),
                            ),
                            icon: _processingCheckout
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.lock_outline_rounded,
                                    size: 20,
                                  ),
                            label: Text(
                              _processingCheckout
                                  ? 'Processing...'
                                  : (_isGuest
                                      ? 'Sign In to Checkout'
                                      : 'Proceed to Checkout'),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Trust Badge
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_user_outlined,
                                size: 13,
                                color: colors.textSecondary
                                    .withOpacity(0.6),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Secured by Paystack · IsmailTex',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: colors.textSecondary
                                      .withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (!widget.showScaffold) {
      return Scaffold(
        backgroundColor: colors.scaffold,
        body: SafeArea(child: content),
      );
    }

    return Scaffold(
      backgroundColor: colors.scaffold,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.shopping_cart_rounded,
              color: colors.brandPrimary,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              'My Cart',
              style: GoogleFonts.poppins(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: firebaseService.watchCart(),
            builder: (context, snap) {
              final count = snap.data?.length ?? 0;
              if (count == 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.brandPrimary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$count item${count == 1 ? '' : 's'}',
                      style: GoogleFonts.poppins(
                        color: colors.brandPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: content,
    );
  }
}

// ── Estimate Row Helper ────────────────────────────────────────────────────────

class _EstimateRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final dynamic colors;
  final bool highlight;

  const _EstimateRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 15, color: colors.textSecondary),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: colors.textSecondary,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight:
                    highlight ? FontWeight.w700 : FontWeight.w600,
                color: highlight ? colors.brandPrimary : colors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Price Row Helper ───────────────────────────────────────────────────────────

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final dynamic colors;
  final Color? valueColor;

  const _PriceRow({
    required this.label,
    required this.value,
    required this.colors,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: colors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: valueColor ?? colors.textPrimary,
          ),
        ),
      ],
    );
  }
}
