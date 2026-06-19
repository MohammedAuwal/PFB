import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/core/constants/app_constants.dart';
import 'package:pfb/features/admin/presentation/screens/edit_product_screen.dart';
import 'package:pfb/features/products/presentation/screens/product_detail_screen.dart';
import 'package:pfb/models/product_model.dart';
import 'package:pfb/services/firebase_service.dart';
import 'package:pfb/shared/widgets/app_page_scaffold.dart';
import 'package:pfb/shared/widgets/app_surface_card.dart';
import 'package:pfb/core/theme/build_context_theme_x.dart';

class ManageProductsScreen extends StatelessWidget {
  ManageProductsScreen({super.key});

  final FirebaseService _firebaseService = FirebaseService();

  bool get _isSuperAdmin => AppConstants.isSuperAdminUid(
        FirebaseAuth.instance.currentUser?.uid,
      );

  bool _hasValidImage(String url) {
    final value = url.trim();
    return value.isNotEmpty &&
        (value.startsWith('http://') || value.startsWith('https://'));
  }

  Future<void> _deleteProduct(BuildContext context, ProductModel product) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (!_isSuperAdmin && currentUid != product.createdBy) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only delete your own products'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete Product'),
            content: Text('Delete "${product.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    await _firebaseService.deleteProduct(product.id);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Product deleted'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final Stream<List<ProductModel>> stream = _isSuperAdmin
        ? _firebaseService.watchAllProducts()
        : _firebaseService.watchMyUploadedProducts();

    return AppPageScaffold(
      title: _isSuperAdmin ? 'Manage Products' : 'My Products',
      body: StreamBuilder<List<ProductModel>>(
        stream: stream,
        builder: (context, snapshot) {
          final products = snapshot.data ?? [];

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (products.isEmpty) {
            return Center(
              child: Text(
                _isSuperAdmin
                    ? 'No products yet'
                    : 'You have not uploaded any products yet',
                style: GoogleFonts.poppins(color: colors.textSecondary),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final product = products[index];
              final canManage = _isSuperAdmin ||
                  product.createdBy == FirebaseAuth.instance.currentUser?.uid;

              return AppSurfaceCard(
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(20),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 58,
                      height: 58,
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
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '₦${product.price.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            color: colors.brandPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.normalizedCategories.join(', '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: colors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        if (_isSuperAdmin && product.createdBy.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Created by: ${product.createdBy}',
                            style: GoogleFonts.poppins(
                              color: colors.textSecondary.withOpacity(0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    color: colors.surfaceAlt,
                    iconColor: colors.iconPrimary,
                    onSelected: (value) async {
                      if (value == 'preview') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(product: product),
                          ),
                        );
                      } else if (value == 'edit') {
                        if (!canManage) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('You can only edit your own products'),
                            ),
                          );
                          return;
                        }

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EditProductScreen(product: product),
                          ),
                        );
                      } else if (value == 'delete') {
                        if (!canManage) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('You can only delete your own products'),
                            ),
                          );
                          return;
                        }

                        await _deleteProduct(context, product);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'preview',
                        child: Text(
                          'Preview',
                          style: GoogleFonts.poppins(color: colors.textPrimary),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(
                          'Edit',
                          style: GoogleFonts.poppins(color: colors.textPrimary),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Delete',
                          style: GoogleFonts.poppins(color: colors.error),
                        ),
                      ),
                    ],
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
