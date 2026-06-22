// lib/features/pos/presentation/screens/pos_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:pfb/config/routes/route_names.dart';
import 'package:pfb/core/theme/app_theme.dart';
import 'package:pfb/features/pos/data/models/pos_cart_item_model.dart';
import 'package:pfb/features/pos/data/models/pos_sale_model.dart';
import 'package:pfb/features/pos/data/repositories/pos_repository.dart';
import 'package:pfb/features/pos/presentation/screens/pos_checkout_screen.dart';
import 'package:pfb/features/pos/presentation/widgets/pos_cart_panel.dart';
import 'package:pfb/features/pos/presentation/widgets/pos_discount_sheet.dart';
import 'package:pfb/features/pos/presentation/widgets/pos_product_search_panel.dart';
import 'package:pfb/features/pos/presentation/widgets/pos_totals_panel.dart';
import 'package:pfb/models/product_model.dart';

class PosDashboardScreen extends StatefulWidget {
  const PosDashboardScreen({super.key});

  @override
  State<PosDashboardScreen> createState() =>
      _PosDashboardScreenState();
}

class _PosDashboardScreenState
    extends State<PosDashboardScreen> {
  final PosRepository _repo = PosRepository();

  final List<PosCartItemModel> _cartItems = [];
  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];

  String _searchQuery = '';
  double _discountValue = 0;
  PosDiscountType _discountType = PosDiscountType.none;
  String _discountReason = '';

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final size = MediaQuery.sizeOf(context);
    final isDesktop = size.width >= 1024;
    final isTablet =
        size.width >= 600 && size.width < 1024;

    return Scaffold(
      backgroundColor: colors.scaffold,
      appBar: _buildAppBar(colors),
      body: StreamBuilder<List<ProductModel>>(
        stream: _repo.watchAllProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
                  ConnectionState.waiting &&
              _allProducts.isEmpty) {
            return Center(
              child: CircularProgressIndicator(
                  color: colors.brandPrimary),
            );
          }

          if (snapshot.hasData) {
            _allProducts = snapshot.data!;
            _filteredProducts = _repo.searchProducts(
              _allProducts,
              _searchQuery,
            );
          }

          if (isDesktop) {
            return _buildDesktopLayout(colors);
          }
          if (isTablet) {
            return _buildTabletLayout(colors);
          }
          return _buildMobileLayout(colors);
        },
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  AppBar _buildAppBar(AppThemeColors colors) {
    return AppBar(
      backgroundColor: colors.scaffold,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_rounded,
            color: colors.textPrimary),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppGradients.goldVertical,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.point_of_sale_rounded,
              color: colors.textOnGold,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'POS Terminal',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Text(
                'Physical Shop Sales',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(
                      color: colors.brandPrimary,
                    ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Cart count indicator
        if (_cartItems.isNotEmpty)
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: AppGradients.goldHorizontal,
                borderRadius:
                    BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.shopping_cart_rounded,
                    color: Colors.black,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_cartItems.length}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ── Desktop Layout ────────────────────────────────────────────────────────

  Widget _buildDesktopLayout(AppThemeColors colors) {
    return Row(
      children: [
        // Left 55%: Product search
        Expanded(
          flex: 55,
          child: PosProductSearchPanel(
            products: _filteredProducts,
            searchQuery: _searchQuery,
            onSearchChanged: _onSearchChanged,
            onProductTapped: _addToCart,
          ),
        ),
        VerticalDivider(
            width: 1, color: colors.borderSoft),
        // Right 45%: Cart + Totals
        Expanded(
          flex: 45,
          child: Column(
            children: [
              Expanded(
                child: PosCartPanel(
                  items: _cartItems,
                  onQuantityChanged: _updateQuantity,
                  onYardChanged: _updateYard,
                  onRemove: _removeItem,
                ),
              ),
              Divider(
                  height: 1, color: colors.borderSoft),
              PosTotalsPanel(
                cartItems: _cartItems,
                discountValue: _discountValue,
                discountType: _discountType,
                discountReason: _discountReason,
                repo: _repo,
                onDiscountChanged: _onDiscountChanged,
                onCheckout: _navigateToCheckout,
                isLoading: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Tablet Layout ─────────────────────────────────────────────────────────

  Widget _buildTabletLayout(AppThemeColors colors) {
    return Row(
      children: [
        Expanded(
          child: PosProductSearchPanel(
            products: _filteredProducts,
            searchQuery: _searchQuery,
            onSearchChanged: _onSearchChanged,
            onProductTapped: _addToCart,
          ),
        ),
        VerticalDivider(
            width: 1, color: colors.borderSoft),
        SizedBox(
          width: 340,
          child: Column(
            children: [
              Expanded(
                child: PosCartPanel(
                  items: _cartItems,
                  onQuantityChanged: _updateQuantity,
                  onYardChanged: _updateYard,
                  onRemove: _removeItem,
                ),
              ),
              Divider(
                  height: 1, color: colors.borderSoft),
              PosTotalsPanel(
                cartItems: _cartItems,
                discountValue: _discountValue,
                discountType: _discountType,
                discountReason: _discountReason,
                repo: _repo,
                onDiscountChanged: _onDiscountChanged,
                onCheckout: _navigateToCheckout,
                isLoading: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Mobile Layout ─────────────────────────────────────────────────────────

  Widget _buildMobileLayout(AppThemeColors colors) {
    return Column(
      children: [
        Expanded(
          child: PosProductSearchPanel(
            products: _filteredProducts,
            searchQuery: _searchQuery,
            onSearchChanged: _onSearchChanged,
            onProductTapped: _addToCart,
          ),
        ),
        // Sticky cart bar at bottom
        if (_cartItems.isNotEmpty)
          GestureDetector(
            onTap: _showMobileCartSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: AppGradients.goldHorizontal,
                boxShadow: [
                  BoxShadow(
                    color: AppPalette.primary
                        .withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color:
                          Colors.black.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_cartItems.length}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'View Cart',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Text(
                    '₦${_repo.calculateSubtotal(_cartItems).toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showMobileCartSheet() {
    final colors = AppTheme.colorsOf(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.85,
              maxChildSize: 0.95,
              minChildSize: 0.4,
              builder: (_, controller) {
                return Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.borderSoft,
                        borderRadius:
                            BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: PosCartPanel(
                        items: _cartItems,
                        onQuantityChanged: (id, qty) {
                          _updateQuantity(id, qty);
                          setSheetState(() {});
                          setState(() {});
                        },
                        onYardChanged: (id, yard) {
                          _updateYard(id, yard);
                          setSheetState(() {});
                          setState(() {});
                        },
                        onRemove: (id) {
                          _removeItem(id);
                          setSheetState(() {});
                          setState(() {});
                        },
                        scrollController: controller,
                      ),
                    ),
                    Divider(
                        height: 1,
                        color: colors.borderSoft),
                    PosTotalsPanel(
                      cartItems: _cartItems,
                      discountValue: _discountValue,
                      discountType: _discountType,
                      discountReason: _discountReason,
                      repo: _repo,
                      onDiscountChanged:
                          _onDiscountChanged,
                      onCheckout: () {
                        Navigator.pop(ctx);
                        _navigateToCheckout();
                      },
                      isLoading: false,
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // ── Cart Actions ──────────────────────────────────────────────────────────

  void _addToCart(ProductModel product) {
    // Check stock before adding
    if (product.stockQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${product.name} is out of stock'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      final existingIndex = _cartItems
          .indexWhere((i) => i.productId == product.id);
      if (existingIndex >= 0) {
        final existing = _cartItems[existingIndex];
        // Do not exceed available stock
        final newQty = existing.quantity + 1;
        if (newQty > product.stockQuantity) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Only ${product.stockQuantity} units available'),
            ),
          );
          return;
        }
        _cartItems[existingIndex] =
            existing.copyWith(quantity: newQty);
      } else {
        _cartItems
            .add(PosCartItemModel.fromProduct(product));
      }
    });

    _showAddedFeedback(product.name);
  }

  void _updateQuantity(String productId, int qty) {
    setState(() {
      final index = _cartItems
          .indexWhere((i) => i.productId == productId);
      if (index < 0) return;
      if (qty <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index] =
            _cartItems[index].copyWith(quantity: qty);
      }
    });
  }

  void _updateYard(String productId, double yards) {
    setState(() {
      final index = _cartItems
          .indexWhere((i) => i.productId == productId);
      if (index < 0) return;
      final safeYards = yards <= 0 ? 1.0 : yards;
      _cartItems[index] =
          _cartItems[index].copyWith(yardQuantity: safeYards);
    });
  }

  void _removeItem(String productId) {
    setState(() {
      _cartItems
          .removeWhere((i) => i.productId == productId);
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _filteredProducts =
          _repo.searchProducts(_allProducts, query);
    });
  }

  void _onDiscountChanged({
    required double value,
    required PosDiscountType type,
    required String reason,
  }) {
    setState(() {
      _discountValue = value;
      _discountType = type;
      _discountReason = reason;
    });
  }

  void _showAddedFeedback(String productName) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text('$productName added'),
          ],
        ),
        duration: const Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Checkout Navigation ───────────────────────────────────────────────────

  void _navigateToCheckout() {
    if (_cartItems.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PosCheckoutScreen(
          cartItems: List.from(_cartItems),
          discountValue: _discountValue,
          discountType: _discountType,
          discountReason: _discountReason,
          repo: _repo,
          onSaleCompleted: (sale) {
            // Clear cart after successful sale
            setState(() {
              _cartItems.clear();
              _discountValue = 0;
              _discountType = PosDiscountType.none;
              _discountReason = '';
            });

            // Navigate to receipt using named route
            if (mounted) {
              Navigator.of(context).pushNamed(
                RouteNames.posReceipt,
                arguments: sale,
              );
            }
          },
        ),
      ),
    );
  }
}