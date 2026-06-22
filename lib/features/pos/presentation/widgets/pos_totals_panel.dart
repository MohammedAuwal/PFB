import 'package:flutter/material.dart';
import 'package:pfb/core/theme/app_theme.dart';
import 'package:pfb/features/pos/data/models/pos_cart_item_model.dart';
import 'package:pfb/features/pos/data/models/pos_sale_model.dart';
import 'package:pfb/features/pos/data/repositories/pos_repository.dart';
import 'package:pfb/features/pos/presentation/widgets/pos_discount_sheet.dart';

class PosTotalsPanel extends StatelessWidget {
  final List<PosCartItemModel> cartItems;
  final double discountValue;
  final PosDiscountType discountType;
  final String discountReason;
  final PosRepository repo;
  final void Function({
    required double value,
    required PosDiscountType type,
    required String reason,
  }) onDiscountChanged;
  final VoidCallback onCheckout;
  final bool isLoading;

  const PosTotalsPanel({
    super.key,
    required this.cartItems,
    required this.discountValue,
    required this.discountType,
    required this.discountReason,
    required this.repo,
    required this.onDiscountChanged,
    required this.onCheckout,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final subtotal = repo.calculateSubtotal(cartItems);
    final discountAmount = repo.calculateDiscount(
      subtotal: subtotal,
      discountValue: discountValue,
      discountType: discountType,
    );
    final finalTotal = repo.calculateFinalTotal(
      subtotal: subtotal,
      discountAmount: discountAmount,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Subtotal row
          _buildRow('Subtotal', subtotal, colors),
          const SizedBox(height: 6),

          // Discount row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => _openDiscountSheet(context, subtotal),
                child: Row(
                  children: [
                    Icon(Icons.discount_outlined,
                        color: colors.brandPrimary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      discountType == PosDiscountType.none
                          ? 'Add Discount'
                          : 'Discount (${discountType == PosDiscountType.percentage ? '${discountValue.toStringAsFixed(0)}%' : '₦${discountValue.toStringAsFixed(0)}'})',
                      style: TextStyle(
                        color: colors.brandPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
              if (discountAmount > 0)
                Text(
                  '-₦${discountAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: colors.success,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),
          GoldDivider(opacity: 0.5),
          const SizedBox(height: 10),

          // Final total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  letterSpacing: 1,
                ),
              ),
              Text(
                '₦${finalTotal.toStringAsFixed(2)}',
                style: TextStyle(
                  color: colors.brandPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Checkout button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: cartItems.isEmpty || isLoading ? null : onCheckout,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.payment_rounded, size: 20),
              label: Text(
                isLoading ? 'Processing...' : 'Checkout  ₦${finalTotal.toStringAsFixed(0)}',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: colors.borderSoft,
                disabledForegroundColor: colors.textSecondary,
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, double amount, AppThemeColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: colors.textSecondary, fontSize: 13),
        ),
        Text(
          '₦${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  void _openDiscountSheet(BuildContext context, double subtotal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => PosDiscountSheet(
        currentValue: discountValue,
        currentType: discountType,
        currentReason: discountReason,
        subtotal: subtotal,
        onApply: onDiscountChanged,
      ),
    );
  }
}