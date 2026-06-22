import 'package:flutter/material.dart';
import 'package:pfb/core/theme/app_theme.dart';
import 'package:pfb/features/pos/data/models/pos_cart_item_model.dart';
import 'package:pfb/features/pos/presentation/widgets/pos_cart_item_tile.dart';

class PosCartPanel extends StatelessWidget {
  final List<PosCartItemModel> items;
  final void Function(String productId, int qty) onQuantityChanged;
  final void Function(String productId, double yards) onYardChanged;
  final void Function(String productId) onRemove;
  final ScrollController? scrollController;

  const PosCartPanel({
    super.key,
    required this.items,
    required this.onQuantityChanged,
    required this.onYardChanged,
    required this.onRemove,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 56,
              color: colors.textSecondary.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Cart is empty',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap a product to add it',
              style: TextStyle(
                color: colors.textSecondary.withOpacity(0.6),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(Icons.shopping_cart_rounded,
                  color: colors.brandPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Cart',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.brandPrimary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${items.length} item${items.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),

        GoldDivider(opacity: 0.3),

        // Cart Items
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            itemBuilder: (_, i) => PosCartItemTile(
              item: items[i],
              onQuantityChanged: (qty) =>
                  onQuantityChanged(items[i].productId, qty),
              onYardChanged: (yard) =>
                  onYardChanged(items[i].productId, yard),
              onRemove: () => onRemove(items[i].productId),
            ),
          ),
        ),
      ],
    );
  }
}