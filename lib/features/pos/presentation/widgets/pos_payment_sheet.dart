import 'package:flutter/material.dart';
import 'package:pfb/core/theme/app_theme.dart';
import 'package:pfb/features/pos/data/models/pos_sale_model.dart';

class PosPaymentSheet extends StatefulWidget {
  final double totalAmount;
  final void Function(PosMixedPayment payment) onMixedPaymentChanged;

  const PosPaymentSheet({
    super.key,
    required this.totalAmount,
    required this.onMixedPaymentChanged,
  });

  @override
  State<PosPaymentSheet> createState() => _PosPaymentSheetState();
}

class _PosPaymentSheetState extends State<PosPaymentSheet> {
  final TextEditingController _cashCtrl = TextEditingController(text: '0');
  final TextEditingController _transferCtrl = TextEditingController(text: '0');
  final TextEditingController _posCtrl = TextEditingController(text: '0');

  double get _cashAmount => double.tryParse(_cashCtrl.text) ?? 0;
  double get _transferAmount => double.tryParse(_transferCtrl.text) ?? 0;
  double get _posAmount => double.tryParse(_posCtrl.text) ?? 0;
  double get _enteredTotal => _cashAmount + _transferAmount + _posAmount;
  double get _remaining =>
      (widget.totalAmount - _enteredTotal).clamp(0, double.infinity);
  bool get _isBalanced =>
      (_enteredTotal - widget.totalAmount).abs() < 0.01;

  void _notify() {
    widget.onMixedPaymentChanged(
      PosMixedPayment(
        cashAmount: _cashAmount,
        transferAmount: _transferAmount,
        posAmount: _posAmount,
      ),
    );
  }

  @override
  void dispose() {
    _cashCtrl.dispose();
    _transferCtrl.dispose();
    _posCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPaymentField('Cash', _cashCtrl, Icons.payments_outlined,
              colors),
          const SizedBox(height: 10),
          _buildPaymentField('Bank Transfer', _transferCtrl,
              Icons.account_balance_outlined, colors),
          const SizedBox(height: 10),
          _buildPaymentField('POS Terminal', _posCtrl,
              Icons.credit_card_outlined, colors),
          const SizedBox(height: 14),

          // Balance display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Remaining:',
                style: TextStyle(
                    color: colors.textSecondary, fontSize: 13),
              ),
              Text(
                '₦${_remaining.toStringAsFixed(2)}',
                style: TextStyle(
                  color: _isBalanced ? colors.success : colors.error,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          if (_isBalanced)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: colors.success, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Payment balanced',
                    style: TextStyle(
                      color: colors.success,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentField(
    String label,
    TextEditingController controller,
    IconData icon,
    AppThemeColors colors,
  ) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) {
        setState(() {});
        _notify();
      },
      decoration: InputDecoration(
        labelText: label,
        prefixText: '₦ ',
        prefixIcon: Icon(icon, color: colors.textSecondary),
      ),
    );
  }
}