import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/config/routes/route_names.dart';
import 'package:pfb/core/routing/app_router.dart';
import 'package:pfb/models/product_model.dart';
import 'package:pfb/services/firebase_service.dart';
import 'package:pfb/shared/widgets/app_status_chip.dart';
import 'package:pfb/shared/widgets/app_surface_card.dart';
import 'package:pfb/core/theme/build_context_theme_x.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState
    extends State<ProductDetailScreen> {
  final _firebaseService = FirebaseService();

  int _selectedImageIndex = 0;
  String? _selectedColor;
  String? _selectedSize;
  bool _addingToCart = false;
  bool _descExpanded = false;

  // All images (primary + additional)
  List<String> get _allImages {
    final images = <String>[];
    if (_hasValidUrl(widget.product.imageUrl)) {
      images.add(widget.product.imageUrl);
    }
    for (final img in widget.product.additionalImages) {
      if (_hasValidUrl(img) && !images.contains(img)) {
        images.add(img);
      }
    }
    return images;
  }

  bool _hasValidUrl(String url) {
    final v = url.trim();
    return v.isNotEmpty &&
        (v.startsWith('http://') || v.startsWith('https://'));
  }

  bool get _isGuest =>
      FirebaseAuth.instance.currentUser == null;

  ProductModel get _product => widget.product;

  Future<void> _promptLogin(String action) async {
    final go = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Sign In Required',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700),
            ),
            content: Text(
              'Please sign in to $action.',
              style:
                  GoogleFonts.poppins(fontSize: 13.5, height: 1.5),
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
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!go || !mounted) return;
    await AppRouter.clearAndGo(context, RouteNames.login);
  }

  Future<void> _addToCart() async {
    if (!_product.inStock) return;

    setState(() => _addingToCart = true);
    try {
      await _firebaseService.addToCart(
        productId: _product.id,
        name: _product.name,
        price: _product.hasDiscount
            ? _product.discountedPrice
            : _product.price,
        imageUrl: _product.imageUrl,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                '${_product.name} added to cart!',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor:
              context.appColors.brandPrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) setState(() => _addingToCart = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final images = _allImages;

    return Scaffold(
      backgroundColor: colors.scaffold,
      body: CustomScrollView(
        slivers: [
          // ── SLIVER APP BAR (Image Gallery) ──────────────────────
          SliverAppBar(
            expandedHeight: 360,
            pinned: true,
            backgroundColor: colors.scaffold,
            leading: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.90),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Colors.black87,
                ),
              ),
            ),
            actions: [
              // Wishlist Toggle
              StreamBuilder<List<String>>(
                stream: _firebaseService.watchFavorites(),
                builder: (context, snapshot) {
                  final favs = snapshot.data ?? [];
                  final isFav = favs.contains(_product.id);

                  return GestureDetector(
                    onTap: () async {
                      if (_isGuest) {
                        await _promptLogin('save to wishlist');
                        return;
                      }
                      await _firebaseService
                          .toggleFavorite(_product.id);
                    },
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.90),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        isFav
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color:
                            isFav ? colors.error : Colors.black87,
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Main image
                  if (images.isEmpty)
                    Container(
                      color: context
                          .colorScheme.surfaceContainerHighest,
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported_rounded,
                          size: 64,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  else
                    PageView.builder(
                      itemCount: images.length,
                      onPageChanged: (i) =>
                          setState(() => _selectedImageIndex = i),
                      itemBuilder: (_, i) => Image.network(
                        images[i],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        loadingBuilder:
                            (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: context.colorScheme
                                .surfaceContainerHighest,
                            child: const Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => Container(
                          color: context.colorScheme
                              .surfaceContainerHighest,
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported_rounded,
                              size: 48,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Page dots
                  if (images.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          images.length,
                          (i) => AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 3),
                            width:
                                _selectedImageIndex == i ? 20 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _selectedImageIndex == i
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.50),
                              borderRadius:
                                  BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Out of stock overlay
                  if (!_product.inStock)
                    Container(
                      color: Colors.black.withOpacity(0.50),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: colors.error,
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: Text(
                          'OUT OF STOCK',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── PRODUCT CONTENT ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: colors.scaffold,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Status Chips ───────────────────────────────
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (_product.isTrending)
                          const AppStatusChip(
                            label: 'Trending',
                            tone: AppStatusChipTone.warning,
                            icon:
                                Icons.local_fire_department_rounded,
                          ),
                        if (_product.featured)
                          const AppStatusChip(
                            label: 'Featured',
                            tone: AppStatusChipTone.primary,
                            icon: Icons.star_rounded,
                          ),
                        if (_product.isNewArrival)
                          const AppStatusChip(
                            label: 'New Arrival',
                            tone: AppStatusChipTone.success,
                          ),
                        if (_product.isBestSeller)
                          const AppStatusChip(
                            label: 'Best Seller',
                            tone: AppStatusChipTone.warning,
                          ),
                        AppStatusChip(
                          label: _product.inStock
                              ? 'In Stock'
                              : 'Out of Stock',
                          tone: _product.inStock
                              ? AppStatusChipTone.success
                              : AppStatusChipTone.error,
                          icon: _product.inStock
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ── Product Name ───────────────────────────────
                    Text(
                      _product.name,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ── Fabric Type + Origin ───────────────────────
                    if (_product.fabricType.isNotEmpty ||
                        _product.origin.isNotEmpty)
                      Row(
                        children: [
                          if (_product.fabricType.isNotEmpty) ...[
                            Icon(
                              Icons.style_rounded,
                              size: 14,
                              color: colors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _product.fabricType,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          if (_product.fabricType.isNotEmpty &&
                              _product.origin.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8),
                              child: Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: colors.textSecondary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          if (_product.origin.isNotEmpty) ...[
                            Icon(
                              Icons.public_rounded,
                              size: 14,
                              color: colors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _product.origin,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),

                    const SizedBox(height: 10),

                    // ── Rating ─────────────────────────────────────
                    if (_product.rating > 0)
                      Row(
                        children: [
                          ...List.generate(5, (i) {
                            final filled =
                                i < _product.rating.floor();
                            final half = !filled &&
                                i < _product.rating &&
                                _product.rating - i >= 0.5;
                            return Icon(
                              filled
                                  ? Icons.star_rounded
                                  : (half
                                      ? Icons.star_half_rounded
                                      : Icons
                                          .star_outline_rounded),
                              color: const Color(0xFFF59E0B),
                              size: 18,
                            );
                          }),
                          const SizedBox(width: 6),
                          Text(
                            '${_product.rating.toStringAsFixed(1)} (${_product.reviewCount} reviews)',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_product.soldCount > 0) ...[
                            const SizedBox(width: 12),
                            Text(
                              '${_product.soldCount} sold',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),

                    const SizedBox(height: 16),

                    // ── Price ──────────────────────────────────────
                    _buildPriceSection(colors),

                    const SizedBox(height: 20),

                    // ── Promo Text ─────────────────────────────────
                    if (_product.promoText.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color:
                              colors.brandPrimary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colors.brandPrimary
                                .withOpacity(0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.local_offer_rounded,
                              color: colors.brandPrimary,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _product.promoText,
                                style: GoogleFonts.poppins(
                                  color: colors.brandPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (_product.promoText.isNotEmpty)
                      const SizedBox(height: 20),

                    // ── Available Colors ───────────────────────────
                    if (_product.availableColors.isNotEmpty) ...[
                      _buildSectionLabel('Available Colors', colors),
                      const SizedBox(height: 10),
                      _buildColorSelector(colors),
                      const SizedBox(height: 20),
                    ],

                    // ── Available Sizes ────────────────────────────
                    if (_product.availableSizes.isNotEmpty) ...[
                      _buildSectionLabel('Sizes / Yards', colors),
                      const SizedBox(height: 10),
                      _buildSizeSelector(colors),
                      const SizedBox(height: 20),
                    ],

                    // ── Variants ───────────────────────────────────
                    if (_product.variants.isNotEmpty) ...[
                      _buildSectionLabel('Variants', colors),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _product.variants.map((v) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius:
                                  BorderRadius.circular(10),
                              border:
                                  Border.all(color: colors.border),
                            ),
                            child: Text(
                              v,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Fabric Details Card ────────────────────────
                    _buildFabricDetailsCard(colors),

                    const SizedBox(height: 20),

                    // ── Description ────────────────────────────────
                    _buildSectionLabel('Description', colors),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => setState(
                          () => _descExpanded = !_descExpanded),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            _product.description.isEmpty
                                ? 'No description available.'
                                : _product.description,
                            style: GoogleFonts.poppins(
                              height: 1.7,
                              fontSize: 13,
                              color: colors.textPrimary,
                            ),
                            maxLines:
                                _descExpanded ? null : 4,
                            overflow: _descExpanded
                                ? null
                                : TextOverflow.ellipsis,
                          ),
                          if (_product.description.length > 200)
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 6),
                              child: Text(
                                _descExpanded
                                    ? 'Show less'
                                    : 'Read more',
                                style: GoogleFonts.poppins(
                                  color: colors.brandPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Categories ─────────────────────────────────
                    _buildSectionLabel('Categories', colors),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _product.normalizedCategories
                          .map((cat) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colors.brandPrimary
                                .withOpacity(0.10),
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                          child: Text(
                            cat,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: colors.brandPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // ── Guest Banner ───────────────────────────────
                    if (_isGuest)
                      AppSurfaceCard(
                        color: colors.brandPrimary
                            .withOpacity(0.08),
                        padding: const EdgeInsets.all(14),
                        margin:
                            const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              color: colors.brown,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Sign in to save to wishlist, track orders, and get personalized recommendations.',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: colors.brown,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // ── Tailoring CTA ──────────────────────────────
                    _buildTailoringCTA(colors),

                    // Spacing for bottom bar
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // ── Bottom Action Bar ────────────────────────────────────────
      bottomNavigationBar: _buildBottomActionBar(colors),
    );
  }

  // ── Price Section ─────────────────────────────────────────────────────────

  Widget _buildPriceSection(dynamic colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_product.hasDiscount) ...[
          Text(
            '₦${_product.discountedPrice.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: colors.brandPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '₦${_product.price.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: colors.textSecondary,
                decoration: TextDecoration.lineThrough,
                decorationColor: colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colors.error,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _product.discountLabel,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ] else
          Text(
            '₦${_product.price.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: colors.textPrimary,
            ),
          ),

        const Spacer(),

        // Stock info
        if (_product.inStock && _product.stockQuantity > 0)
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${_product.stockQuantity} in stock',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2E7D32),
              ),
            ),
          ),
      ],
    );
  }

  // ── Color Selector ────────────────────────────────────────────────────────

  Widget _buildColorSelector(dynamic colors) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _product.availableColors.map((colorName) {
        final isSelected = _selectedColor == colorName;
        return GestureDetector(
          onTap: () =>
              setState(() => _selectedColor = colorName),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.brandPrimary
                  : colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? colors.brandPrimary
                    : colors.border,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color:
                            colors.brandPrimary.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Text(
              colorName,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : colors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Size Selector ─────────────────────────────────────────────────────────

  Widget _buildSizeSelector(dynamic colors) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _product.availableSizes.map((size) {
        final isSelected = _selectedSize == size;
        return GestureDetector(
          onTap: () =>
              setState(() => _selectedSize = size),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 54,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.brandPrimary
                  : colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? colors.brandPrimary
                    : colors.border,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color:
                            colors.brandPrimary.withOpacity(0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: Text(
                size,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? Colors.white
                      : colors.textPrimary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Fabric Details Card ───────────────────────────────────────────────────

  Widget _buildFabricDetailsCard(dynamic colors) {
    final details = <Map<String, dynamic>>[];

    if (_product.material.isNotEmpty) {
      details.add({
        'icon': Icons.texture_rounded,
        'label': 'Material',
        'value': _product.material,
      });
    }
    if (_product.fabricType.isNotEmpty) {
      details.add({
        'icon': Icons.style_rounded,
        'label': 'Fabric Type',
        'value': _product.fabricType,
      });
    }
    if (_product.gsm.isNotEmpty) {
      details.add({
        'icon': Icons.straighten_rounded,
        'label': 'GSM / Weight',
        'value': _product.gsm,
      });
    }
    if (_product.yardage > 0) {
      details.add({
        'icon': Icons.linear_scale_rounded,
        'label': 'Yardage',
        'value': '${_product.yardage} yards',
      });
    }
    if (_product.origin.isNotEmpty) {
      details.add({
        'icon': Icons.public_rounded,
        'label': 'Origin',
        'value': _product.origin,
      });
    }
    if (_product.occasion.isNotEmpty) {
      details.add({
        'icon': Icons.celebration_rounded,
        'label': 'Occasion',
        'value': _product.occasion,
      });
    }
    if (_product.gender.isNotEmpty) {
      details.add({
        'icon': Icons.person_rounded,
        'label': 'Gender',
        'value': _product.gender,
      });
    }
    if (_product.careInstructions.isNotEmpty) {
      details.add({
        'icon': Icons.dry_cleaning_rounded,
        'label': 'Care',
        'value': _product.careInstructions,
      });
    }

    if (details.isEmpty) return const SizedBox.shrink();

    return AppSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: colors.brandPrimary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Fabric Details',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...details.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(
                      d['icon'] as IconData,
                      size: 16,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 90,
                      child: Text(
                        d['label'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        d['value'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ── Tailoring CTA ─────────────────────────────────────────────────────────

  Widget _buildTailoringCTA(dynamic colors) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.brown.withOpacity(0.15),
            colors.cream,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.brown.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.brown.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.content_cut_rounded,
              color: colors.brown,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need Custom Tailoring?',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  'Get this fabric sewn to your measurements',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '✂️ Tailoring Services — Coming Soon!',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600),
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              backgroundColor:
                  colors.brown.withOpacity(0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Book',
              style: GoogleFonts.poppins(
                color: colors.brown,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Label ─────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String title, dynamic colors) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.w700,
        fontSize: 15,
        color: colors.textPrimary,
      ),
    );
  }

  // ── Bottom Action Bar ─────────────────────────────────────────────────────

  Widget _buildBottomActionBar(dynamic colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: colors.surface,
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Wishlist Button
            StreamBuilder<List<String>>(
              stream: _firebaseService.watchFavorites(),
              builder: (context, snapshot) {
                final favs = snapshot.data ?? [];
                final isFav = favs.contains(_product.id);

                return GestureDetector(
                  onTap: () async {
                    if (_isGuest) {
                      await _promptLogin(
                          'save to wishlist');
                      return;
                    }
                    await _firebaseService
                        .toggleFavorite(_product.id);
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isFav
                          ? colors.error.withOpacity(0.12)
                          : colors.surface,
                      borderRadius:
                          BorderRadius.circular(16),
                      border: Border.all(
                        color: isFav
                            ? colors.error
                            : colors.border,
                      ),
                    ),
                    child: Icon(
                      isFav
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFav
                          ? colors.error
                          : colors.iconPrimary,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),

            // Add to Cart
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _product.inStock && !_addingToCart
                      ? () async {
                          if (_isGuest) {
                            // Allow guest cart
                          }
                          await _addToCart();
                        }
                      : null,
                  icon: _addingToCart
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.shopping_bag_outlined,
                          size: 20,
                        ),
                  label: Text(
                    _addingToCart
                        ? 'Adding...'
                        : 'Add to Cart',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _product.inStock
                            ? colors.brandPrimary
                            : colors.textSecondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Buy Now
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _product.inStock
                      ? () async {
                          if (_isGuest) {
                            await _promptLogin(
                                'proceed to checkout');
                            return;
                          }
                          await _addToCart();
                          if (!mounted) return;
                          Navigator.of(context).pushNamed(
                            RouteNames.cart,
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.brandSecondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Buy Now',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
