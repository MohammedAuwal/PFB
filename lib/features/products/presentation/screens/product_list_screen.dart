import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pfb/config/routes/route_names.dart';
import 'package:pfb/core/constants/app_constants.dart';
import 'package:pfb/core/routing/app_router.dart';
import 'package:pfb/core/theme/build_context_theme_x.dart';
import 'package:pfb/features/cart/presentation/screens/cart_screen.dart';
import 'package:pfb/features/orders/presentation/screens/order_screen.dart';
import 'package:pfb/features/products/data/product_repository.dart';
import 'package:pfb/features/products/presentation/screens/product_detail_screen.dart';
import 'package:pfb/features/profile/presentation/screens/profile_screen.dart';
import 'package:pfb/features/shared/presentation/widgets/app_shimmer_loader.dart';
import 'package:pfb/features/shared/presentation/widgets/empty_state_card.dart';
import 'package:pfb/models/product_model.dart';
import 'package:pfb/services/admin_preview_scope.dart';
import 'package:pfb/services/firebase_service.dart';
import 'package:pfb/shared/widgets/app_section_title.dart';
import 'package:pfb/shared/widgets/app_status_chip.dart';
import 'package:pfb/shared/widgets/app_surface_card.dart';

// ── Textile Categories ─────────────────────────────────────────────────────────

class _TextileCategories {
  static const List<Map<String, dynamic>> items = [
    {'label': 'All', 'emoji': '🏪'},
    {'label': 'Ankara', 'emoji': '🌺'},
    {'label': 'Lace', 'emoji': '🤍'},
    {'label': 'Aso Oke', 'emoji': '👑'},
    {'label': 'Chiffon', 'emoji': '🌸'},
    {'label': 'Cotton', 'emoji': '☁️'},
    {'label': 'Silk', 'emoji': '✨'},
    {'label': 'Linen', 'emoji': '🌿'},
    {'label': 'Native Wear', 'emoji': '🇳🇬'},
    {'label': 'Adire', 'emoji': '🎨'},
    {'label': 'George', 'emoji': '💎'},
    {'label': 'Velvet', 'emoji': '🍷'},
    {'label': 'Atiku', 'emoji': '🏅'},
    {'label': 'Wedding', 'emoji': '💍'},
    {'label': 'New Arrivals', 'emoji': '🆕'},
    {'label': 'Best Sellers', 'emoji': '⭐'},
    {'label': 'Trending', 'emoji': '🔥'},
    {'label': 'Featured', 'emoji': '💫'},
    {'label': 'Men', 'emoji': '👔'},
    {'label': 'Women', 'emoji': '👗'},
    {'label': 'Children', 'emoji': '👧'},
    {'label': 'Accessories', 'emoji': '👜'},
    {'label': 'Luxury', 'emoji': '🥂'},
  ];
}

// ── Quick Actions Data ─────────────────────────────────────────────────────────

class _QuickActionData {
  final IconData icon;
  final String label;
  final Color bgColor;
  final VoidCallback onTap;

  const _QuickActionData({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.onTap,
  });
}

// ── Occasion Tiles ─────────────────────────────────────────────────────────────

class _OccasionData {
  final String label;
  final String emoji;
  final Color color;

  const _OccasionData({
    required this.label,
    required this.emoji,
    required this.color,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// ProductListScreen
// ═══════════════════════════════════════════════════════════════════════════════

class ProductListScreen extends StatefulWidget {
  final bool showBottomNav;

  const ProductListScreen({super.key, this.showBottomNav = true});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen>
    with SingleTickerProviderStateMixin {
  final _repo = ProductRepository();
  final _firebaseService = FirebaseService();
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  String _selectedCategory = 'All';
  bool _showSearchFocused = false;
  late AnimationController _promoAnimCtrl;
  late Animation<double> _promoAnim;

  // ── Helpers ──────────────────────────────────────────────────────────────

  bool _matchesSearch(ProductModel p, String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return p.name.toLowerCase().contains(q) ||
        p.description.toLowerCase().contains(q) ||
        p.normalizedCategories.any((c) => c.toLowerCase().contains(q)) ||
        p.variants.any((v) => v.toLowerCase().contains(q)) ||
        p.fabricType.toLowerCase().contains(q) ||
        p.material.toLowerCase().contains(q) ||
        p.occasion.toLowerCase().contains(q);
  }

  bool _matchesCategory(ProductModel p, String category) {
    if (category == 'All') return true;
    return p.hasCategory(category);
  }

  bool _hasValidImage(String url) {
    final v = url.trim();
    return v.isNotEmpty &&
        (v.startsWith('http://') || v.startsWith('https://'));
  }

  bool get _isGuest => FirebaseAuth.instance.currentUser == null;

  Future<void> _goToLogin() async {
    await AppRouter.clearAndGo(context, RouteNames.login);
  }

  Future<void> _openNotifications() async {
    if (_isGuest) {
      _openGuestNotificationsPanel();
      return;
    }
    await Navigator.of(context).pushNamed(RouteNames.notifications);
  }

  void _openGuestNotificationsPanel() {
    final colors = context.appColors;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final c = ctx.appColors;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: c.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: c.brandPrimary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.notifications_active_rounded,
                        color: c.brandPrimary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'IsmailTex Notifications',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: c.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Sign in to receive updates on your fabric orders, tailoring progress, new arrivals, exclusive deals, and delivery tracking.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: c.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await _goToLogin();
                    },
                    icon: const Icon(Icons.login_rounded),
                    label: Text(
                      'Sign In to IsmailTex',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _firebaseService.seedDefaultCategoriesIfMissing();
    _firebaseService.seedDefaultAppSettings();

    _promoAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _promoAnim = CurvedAnimation(
      parent: _promoAnimCtrl,
      curve: Curves.easeOut,
    );
    _promoAnimCtrl.forward();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _promoAnimCtrl.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final previewController = AdminPreviewScope.of(context);
    final colors = context.appColors;

    final body = SafeArea(
      child: StreamBuilder<Map<String, dynamic>?>(
        stream: _firebaseService.watchUserProfile(),
        builder: (context, profileSnapshot) {
          final profile = profileSnapshot.data ?? {};
          final authUser = FirebaseAuth.instance.currentUser;

          final profileDisplayName =
              (profile['displayName'] ?? '').toString().trim();
          final authDisplayName =
              (authUser?.displayName ?? '').trim();
          final authEmail = (authUser?.email ?? '').trim();

          final displayName = profileDisplayName.isNotEmpty
              ? profileDisplayName
              : (authDisplayName.isNotEmpty
                  ? authDisplayName
                  : (_isGuest
                      ? 'Guest'
                      : (authEmail.isNotEmpty ? authEmail : 'User')));

          final profilePhotoUrl =
              (profile['photoUrl'] ?? '').toString().trim();
          final authPhotoUrl =
              (authUser?.photoURL ?? '').trim();
          final headerPhotoUrl = profilePhotoUrl.isNotEmpty
              ? profilePhotoUrl
              : authPhotoUrl;
          final hasHeaderPhoto = _hasValidImage(headerPhotoUrl);

          return StreamBuilder<List<String>>(
            stream: _firebaseService.watchCategories(),
            builder: (context, categorySnapshot) {
              final dynamicCategories =
                  categorySnapshot.data ?? const <String>[];

              // Merge dynamic DB categories with static textile categories
              final staticLabels = _TextileCategories.items
                  .map((e) => e['label'] as String)
                  .toSet();
              final extraFromDB = dynamicCategories
                  .where((c) => !staticLabels.contains(c))
                  .toList();

              final allCategories = [
                ..._TextileCategories.items
                    .map((e) => e['label'] as String),
                ...extraFromDB,
              ];

              final effectiveCategory =
                  allCategories.contains(_selectedCategory)
                      ? _selectedCategory
                      : 'All';

              return StreamBuilder<List<ProductModel>>(
                stream: _repo.watchProducts(),
                builder: (context, productSnapshot) {
                  if (productSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return _buildSkeletonLoader();
                  }

                  final items = productSnapshot.data ?? [];
                  final query =
                      _searchCtrl.text.trim().toLowerCase();

                  final filtered = items.where((p) {
                    return _matchesSearch(p, query) &&
                        _matchesCategory(p, effectiveCategory);
                  }).toList();

                  final trendingItems =
                      items.where((p) => p.isTrending).toList();
                  final newArrivals =
                      items.where((p) => p.isNewArrival).toList();
                  final bestSellers =
                      items.where((p) => p.isBestSeller).toList();
                  final featuredItems =
                      items.where((p) => p.featured).toList();

                  return StreamBuilder<List<String>>(
                    stream: _firebaseService.watchFavorites(),
                    builder: (context, favSnapshot) {
                      final favorites = favSnapshot.data ?? [];

                      return CustomScrollView(
                        controller: _scrollCtrl,
                        slivers: [
                          // ────────────────────────────────────────
                          // 1. APP BAR HEADER
                          // ────────────────────────────────────────
                          SliverToBoxAdapter(
                            child: _buildHeader(
                              context,
                              colors: colors,
                              displayName: displayName,
                              hasHeaderPhoto: hasHeaderPhoto,
                              headerPhotoUrl: headerPhotoUrl,
                            ),
                          ),

                          // ────────────────────────────────────────
                          // 2. GUEST BANNER
                          // ────────────────────────────────────────
                          if (_isGuest)
                            SliverToBoxAdapter(
                              child: _buildGuestBanner(colors),
                            ),

                          // ────────────────────────────────────────
                          // 3. ADMIN PREVIEW BANNER
                          // ────────────────────────────────────────
                          if (previewController.isPreviewMode)
                            SliverToBoxAdapter(
                              child: _buildPreviewBanner(colors),
                            ),

                          // ────────────────────────────────────────
                          // 4. SEARCH BAR
                          // ────────────────────────────────────────
                          SliverToBoxAdapter(
                            child: _buildSearchBar(colors),
                          ),

                          const SliverToBoxAdapter(
                              child: SizedBox(height: 14)),

                          // ────────────────────────────────────────
                          // 5. DELIVER TO CARD
                          // ────────────────────────────────────────
                          SliverToBoxAdapter(
                            child: _buildDeliverToCard(colors),
                          ),

                          const SliverToBoxAdapter(
                              child: SizedBox(height: 14)),

                          // ────────────────────────────────────────
                          // 6. MAIN ACTION CARDS
                          //    Browse Fabrics | Tailoring Services
                          // ────────────────────────────────────────
                          SliverToBoxAdapter(
                            child: _buildMainActionCards(colors),
                          ),

                          const SliverToBoxAdapter(
                              child: SizedBox(height: 14)),

                          // ────────────────────────────────────────
                          // 7. QUICK ACTIONS
                          //    Cart | Orders | Wishlist | Track
                          // ────────────────────────────────────────
                          SliverToBoxAdapter(
                            child: _buildQuickActions(colors),
                          ),

                          const SliverToBoxAdapter(
                              child: SizedBox(height: 16)),

                          // ────────────────────────────────────────
                          // 8. PROMO BANNER
                          // ────────────────────────────────────────
                          SliverToBoxAdapter(
                            child: _buildPromoBanner(colors),
                          ),

                          const SliverToBoxAdapter(
                              child: SizedBox(height: 16)),

                          // ────────────────────────────────────────
                          // 9. SHOP BY OCCASION
                          // ────────────────────────────────────────
                          SliverToBoxAdapter(
                            child: _buildSectionHeader(
                              colors,
                              title: 'Shop by Occasion 🎉',
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: _buildOccasionRow(colors),
                          ),

                          const SliverToBoxAdapter(
                              child: SizedBox(height: 16)),

                          // ────────────────────────────────────────
                          // 10. FABRIC CATEGORY CHIPS
                          // ────────────────────────────────────────
                          SliverToBoxAdapter(
                            child: _buildSectionHeader(
                              colors,
                              title: 'Browse by Fabric',
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: _buildCategoryChips(
                              allCategories,
                              effectiveCategory,
                              colors,
                            ),
                          ),

                          const SliverToBoxAdapter(
                              child: SizedBox(height: 16)),

                          // ────────────────────────────────────────
                          // 11. TRENDING NOW
                          // ────────────────────────────────────────
                          SliverToBoxAdapter(
                            child: _buildSectionHeader(
                              colors,
                              title: 'Trending Now 🔥',
                            ),
                          ),
                          if (trendingItems.isEmpty)
                            _buildEmptySliver(
                              icon: Icons.local_fire_department_outlined,
                              title: 'No trending fabrics yet',
                              subtitle:
                                  'Mark products as trending from admin panel.',
                            )
                          else
                            SliverToBoxAdapter(
                              child: _buildHorizontalProductList(
                                context,
                                items: trendingItems,
                                favorites: favorites,
                              ),
                            ),

                          const SliverToBoxAdapter(
                              child: SizedBox(height: 16)),

                          // ────────────────────────────────────────
                          // 12. NEW ARRIVALS
                          // ────────────────────────────────────────
                          if (newArrivals.isNotEmpty) ...[
                            SliverToBoxAdapter(
                              child: _buildSectionHeader(
                                colors,
                                title: 'New Arrivals 🆕',
                                actionLabel: 'See All',
                                onAction: () => setState(
                                  () => _selectedCategory =
                                      'New Arrivals',
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: _buildHorizontalProductList(
                                context,
                                items: newArrivals,
                                favorites: favorites,
                              ),
                            ),
                            const SliverToBoxAdapter(
                                child: SizedBox(height: 16)),
                          ],

                          // ────────────────────────────────────────
                          // 13. BEST SELLERS
                          // ────────────────────────────────────────
                          if (bestSellers.isNotEmpty) ...[
                            SliverToBoxAdapter(
                              child: _buildSectionHeader(
                                colors,
                                title: 'Best Sellers ⭐',
                                actionLabel: 'See All',
                                onAction: () => setState(
                                  () => _selectedCategory =
                                      'Best Sellers',
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: _buildHorizontalProductList(
                                context,
                                items: bestSellers,
                                favorites: favorites,
                              ),
                            ),
                            const SliverToBoxAdapter(
                                child: SizedBox(height: 16)),
                          ],

                          // ────────────────────────────────────────
                          // 14. FEATURED COLLECTION
                          // ────────────────────────────────────────
                          if (featuredItems.isNotEmpty) ...[
                            SliverToBoxAdapter(
                              child: _buildSectionHeader(
                                colors,
                                title: 'Featured Collection 💫',
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: _buildHorizontalProductList(
                                context,
                                items: featuredItems,
                                favorites: favorites,
                                cardWidth: 200,
                                cardHeight: 240,
                              ),
                            ),
                            const SliverToBoxAdapter(
                                child: SizedBox(height: 16)),
                          ],

                          // ────────────────────────────────────────
                          // 15. SHOP BY GENDER
                          // ────────────────────────────────────────
                          SliverToBoxAdapter(
                            child: _buildSectionHeader(
                              colors,
                              title: 'Shop by Gender 👗',
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: _buildGenderRow(colors),
                          ),

                          const SliverToBoxAdapter(
                              child: SizedBox(height: 16)),

                          // ────────────────────────────────────────
                          // 16. ALL PRODUCTS GRID (filtered)
                          // ────────────────────────────────────────
                          SliverToBoxAdapter(
                            child: _buildSectionHeader(
                              colors,
                              title: effectiveCategory == 'All'
                                  ? 'All Products'
                                  : effectiveCategory,
                              subtitle: filtered.isEmpty
                                  ? null
                                  : '${filtered.length} items',
                            ),
                          ),

                          if (filtered.isEmpty)
                            _buildEmptySliver(
                              icon: Icons.inventory_2_outlined,
                              title: 'No products found',
                              subtitle:
                                  'Try a different category or search term.',
                            )
                          else
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 0, 16, 8),
                              sliver: SliverGrid(
                                delegate:
                                    SliverChildBuilderDelegate(
                                  (_, i) {
                                    final product = filtered[i];
                                    final isFav = favorites
                                        .contains(product.id);
                                    return _ProductGridCard(
                                      product: product,
                                      isFavorite: isFav,
                                      onTap: () =>
                                          _openProduct(
                                              context, product),
                                      onFavorite: () =>
                                          _toggleFav(product.id),
                                    );
                                  },
                                  childCount: filtered.length,
                                ),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.68,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                              ),
                            ),

                          // ────────────────────────────────────────
                          // 17. BOTTOM PROMO STRIP
                          // ────────────────────────────────────────
                          SliverToBoxAdapter(
                            child: _buildBottomPromoStrip(colors),
                          ),

                          const SliverToBoxAdapter(
                              child: SizedBox(height: 32)),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );

    if (!widget.showBottomNav) {
      return Scaffold(
        backgroundColor: context.appColors.scaffold,
        body: body,
      );
    }

    // Standalone bottom nav (when used outside shell)
    return StreamBuilder<int>(
      stream: _firebaseService.watchUnreadNotificationCount(),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: context.appColors.scaffold,
          body: body,
          bottomNavigationBar: _buildStandaloneBottomNav(context),
        );
      },
    );
  }

  // ── Action Helpers ────────────────────────────────────────────────────────

  void _openProduct(BuildContext context, ProductModel product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(product: product),
      ),
    );
  }

  Future<void> _toggleFav(String productId) async {
    if (_isGuest) {
      await _goToLogin();
      return;
    }
    await _firebaseService.toggleFavorite(productId);
  }

  // ── Section Widgets ───────────────────────────────────────────────────────

  Widget _buildSkeletonLoader() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (_, __) => AppSurfaceCard(
        padding: const EdgeInsets.all(10),
        borderRadius: BorderRadius.circular(20),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppShimmerLoader(
                borderRadius:
                    BorderRadius.all(Radius.circular(14)),
              ),
            ),
            SizedBox(height: 10),
            AppShimmerLoader(height: 12, width: 100),
            SizedBox(height: 6),
            AppShimmerLoader(height: 10, width: 70),
            SizedBox(height: 6),
            AppShimmerLoader(height: 10, width: 50),
          ],
        ),
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────

  Widget _buildHeader(
    BuildContext context, {
    required dynamic colors,
    required String displayName,
    required bool hasHeaderPhoto,
    required String headerPhotoUrl,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const ProfileScreen()),
              );
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.brandPrimary.withOpacity(0.45),
                  width: 2.5,
                ),
                image: hasHeaderPhoto
                    ? DecorationImage(
                        image: NetworkImage(headerPhotoUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: colors.cream,
              ),
              child: !hasHeaderPhoto
                  ? Center(
                      child: Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : 'I',
                        style: GoogleFonts.poppins(
                          color: colors.brown,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),

          // Brand + Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colors.brandPrimary,
                            colors.brandPrimary.withOpacity(0.75),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color:
                                colors.brandPrimary.withOpacity(0.30),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        'ITEX',
                        style: GoogleFonts.cinzel(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'IsmailTex',
                      style: GoogleFonts.playfairDisplay(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _isGuest
                      ? '👋 Welcome! Discover premium fabrics'
                      : '👋 Welcome back, $displayName',
                  style: GoogleFonts.poppins(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Notification Bell
          StreamBuilder<int>(
            stream: _firebaseService.watchUnreadNotificationCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              return GestureDetector(
                onTap: _openNotifications,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colors.shadow,
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.notifications_none_rounded,
                        color: colors.iconOnLightTint,
                        size: 22,
                      ),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.error,
                            borderRadius:
                                BorderRadius.circular(999),
                            border: Border.all(
                              color: colors.surface,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              unreadCount > 99
                                  ? '99+'
                                  : '$unreadCount',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── GUEST BANNER ──────────────────────────────────────────────────────────

  Widget _buildGuestBanner(dynamic colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: AppSurfaceCard(
        color: colors.brandPrimary.withOpacity(0.08),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.brandPrimary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.person_outline_rounded,
                color: colors.brown,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Sign in to save wishlists, track orders & enjoy personalized recommendations.',
                style: GoogleFonts.poppins(
                  color: colors.brown,
                  fontWeight: FontWeight.w600,
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _goToLogin,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                backgroundColor:
                    colors.brandPrimary.withOpacity(0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Sign In',
                style: GoogleFonts.poppins(
                  color: colors.brown,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── PREVIEW BANNER ────────────────────────────────────────────────────────

  Widget _buildPreviewBanner(dynamic colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: AppSurfaceCard(
        color: colors.brandPrimary.withOpacity(0.12),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.visibility_rounded,
                color: colors.brown, size: 18),
            const SizedBox(width: 8),
            Text(
              'Admin Preview Mode — IsmailTex',
              style: GoogleFonts.poppins(
                color: colors.brown,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── SEARCH BAR ────────────────────────────────────────────────────────────

  Widget _buildSearchBar(dynamic colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _showSearchFocused
                ? colors.brandPrimary
                : colors.borderSoft,
            width: _showSearchFocused ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _showSearchFocused
                  ? colors.brandPrimary.withOpacity(0.12)
                  : colors.shadow,
              blurRadius: _showSearchFocused ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (_) => setState(() {}),
          onTap: () => setState(() => _showSearchFocused = true),
          onSubmitted: (_) =>
              setState(() => _showSearchFocused = false),
          decoration: InputDecoration(
            hintText:
                'Search fabrics, lace, Ankara, native wear...',
            hintStyle: GoogleFonts.poppins(
              fontSize: 13,
              color: colors.textSecondary,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: _showSearchFocused
                  ? colors.brandPrimary
                  : colors.iconPrimary,
            ),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: colors.iconPrimary,
                      size: 20,
                    ),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _showSearchFocused = false);
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 4,
            ),
          ),
        ),
      ),
    );
  }

  // ── DELIVER TO ────────────────────────────────────────────────────────────

  Widget _buildDeliverToCard(dynamic colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: StreamBuilder<String>(
        stream: _firebaseService.watchSelectedAddress(),
        builder: (context, addressSnapshot) {
          final selectedAddress = addressSnapshot.data ?? '';

          return AppSurfaceCard(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.brandPrimary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    color: colors.brandPrimary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deliver To',
                        style: GoogleFonts.poppins(
                          color: colors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isGuest
                            ? 'Sign in to set delivery address'
                            : (selectedAddress.isEmpty
                                ? 'No address selected'
                                : selectedAddress),
                        style: GoogleFonts.poppins(
                          color: (_isGuest ||
                                  selectedAddress.isEmpty)
                              ? colors.textSecondary
                              : colors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _isGuest ? _goToLogin : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const ProfileScreen()),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    backgroundColor:
                        colors.brandPrimary.withOpacity(0.10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Change',
                    style: GoogleFonts.poppins(
                      color: colors.brandPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── MAIN ACTION CARDS ─────────────────────────────────────────────────────

  Widget _buildMainActionCards(dynamic colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Browse Fabrics
          Expanded(
            child: _MainActionCard(
              title: 'Browse\nFabrics',
              subtitle: 'Ankara, Lace & more',
              icon: Icons.style_rounded,
              gradientColors: [
                colors.brandPrimary,
                colors.brandPrimary.withOpacity(0.70),
              ],
              iconBg: Colors.white.withOpacity(0.20),
              onTap: () => setState(() => _selectedCategory = 'All'),
            ),
          ),
          const SizedBox(width: 12),
          // Tailoring Services
          Expanded(
            child: _MainActionCard(
              title: 'Tailoring\nServices',
              subtitle: 'Custom fitted styles',
              icon: Icons.content_cut_rounded,
              gradientColors: [
                colors.brown,
                colors.darkBrown,
              ],
              iconBg: Colors.white.withOpacity(0.20),
              onTap: () {
                // TODO: Navigate to TailoringScreen
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '✂️ Tailoring Services — Coming Soon!',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600),
                    ),
                    backgroundColor: colors.brown,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── QUICK ACTIONS ─────────────────────────────────────────────────────────

  Widget _buildQuickActions(dynamic colors) {
    final actions = [
      _QuickActionData(
        icon: Icons.shopping_bag_rounded,
        label: 'Cart',
        bgColor: colors.paleOrange,
        onTap: () {
          if (_isGuest) {
            _goToLogin();
            return;
          }
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CartScreen()),
          );
        },
      ),
      _QuickActionData(
        icon: Icons.receipt_long_rounded,
        label: 'Orders',
        bgColor: colors.paleBlue,
        onTap: () {
          if (_isGuest) {
            _goToLogin();
            return;
          }
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => OrderScreen()),
          );
        },
      ),
      _QuickActionData(
        icon: Icons.favorite_rounded,
        label: 'Wishlist',
        bgColor: colors.paleRed,
        onTap: () {
          if (_isGuest) {
            _goToLogin();
            return;
          }
          Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) =>
                    const ProfileScreen(showScaffold: true)),
          );
        },
      ),
      _QuickActionData(
        icon: Icons.local_shipping_rounded,
        label: 'Track',
        bgColor: colors.paleGreen,
        onTap: () {
          if (_isGuest) {
            _goToLogin();
            return;
          }
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => OrderScreen()),
          );
        },
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: actions
            .map(
              (a) => Expanded(
                child: _QuickActionItem(
                  icon: a.icon,
                  label: a.label,
                  bgColor: a.bgColor,
                  onTap: a.onTap,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ── PROMO BANNER ──────────────────────────────────────────────────────────

  Widget _buildPromoBanner(dynamic colors) {
    return FadeTransition(
      opacity: _promoAnim,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colors.brandPrimary,
                colors.brown,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colors.brandPrimary.withOpacity(0.30),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _isGuest
                            ? '🎁 New Customer Offer'
                            : '🔥 Flash Sale',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isGuest
                          ? 'Sign in & get 10% off your first fabric order!'
                          : 'Premium Ankara & Lace — Up to 30% OFF this week!',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _isGuest ? _goToLogin : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _isGuest ? 'Sign In Now' : 'Shop Now',
                          style: GoogleFonts.poppins(
                            color: colors.brandPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.style_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── OCCASION ROW ──────────────────────────────────────────────────────────

  Widget _buildOccasionRow(dynamic colors) {
    final occasions = [
      _OccasionData(
        label: 'Wedding',
        emoji: '💍',
        color: const Color(0xFFFCE4EC),
      ),
      _OccasionData(
        label: 'Sallah',
        emoji: '🌙',
        color: const Color(0xFFE8F5E9),
      ),
      _OccasionData(
        label: 'Naming',
        emoji: '👶',
        color: const Color(0xFFE3F2FD),
      ),
      _OccasionData(
        label: 'Birthday',
        emoji: '🎂',
        color: const Color(0xFFFFF9C4),
      ),
      _OccasionData(
        label: 'Corporate',
        emoji: '👔',
        color: const Color(0xFFEDE7F6),
      ),
      _OccasionData(
        label: 'Burial',
        emoji: '🕊️',
        color: const Color(0xFFF3E5F5),
      ),
    ];

    return SizedBox(
      height: 88,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: occasions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final o = occasions[i];
          return GestureDetector(
            onTap: () => setState(
                () => _selectedCategory = o.label),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: o.color,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _selectedCategory == o.label
                          ? colors.brandPrimary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      o.emoji,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  o.label,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── CATEGORY CHIPS ────────────────────────────────────────────────────────

  Widget _buildCategoryChips(
    List<String> categories,
    String effectiveCategory,
    dynamic colors,
  ) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final label = categories[i];
          final selected = label == effectiveCategory;

          // Find matching emoji
          final matchItem = _TextileCategories.items.firstWhere(
            (e) => e['label'] == label,
            orElse: () => {'emoji': '🧵'},
          );
          final emoji = matchItem['emoji'] as String;

          return GestureDetector(
            onTap: () =>
                setState(() => _selectedCategory = label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? colors.brandPrimary
                    : colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? colors.brandPrimary
                      : colors.borderSoft,
                ),
                boxShadow: selected
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji,
                      style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: selected
                          ? Colors.white
                          : colors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── GENDER ROW ────────────────────────────────────────────────────────────

  Widget _buildGenderRow(dynamic colors) {
    final genders = [
      {'label': 'Men', 'emoji': '👔', 'color': const Color(0xFFE3F2FD)},
      {'label': 'Women', 'emoji': '👗', 'color': const Color(0xFFFCE4EC)},
      {'label': 'Children', 'emoji': '👧', 'color': const Color(0xFFF9FBE7)},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: genders.map((g) {
          final label = g['label'] as String;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: label != 'Children' ? 10 : 0,
              ),
              child: GestureDetector(
                onTap: () =>
                    setState(() => _selectedCategory = label),
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: g['color'] as Color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedCategory == label
                          ? colors.brandPrimary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        g['emoji'] as String,
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── HORIZONTAL PRODUCT LIST ───────────────────────────────────────────────

  Widget _buildHorizontalProductList(
    BuildContext context, {
    required List<ProductModel> items,
    required List<String> favorites,
    double cardWidth = 180,
    double cardHeight = 220,
  }) {
    return SizedBox(
      height: cardHeight,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final product = items[i];
          final isFav = favorites.contains(product.id);
          return _HorizontalProductCard(
            product: product,
            isFavorite: isFav,
            width: cardWidth,
            onTap: () => _openProduct(context, product),
            onFavorite: () => _toggleFav(product.id),
          );
        },
      ),
    );
  }

  // ── SECTION HEADER ────────────────────────────────────────────────────────

  Widget _buildSectionHeader(
    dynamic colors, {
    required String title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: colors.brandPrimary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: colors.textPrimary,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: colors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel,
                style: GoogleFonts.poppins(
                  color: colors.brandPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── EMPTY SLIVER ──────────────────────────────────────────────────────────

  SliverToBoxAdapter _buildEmptySliver({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: EmptyStateCard(
          icon: icon,
          title: title,
          subtitle: subtitle,
        ),
      ),
    );
  }

  // ── BOTTOM PROMO STRIP ────────────────────────────────────────────────────

  Widget _buildBottomPromoStrip(dynamic colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.cream,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colors.brandPrimary.withOpacity(0.20),
          ),
        ),
        child: Row(
          children: [
            Text('🧵', style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Free Delivery',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    'On all orders above ₦25,000 within Lagos',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.local_shipping_outlined,
              color: colors.brandPrimary,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }

  // ── STANDALONE BOTTOM NAV (fallback) ──────────────────────────────────────

  Widget _buildStandaloneBottomNav(BuildContext context) {
    final colors = context.appColors;
    return StreamBuilder<int>(
      stream: _firebaseService.watchCartCount(),
      builder: (context, cartSnap) {
        final count = cartSnap.data ?? 0;
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            boxShadow: [
              BoxShadow(
                color: colors.shadow,
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            top: false,
            child: BottomNavigationBar(
              currentIndex: 0,
              backgroundColor: colors.surface,
              selectedItemColor: colors.brandPrimary,
              unselectedItemColor: colors.textSecondary,
              elevation: 0,
              selectedLabelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
              onTap: (index) {
                switch (index) {
                  case 1:
                    if (_isGuest) {
                      _goToLogin();
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const CartScreen()),
                      );
                    }
                    break;
                  case 2:
                    if (_isGuest) {
                      _goToLogin();
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => OrderScreen()),
                      );
                    }
                    break;
                  case 3:
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const ProfileScreen()),
                    );
                    break;
                }
              },
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.shopping_bag_rounded),
                      if (count > 0)
                        Positioned(
                          right: -8,
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: colors.error,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  label: 'Cart',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long_rounded),
                  label: 'Orders',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// _MainActionCard
// ═══════════════════════════════════════════════════════════════════════════════

class _MainActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final Color iconBg;
  final VoidCallback onTap;

  const _MainActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.iconBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 130,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withOpacity(0.30),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const Spacer(),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.80),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// _QuickActionItem
// ═══════════════════════════════════════════════════════════════════════════════

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: colors.iconOnLightTint,
                size: 22,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// _HorizontalProductCard — For trending/new arrivals/best sellers rows
// ═══════════════════════════════════════════════════════════════════════════════

class _HorizontalProductCard extends StatelessWidget {
  final ProductModel product;
  final bool isFavorite;
  final double width;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  const _HorizontalProductCard({
    required this.product,
    required this.isFavorite,
    required this.width,
    required this.onTap,
    required this.onFavorite,
  });

  bool get _hasValidImage =>
      product.imageUrl.trim().isNotEmpty &&
      (product.imageUrl.startsWith('http://') ||
          product.imageUrl.startsWith('https://'));

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GestureDetector(
      onTap: onTap,
      child: AppSurfaceCard(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(22),
                      ),
                      child: _hasValidImage
                          ? Image.network(
                              product.imageUrl,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _placeholder(context),
                            )
                          : _placeholder(context),
                    ),

                    // Discount badge
                    if (product.hasDiscount)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.error,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            product.discountLabel,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                    // Status chips
                    if (!product.hasDiscount)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            if (product.isNewArrival)
                              const AppStatusChip(
                                label: 'New',
                                tone: AppStatusChipTone.success,
                              ),
                            if (product.isTrending)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: AppStatusChip(
                                  label: 'Hot',
                                  tone: AppStatusChipTone.warning,
                                ),
                              ),
                          ],
                        ),
                      ),

                    // Wishlist button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: onFavorite,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color:
                                Colors.white.withOpacity(0.90),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withOpacity(0.10),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Icon(
                            isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isFavorite
                                ? colors.error
                                : colors.iconPrimary,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Info
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (product.fabricType.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        product.fabricType,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Discounted price
                        if (product.hasDiscount) ...[
                          Text(
                            '₦${product.discountedPrice.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: colors.brandPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '₦${product.price.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: colors.textSecondary,
                              decoration:
                                  TextDecoration.lineThrough,
                            ),
                          ),
                        ] else
                          Text(
                            '₦${product.price.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: colors.brandPrimary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: context.colorScheme.surfaceContainerHighest,
      child: const Center(
        child: Icon(
          Icons.image_not_supported_rounded,
          color: Colors.grey,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// _ProductGridCard — 2-column grid layout
// ═══════════════════════════════════════════════════════════════════════════════

class _ProductGridCard extends StatelessWidget {
  final ProductModel product;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  const _ProductGridCard({
    required this.product,
    required this.isFavorite,
    required this.onTap,
    required this.onFavorite,
  });

  bool get _hasValidImage =>
      product.imageUrl.trim().isNotEmpty &&
      (product.imageUrl.startsWith('http://') ||
          product.imageUrl.startsWith('https://'));

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GestureDetector(
      onTap: onTap,
      child: AppSurfaceCard(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            Expanded(
              flex: 6,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: _hasValidImage
                        ? Image.network(
                            product.imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder:
                                (context, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: context.colorScheme
                                    .surfaceContainerHighest,
                                child: const Center(
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) =>
                                _placeholder(context),
                          )
                        : _placeholder(context),
                  ),

                  // Discount badge
                  if (product.hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.error,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          product.discountLabel,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                  else
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          if (product.isTrending)
                            const AppStatusChip(
                              label: 'Trending',
                              tone: AppStatusChipTone.warning,
                            ),
                          if (product.featured)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: AppStatusChip(
                                label: 'Featured',
                                tone: AppStatusChipTone.primary,
                              ),
                            ),
                          if (product.isNewArrival)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: AppStatusChip(
                                label: 'New',
                                tone: AppStatusChipTone.success,
                              ),
                            ),
                        ],
                      ),
                    ),

                  // Wishlist
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onFavorite,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.90),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withOpacity(0.10),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Icon(
                          isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFavorite
                              ? colors.error
                              : colors.iconPrimary,
                          size: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Info section
            Expanded(
              flex: 4,
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.fabricType.isNotEmpty
                          ? product.fabricType
                          : product.primaryCategory,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: colors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: product.hasDiscount
                              ? Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '₦${product.discountedPrice.toStringAsFixed(0)}',
                                      style: GoogleFonts.poppins(
                                        color: colors.brandPrimary,
                                        fontWeight:
                                            FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      '₦${product.price.toStringAsFixed(0)}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 9,
                                        color:
                                            colors.textSecondary,
                                        decoration: TextDecoration
                                            .lineThrough,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  '₦${product.price.toStringAsFixed(0)}',
                                  style: GoogleFonts.poppins(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                        ),
                        GestureDetector(
                          onTap: onTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: colors.brandPrimary,
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Buy',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: context.colorScheme.surfaceContainerHighest,
      child: const Center(
        child: Icon(
          Icons.image_not_supported_rounded,
          color: Colors.grey,
        ),
      ),
    );
  }
}
