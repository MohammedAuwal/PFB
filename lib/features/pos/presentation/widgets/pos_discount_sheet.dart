import 'package:flutter/material.dart';
import 'package:pfb/core/theme/app_theme.dart';
import 'package:pfb/features/pos/data/models/pos_sale_model.dart';

class PosDiscountSheet extends StatefulWidget {
  final double currentValue;
  final PosDiscountType currentType;
  final String currentReason;
  final double subtotal;
  final void Function({
    required double value,
    required PosDiscountType type,
    required String reason,
  }) onApply;

  const PosDiscountSheet({
    super.key,
    required this.currentValue,
    required this.currentType,
    required this.currentReason,
    required this.subtotal,
    required this.onApply,
  });

  @override
  State<PosDiscountSheet> createState() => _PosDiscountSheetState();
}

class _PosDiscountSheetState extends State<PosDiscountSheet> {
  late PosDiscountType _type;
  late TextEditingController _valueCtrl;
  late TextEditingController _reasonCtrl;

  @override
  void initState() {
    super.initState();
    _type = widget.currentType == PosDiscountType.none
        ? PosDiscountType.percentage
        : widget.currentType;
    _valueCtrl =
        TextEditingController(text: widget.currentValue > 0 ? widget.currentValue.toString() : '');
    _reasonCtrl = TextEditingController(text: widget.currentReason);
  }

  @override
  void dispose() {
    _valueCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  double get _previewDiscount {
    final v = double.tryParse(_valueCtrl.text) ?? 0;
    if (_type == PosDiscountType.percentage) {
      return (v / 100) * widget.subtotal;
    }
    return v.clamp(0, widget.subtotal).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final keyboardPadding = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + keyboardPadding),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.borderSoft,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            'Apply Discount',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 20),

          // Type Selector
          Row(
            children: [
              _typeButton(PosDiscountType.percentage, 'Percentage (%)', colors),
              const SizedBox(width: 12),
              _typeButton(PosDiscountType.fixed, 'Fixed Amount (₦)', colors),
            ],
          ),
          const SizedBox(height: 16),

          // Value Field
          TextField(
            controller: _valueCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: _type == PosDiscountType.percentage
                  ? 'Enter percentage (e.g. 10)'
                  : 'Enter amount (e.g. 500)',
              prefixText: _type == PosDiscountType.fixed ? '₦ ' : '',
              suffixText: _type == PosDiscountType.percentage ? '%' : '',
              prefixIcon: Icon(Icons.discount_outlined,
                  color: colors.textSecondary),
            ),
          ),
          const SizedBox(height: 12),

          // Reason field
          TextField(
            controller: _reasonCtrl,
            decoration: InputDecoration(
              hintText: 'Discount reason (e.g. Loyal customer)',
              prefixIcon: Icon(Icons.note_outlined,
                  color: colors.textSecondary),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),

          // Preview
          if (_previewDiscount > 0)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.paleGold,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: colors.brandPrimary.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Discount Preview:',
                    style: TextStyle(
                        color: colors.textSecondary, fontSize: 13),
                  ),
                  Text(
                    '-₦${_previewDiscount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: colors.brandPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              // Clear
              if (widget.currentValue > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.onApply(
                        value: 0,
                        type: PosDiscountType.none,
                        reason: '',
                      );
                      Navigator.pop(context);
                    },
                    child: const Text('Clear'),
                  ),
                ),
              if (widget.currentValue > 0) const SizedBox(width: 12),

              // Apply
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    final v = double.tryParse(_valueCtrl.text) ?? 0;
                    if (v <= 0) return;
                    widget.onApply(
                      value: v,
                      type: _type,
                      reason: _reasonCtrl.text.trim(),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Apply Discount'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _typeButton(
      PosDiscountType type, String label, AppThemeColors colors) {
    final isSelected = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? colors.brandPrimary : colors.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? colors.brandPrimary : colors.border,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.black : colors.textSecondary,
              fontWeight:
                  isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}