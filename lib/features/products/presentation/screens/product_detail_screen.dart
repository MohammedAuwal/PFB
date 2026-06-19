import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/config/routes/route_names.dart';
import 'package:pfb/core/routing/app_router.dart';
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
    final go = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Text(
              'Sign in required',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
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
                  style: GoogleFonts.poppins(),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
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
    final isGuest = FirebaseAuth.instance.currentUser == null;
    final colors = context.appColors;

    return AppPageScaffold(
      title: product.name,
      actions: [
        if (!isGuest)
          StreamBuilder<List<String>>(
            stream: firebaseService.watchFavorites(),
            builder: (context, snapshot) {
              final favorites = snapshot.data ?? [];
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
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AspectRatio(
              aspectRatio: 1.1,
              child: _hasValidImage
                  ? Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: context.colorScheme.surfaceContainerHighest,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        color: context.colorScheme.surfaceContainerHighest,
                        child: const Center(
                          child: Icon(Icons.image_not_supported, size: 42),
                        ),
                      ),
                    )
                  : Container(
                      color: context.colorScheme.surfaceContainerHighest,
                      child: const Center(
                        child: Icon(Icons.image_not_supported, size: 42),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (product.isTrending)
                const AppStatusChip(
                  label: 'Trending',
                  tone: AppStatusChipTone.warning,
                  icon: Icons.local_fire_department_rounded,
                ),
              if (product.featured)
                const AppStatusChip(
                  label: 'Featured',
                  tone: AppStatusChipTone.primary,
                  icon: Icons.star_rounded,
                ),
              AppStatusChip(
                label: product.inStock ? 'In Stock' : 'Out of Stock',
                tone: product.inStock
                    ? AppStatusChipTone.success
                    : AppStatusChipTone.error,
                icon: product.inStock
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            product.name,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₦${product.price.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: colors.brandPrimary,
            ),
          ),
          const SizedBox(height: 18),
          const AppSectionTitle(
            title: 'Categories',
            spacingBottom: 6,
          ),
          Text(
            categoryText,
            style: GoogleFonts.poppins(color: colors.textPrimary),
          ),
          const SizedBox(height: 18),
          const AppSectionTitle(
            title: 'Variants',
            spacingBottom: 6,
          ),
          Text(
            variantText,
            style: GoogleFonts.poppins(color: colors.textPrimary),
          ),
          const SizedBox(height: 18),
          const AppSectionTitle(
            title: 'Description',
            spacingBottom: 8,
          ),
          Text(
            product.description,
            style: GoogleFonts.poppins(
              height: 1.6,
              color: colors.textPrimary,
            ),
          ),
          if (isGuest)
            AppSurfaceCard(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(14),
              color: colors.brandPrimary.withOpacity(0.12),
              child: Text(
                'You are browsing as a guest. Sign in to save favorites and track your activity across devices.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: colors.brown,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 28),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: product.inStock
                  ? () async {
                      await firebaseService.addToCart(
                        productId: product.id,
                        name: product.name,
                        price: product.price,
                        imageUrl: product.imageUrl,
                      );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isGuest
                                  ? 'Added to guest cart'
                                  : 'Added to cart',
                            ),
                          ),
                        );
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.brandSecondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Add to Cart',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
