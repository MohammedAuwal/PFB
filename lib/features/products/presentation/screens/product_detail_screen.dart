import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/config/routes/route_names.dart';
import 'package:pfb/core/routing/app_router.dart';
import 'package:pfb/core/theme/app_theme.dart';
import 'package:pfb/models/product_model.dart';
import 'package:pfb/services/firebase_service.dart';
import 'package:pfb/shared/widgets/app_page_scaffold.dart';
import 'package:pfb/shared/widgets/app_section_title.dart';
import 'package:pfb/shared/widgets/app_status_chip.dart';
import 'package:pfb/shared/widgets/app_surface_card.dart';
import 'package:pfb/core/theme/build_context_theme_x.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductModel product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  bool get _hasValidImage =>
      product.imageUrl.trim().isNotEmpty &&
      (product.imageUrl.startsWith('http://') ||
          product.imageUrl.startsWith('https://'));

  Future<void> _promptLogin(BuildContext context, String actionText) async {
    final colors = context.appColors;

    final go = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            // Gold-tinted top border on dialog
            title: Row(
              children: [
                Container(
                  width:  4,
                  height: 20,
                  decoration: BoxDecoration(
                    color:        AppPalette.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Sign in required',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            content: Text(
              'Please sign in or create an account to $actionText.',
              style: GoogleFonts.poppins(fontSize: 13.5, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Later',
                  style: GoogleFonts.poppins(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.primary,
                  foregroundColor: AppPalette.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Sign In',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!go) return;
    if (!context.mounted) return;
    await AppRouter.clearAndGo(context, RouteNames.login);
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();
    final variantText =
        product.variants.isEmpty ? 'No variants' : product.variants.join(', ');
    final categoryText = product.normalizedCategories.join(', ');
    final isGuest      = FirebaseAuth.instance.currentUser == null;
    final colors       = context.appColors;
    final isDark       = context.isDarkMode;

    return AppPageScaffold(
      title: product.name,
      actions: [
        if (!isGuest)
          StreamBuilder<List<String>>(
            stream: firebaseService.watchFavorites(),
            builder: (context, snapshot) {
              final favorites  = snapshot.data ?? [];
              final isFavorite = favorites.contains(product.id);

              return IconButton(
                onPressed: () async {
                  await firebaseService.toggleFavorite(product.id);
                },
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? colors.error : colors.iconPrimary,
                ),
              );
            },
          )
        else
          IconButton(
            onPressed: () => _promptLogin(context, 'save favorites'),
            icon: Icon(
              Icons.favorite_border,
              color: colors.iconPrimary,
            ),
          ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(0),
        children: [
          // ── Product Image with gold overlay at bottom ──────────────────
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft:  Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
                child: AspectRatio(
                  aspectRatio: 1.1,
                  child: _hasValidImage
                      ? Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: context
                                  .colorScheme.surfaceContainerHighest,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: colors.brandPrimary,
                                  strokeWidth: 2.5,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => Container(
                            color: context
                                .colorScheme.surfaceContainerHighest,
                            child: Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size:  42,
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: context
                              .colorScheme.surfaceContainerHighest,
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size:  42,
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                ),
              ),
              // Gold gradient overlay at bottom of image
              Positioned(
                bottom: 0,
                left:   0,
                right:  0,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        colors.scaffold.withOpacity(0.85),
                      ],
                      begin: Alignment.topCenter,
                      end:   Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft:  Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                ),
              ),
              // Price tag overlay — gold pill
              Positioned(
                bottom: 16,
                right:  16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical:   8,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppPalette.primaryDark,
                        AppPalette.primary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color:      AppPalette.primary.withOpacity(0.40),
                        blurRadius: 10,
                        offset:     const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    '₦${product.price.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize:    16,
                      fontWeight:  FontWeight.w800,
                      color:       AppPalette.secondary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Body content ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Status chips ──────────────────────────────────────
                Wrap(
                  spacing:    8,
                  runSpacing: 8,
                  children: [
                    if (product.isTrending)
                      const AppStatusChip(
                        label: 'Trending',
                        tone:  AppStatusChipTone.warning,
                        icon:  Icons.local_fire_department_rounded,
                      ),
                    if (product.featured)
                      const AppStatusChip(
                        label: 'Featured',
                        tone:  AppStatusChipTone.primary,
                        icon:  Icons.star_rounded,
                      ),
                    AppStatusChip(
                      label: product.inStock ? 'In Stock' : 'Out of Stock',
                      tone:  product.inStock
                          ? AppStatusChipTone.success
                          : AppStatusChipTone.error,
                      icon: product.inStock
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Product name ──────────────────────────────────────
                Text(
                  product.name,
                  style: GoogleFonts.poppins(
                    fontSize:    22,
                    fontWeight:  FontWeight.w800,
                    color:       colors.textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),

                const SizedBox(height: 4),

                // ── Category label ────────────────────────────────────
                Text(
                  categoryText,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color:    colors.textSecondary,
                  ),
                ),

                const SizedBox(height: 20),

                // ── Variants ──────────────────────────────────────────
                AppSurfaceCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width:  3,
                            height: 16,
                            decoration: BoxDecoration(
                              color:        colors.brandPrimary,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const AppSectionTitle(
                            title:         'Variants',
                            spacingBottom: 0,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        variantText,
                        style: GoogleFonts.poppins(
                          color:  colors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ── Description ───────────────────────────────────────
                AppSurfaceCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width:  3,
                            height: 16,
                            decoration: BoxDecoration(
                              color:        colors.brandPrimary,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const AppSectionTitle(
                            title:         'Description',
                            spacingBottom: 0,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.description,
                        style: GoogleFonts.poppins(
                          height: 1.6,
                          color:  colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Guest notice card ─────────────────────────────────
                if (isGuest)
                  Container(
                    margin:  const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color:        colors.paleGold,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: colors.brandPrimary.withOpacity(0.25),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: colors.brandPrimary,
                          size:  18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Sign in to save this fabric to your wishlist and track your activity.',
                            style: GoogleFonts.poppins(
                              fontSize:   12,
                              color:      colors.brown,
                              fontWeight: FontWeight.w600,
                              height:     1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 28),

                // ── Add to Cart button — Gold CTA ─────────────────────
                SizedBox(
                  width:  double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: product.inStock
                        ? () async {
                            await firebaseService.addToCart(
                              productId: product.id,
                              name:      product.name,
                              price:     product.price,
                              imageUrl:  product.imageUrl,
                            );

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isGuest
                                        ? 'Added to guest cart'
                                        : '${product.name} added to cart',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                    ),
                                  ),
                                  backgroundColor: AppPalette.secondary,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      // Gold button + black text — luxury CTA
                      backgroundColor: AppPalette.primary,
                      foregroundColor: AppPalette.secondary,
                      elevation:       0,
                      shadowColor:     AppPalette.primary.withOpacity(0.30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.shopping_bag_rounded,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          product.inStock ? 'Add to Cart' : 'Out of Stock',
                          style: GoogleFonts.poppins(
                            fontWeight:   FontWeight.w700,
                            fontSize:     16,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Wishlist button — outlined secondary ──────────────
                if (!isGuest) ...[
                  const SizedBox(height: 12),
                  StreamBuilder<List<String>>(
                    stream: firebaseService.watchFavorites(),
                    builder: (context, snapshot) {
                      final favorites  = snapshot.data ?? [];
                      final isFavorite = favorites.contains(product.id);

                      return SizedBox(
                        width:  double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await firebaseService
                                .toggleFavorite(product.id);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.brandPrimary,
                            side: BorderSide(
                              color: colors.brandPrimary.withOpacity(0.50),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: Icon(
                            isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size:  20,
                            color: isFavorite ? colors.error : null,
                          ),
                          label: Text(
                            isFavorite
                                ? 'Remove from Wishlist'
                                : 'Add to Wishlist',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize:   15,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
