import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/features/products/presentation/screens/product_detail_screen.dart';
import 'package:pfb/services/firebase_service.dart';
import 'package:pfb/shared/widgets/app_page_scaffold.dart';
import 'package:pfb/shared/widgets/app_surface_card.dart';
import 'package:pfb/core/theme/build_context_theme_x.dart';

class FavoritesScreen extends StatelessWidget {
  FavoritesScreen({super.key});

  final firebaseService = FirebaseService();

  bool _hasValidImage(String url) {
    final value = url.trim();
    return value.isNotEmpty &&
        (value.startsWith('http://') || value.startsWith('https://'));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppPageScaffold(
      title: 'Favorites',
      body: StreamBuilder(
        stream: firebaseService.watchFavoriteProducts(),
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return Center(
              child: Text(
                'No favorite products yet',
                style: GoogleFonts.poppins(
                  color: colors.textPrimary,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final product = items[i];

              return AppSurfaceCard(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(0),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(product: product),
                    ),
                  );
                },
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: _hasValidImage(product.imageUrl)
                          ? Image.network(
                              product.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: context.colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: colors.textSecondary,
                                ),
                              ),
                            )
                          : Container(
                              color: context.colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.image_not_supported,
                                color: colors.textSecondary,
                              ),
                            ),
                    ),
                  ),
                  title: Text(
                    product.name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    '₦${product.price.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      color: colors.brandPrimary,
                    ),
                  ),
                  trailing: IconButton(
                    onPressed: () async {
                      await firebaseService.toggleFavorite(product.id);
                    },
                    icon: Icon(
                      Icons.favorite,
                      color: colors.error,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
