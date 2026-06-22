import 'package:flutter/material.dart';
import 'package:pfb/core/theme/app_theme.dart';
import 'package:pfb/features/pos/data/models/pos_cart_item_model.dart';

class PosCartItemTile extends StatelessWidget {
  final PosCartItemModel item;
  final void Function(int qty) onQuantityChanged;
  final void Function(double yards) onYardChanged;
  final VoidCallback onRemove;

  const PosCartItemTile({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onYardChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Fabric icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.goldTint,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: colors.brandPrimary.withOpacity(0.2)),
                ),
                child: Icon(Icons.texture_rounded,
                    color: colors.brandPrimary, size: 20),
              ),
              const SizedBox(width: 10),

              // Name + category
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      item.category,
                      style: TextStyle(
                          color: colors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),

              // Remove
              GestureDetector(
                onTap: onRemove,
                child: Icon(Icons.close_rounded,
                    color: colors.error, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Controls row
          Row(
            children: [
              // Quantity stepper
              _buildLabel('Qty', colors),
              const SizedBox(width: 6),
              _buildStepper(
                value: item.quantity,
                min: 1,
                max: 999,
                onChanged: onQuantityChanged,
                colors: colors,
              ),

              const SizedBox(width: 16),

              // Yards stepper
              _buildLabel('Yds', colors),
              const SizedBox(width: 6),
              _buildYardStepper(colors),

              const Spacer(),

              // Line total
              Text(
                '₦${item.lineTotal.toStringAsFixed(0)}',
                style: TextStyle(
                  color: colors.brandPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, AppThemeColors colors) {
    return Text(
      text,
      style: TextStyle(
        color: colors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildStepper({
    required int value,
    required int min,
    required int max,
    required void Function(int) onChanged,
    required AppThemeColors colors,
  }) {
    return Row(
      children: [
        _stepButton(
          icon: Icons.remove_rounded,
          onTap: value > min ? () => onChanged(value - 1) : null,
          colors: colors,
        ),
        Container(
          width: 32,
          alignment: Alignment.center,
          child: Text(
            '$value',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        _stepButton(
          icon: Icons.add_rounded,
          onTap: value < max ? () => onChanged(value + 1) : null,
          colors: colors,
        ),
      ],
    );
  }

  Widget _buildYardStepper(AppThemeColors colors) {
    const step = 0.5;
    final value = item.yardQuantity;
    return Row(
      children: [
        _stepButton(
          icon: Icons.remove_rounded,
          onTap: value > 0.5
              ? () => onYardChanged(double.parse(
                  (value - step).toStringAsFixed(1)))
              : null,
          colors: colors,
        ),
        Container(
          width: 36,
          alignment: Alignment.center,
          child: Text(
            value.toStringAsFixed(1),
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        _stepButton(
          icon: Icons.add_rounded,
          onTap: () => onYardChanged(
              double.parse((value + step).toStringAsFixed(1))),
          colors: colors,
        ),
      ],
    );
  }

  Widget _stepButton({
    required IconData icon,
    required VoidCallback? onTap,
    required AppThemeColors colors,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: onTap != null ? colors.brandPrimary.withOpacity(0.15) : colors.borderSoft,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 14,
          color: onTap != null ? colors.brandPrimary : colors.textSecondary,
        ),
      ),
    );
  }
}