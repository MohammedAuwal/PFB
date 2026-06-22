// lib/features/pos/presentation/screens/pos_checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:pfb/core/theme/app_theme.dart';
import 'package:pfb/features/pos/data/models/pos_cart_item_model.dart';
import 'package:pfb/features/pos/data/models/pos_sale_model.dart';
import 'package:pfb/features/pos/data/repositories/pos_repository.dart';
import 'package:pfb/features/pos/presentation/widgets/pos_payment_sheet.dart';
import 'package:pfb/services/firebase_service.dart';
import 'package:google_fonts/google_fonts.dart';

class PosCheckoutScreen extends StatefulWidget {
  final List<PosCartItemModel> cartItems;
  final double discountValue;
  final PosDiscountType discountType;
  final String discountReason;
  final PosRepository repo;

  /// Called after sale is committed to Firestore.
  /// The dashboard uses this to clear cart + navigate to receipt.
  final void Function(PosSaleModel sale) onSaleCompleted;

  const PosCheckoutScreen({
    super.key,
    required this.cartItems,
    required this.discountValue,
    required this.discountType,
    required this.discountReason,
    required this.repo,
    required this.onSaleCompleted,
  });

  @override
  State<PosCheckoutScreen> createState() =>
      _PosCheckoutScreenState();
}

class _PosCheckoutScreenState
    extends State<PosCheckoutScreen> {
  final FirebaseService _firebaseService =
      FirebaseService();
  final TextEditingController _customerNameCtrl =
      TextEditingController();
  final TextEditingController _customerPhoneCtrl =
      TextEditingController();
  final TextEditingController _tenderedCtrl =
      TextEditingController();

  PosPaymentMethod _selectedPayment =
      PosPaymentMethod.cash;
  PosMixedPayment? _mixedPayment;
  double _amountTendered = 0;
  bool _isProcessing = false;

  late final double _subtotal;
  late final double _discountAmount;
  late final double _finalTotal;

  @override
  void initState() {
    super.initState();
    _subtotal =
        widget.repo.calculateSubtotal(widget.cartItems);
    _discountAmount = widget.repo.calculateDiscount(
      subtotal: _subtotal,
      discountValue: widget.discountValue,
      discountType: widget.discountType,
    );
    _finalTotal = widget.repo.calculateFinalTotal(
      subtotal: _subtotal,
      discountAmount: _discountAmount,
    );
    _amountTendered = _finalTotal;
    _tenderedCtrl.text =
        _finalTotal.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _tenderedCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return Scaffold(
      backgroundColor: colors.scaffold,
      appBar: AppBar(
        backgroundColor: colors.scaffold,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Checkout',
          style: GoogleFonts.poppins(
            color: colors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _isProcessing
          ? _buildProcessingView(colors)
          : _buildForm(colors),
    );
  }

  // ── Processing View ───────────────────────────────────────────────────────

  Widget _buildProcessingView(AppThemeColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppGradients.goldVertical,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.point_of_sale_rounded,
              color: Colors.black,
              size: 36,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Processing Sale...',
            style: GoogleFonts.poppins(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          CircularProgressIndicator(
              color: colors.brandPrimary),
        ],
      ),
    );
  }

  // ── Checkout Form ─────────────────────────────────────────────────────────

  Widget _buildForm(AppThemeColors colors) {
    final change = widget.repo.calculateChange(
      amountTendered: _amountTendered,
      finalTotal: _finalTotal,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Order Summary ────────────────────────────
          _buildOrderSummary(colors),
          const SizedBox(height: 20),

          // ── Customer Details (optional) ──────────────
          _buildSectionLabel(
              'Customer Details', colors,
              optional: true),
          const SizedBox(height: 12),
          _buildCustomerFields(colors),
          const SizedBox(height: 20),

          // ── Payment Method ───────────────────────────
          _buildSectionLabel(
              'Payment Method', colors),
          const SizedBox(height: 12),
          _buildPaymentMethodSelector(colors),
          const SizedBox(height: 20),

          // ── Cash: amount tendered ────────────────────
          if (_selectedPayment ==
              PosPaymentMethod.cash) ...[
            _buildSectionLabel(
                'Amount Tendered', colors),
            const SizedBox(height: 12),
            _buildTenderedField(colors),
            const SizedBox(height: 12),
            if (change > 0)
              _buildChangeDisplay(colors, change),
            const SizedBox(height: 20),
          ],

          // ── Mixed Payment ────────────────────────────
          if (_selectedPayment ==
              PosPaymentMethod.mixed) ...[
            _buildSectionLabel(
                'Mixed Payment Breakdown', colors),
            const SizedBox(height: 12),
            PosPaymentSheet(
              totalAmount: _finalTotal,
              onMixedPaymentChanged: (mp) {
                setState(() => _mixedPayment = mp);
              },
            ),
            const SizedBox(height: 20),
          ],

          // ── Complete Button ──────────────────────────
          _buildCompleteButton(colors),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(AppThemeColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.borderGold.withOpacity(0.4),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppGradients.goldHorizontal,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                    Icons.receipt_long_rounded,
                    color: Colors.black,
                    size: 20),
                const SizedBox(width: 10),
                Text(
                  'Order Summary',
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Text(
                  '${widget.cartItems.length} item${widget.cartItems.length != 1 ? 's' : ''}',
                  style: GoogleFonts.poppins(
                    color: Colors.black.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Items
          ...widget.cartItems.map(
              (item) => _buildItemRow(item, colors)),

          // Divider
          Divider(
              height: 1, color: colors.borderSoft),

          // Totals
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildAmountRow(
                    'Subtotal', _subtotal, colors),
                if (widget.discountType !=
                        PosDiscountType.none &&
                    widget.discountValue > 0) ...[
                  const SizedBox(height: 6),
                  _buildAmountRow(
                    widget.discountType ==
                            PosDiscountType.percentage
                        ? 'Discount (${widget.discountValue.toStringAsFixed(0)}%)'
                        : 'Discount',
                    -_discountAmount,
                    colors,
                    isDiscount: true,
                  ),
                ],
                const SizedBox(height: 10),
                GoldDivider(opacity: 0.5),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL',
                      style: GoogleFonts.poppins(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      '₦${_finalTotal.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        color: colors.brandPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(
      PosCartItemModel item, AppThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: GoogleFonts.poppins(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${item.quantity} unit${item.quantity != 1 ? 's' : ''}'
                  ' × ${item.yardQuantity.toStringAsFixed(1)} yds',
                  style: GoogleFonts.poppins(
                    color: colors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₦${item.lineTotal.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(
    String label,
    double amount,
    AppThemeColors colors, {
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: colors.textSecondary,
            fontSize: 13,
          ),
        ),
        Text(
          isDiscount
              ? '-₦${amount.abs().toStringAsFixed(2)}'
              : '₦${amount.toStringAsFixed(2)}',
          style: GoogleFonts.poppins(
            color: isDiscount
                ? colors.success
                : colors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(
    String title,
    AppThemeColors colors, {
    bool optional = false,
  }) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        if (optional) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colors.borderSoft,
              borderRadius:
                  BorderRadius.circular(999),
            ),
            child: Text(
              'Optional',
              style: GoogleFonts.poppins(
                color: colors.textSecondary,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCustomerFields(
      AppThemeColors colors) {
    return Column(
      children: [
        TextField(
          controller: _customerNameCtrl,
          decoration: InputDecoration(
            hintText: 'Customer name',
            prefixIcon: Icon(
                Icons.person_outline_rounded,
                color: colors.textSecondary),
          ),
          style:
              TextStyle(color: colors.textPrimary),
          textCapitalization:
              TextCapitalization.words,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _customerPhoneCtrl,
          decoration: InputDecoration(
            hintText: 'Phone number',
            prefixIcon: Icon(
                Icons.phone_outlined,
                color: colors.textSecondary),
          ),
          style:
              TextStyle(color: colors.textPrimary),
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSelector(
      AppThemeColors colors) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: PosPaymentMethod.values.map((method) {
        final isSelected =
            _selectedPayment == method;
        return GestureDetector(
          onTap: () => setState(() {
            _selectedPayment = method;
            _mixedPayment = null;
          }),
          child: AnimatedContainer(
            duration:
                const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.brandPrimary
                  : colors.surface,
              borderRadius:
                  BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? colors.brandPrimary
                    : colors.border,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: colors.brandPrimary
                            .withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _paymentIcon(method),
                  color: isSelected
                      ? Colors.black
                      : colors.textSecondary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  method.label,
                  style: GoogleFonts.poppins(
                    color: isSelected
                        ? Colors.black
                        : colors.textPrimary,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _paymentIcon(PosPaymentMethod method) {
    switch (method) {
      case PosPaymentMethod.cash:
        return Icons.payments_outlined;
      case PosPaymentMethod.bankTransfer:
        return Icons.account_balance_outlined;
      case PosPaymentMethod.posTerminal:
        return Icons.credit_card_outlined;
      case PosPaymentMethod.mixed:
        return Icons.shuffle_rounded;
    }
  }

  Widget _buildTenderedField(
      AppThemeColors colors) {
    return TextField(
      controller: _tenderedCtrl,
      keyboardType:
          const TextInputType.numberWithOptions(
              decimal: true),
      onChanged: (v) {
        setState(() {
          _amountTendered =
              double.tryParse(v) ?? _finalTotal;
        });
      },
      decoration: InputDecoration(
        prefixText: '₦ ',
        hintText: _finalTotal.toStringAsFixed(2),
        prefixIcon: Icon(Icons.payments_outlined,
            color: colors.textSecondary),
      ),
      style: GoogleFonts.poppins(
        color: colors.textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 18,
      ),
    );
  }

  Widget _buildChangeDisplay(
      AppThemeColors colors, double change) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.paleGreen,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.success.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.change_circle_outlined,
              color: colors.success),
          const SizedBox(width: 10),
          Text(
            'Change: ',
            style: GoogleFonts.poppins(
              color: colors.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            '₦${change.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              color: colors.success,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteButton(
      AppThemeColors colors) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isProcessing ? null : _completeSale,
        icon: _isProcessing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2,
                ),
              )
            : const Icon(
                Icons.check_circle_rounded,
                size: 22),
        label: Text(
          _isProcessing
              ? 'Processing...'
              : 'Complete Sale',
        ),
        style: ElevatedButton.styleFrom(
          padding:
              const EdgeInsets.symmetric(vertical: 18),
          disabledBackgroundColor: colors.borderSoft,
          disabledForegroundColor:
              colors.textSecondary,
          textStyle: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // ── Complete Sale ─────────────────────────────────────────────────────────

  Future<void> _completeSale() async {
    final user = _firebaseService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please log in to complete sale'),
        ),
      );
      return;
    }

    // Validate mixed payment totals
    if (_selectedPayment == PosPaymentMethod.mixed) {
      if (_mixedPayment == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Please enter mixed payment amounts'),
          ),
        );
        return;
      }
      if ((_mixedPayment!.total - _finalTotal).abs() >
          0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Mixed payment total '
              '(₦${_mixedPayment!.total.toStringAsFixed(2)}) '
              'must equal ₦${_finalTotal.toStringAsFixed(2)}',
            ),
          ),
        );
        return;
      }
    }

    // Validate cash tendered
    if (_selectedPayment == PosPaymentMethod.cash &&
        _amountTendered < _finalTotal) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Amount tendered '
            '(₦${_amountTendered.toStringAsFixed(2)}) '
            'is less than total '
            '(₦${_finalTotal.toStringAsFixed(2)})',
          ),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final sale = await widget.repo.completeSale(
        cartItems: widget.cartItems,
        cashierUid: user.uid,
        // ── Null-safe displayName fallback ────────
        cashierName: (user.displayName?.isNotEmpty ??
                false)
            ? user.displayName!
            : (user.email?.split('@').first ?? 'Cashier'),
        cashierEmail: user.email ?? '',
        customerName:
            _customerNameCtrl.text.trim(),
        customerPhone:
            _customerPhoneCtrl.text.trim(),
        discountValue: widget.discountValue,
        discountType: widget.discountType,
        discountReason: widget.discountReason,
        paymentMethod: _selectedPayment,
        mixedPayment: _mixedPayment,
        amountTendered: _amountTendered,
      );

      // Pop checkout screen first
      if (!mounted) return;
      Navigator.of(context).pop();

      // Trigger dashboard callback — clears cart + navigates to receipt
      widget.onSaleCompleted(sale);
    } catch (e) {
      setState(() => _isProcessing = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sale failed: $e'),
          backgroundColor: AppTheme.colorsOf(context).error,
        ),
      );
    }
  }
}