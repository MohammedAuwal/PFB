import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pfb/config/routes/route_names.dart';
import 'package:pfb/core/constants/app_constants.dart';
import 'package:pfb/core/routing/app_router.dart';
import 'package:pfb/core/theme/app_theme.dart';
import 'package:pfb/core/theme/build_context_theme_x.dart';
import 'package:pfb/features/cart/presentation/screens/cart_screen.dart';
import 'package:pfb/features/orders/presentation/screens/order_screen.dart';
import 'package:pfb/features/products/data/product_repository.dart';
import 'package:pfb/features/products/presentation/screens/product_detail_screen.dart';
import 'package:pfb/features/profile/presentation/screens/profile_screen.dart';
import 'package:pfb/features/rider/presentation/screens/rider_home_screen.dart';
import 'package:pfb/features/rider/presentation/screens/ride_detail_screen.dart';
import 'package:pfb/features/shared/presentation/widgets/active_service_card.dart';
import 'package:pfb/features/shared/presentation/widgets/app_shimmer_loader.dart';
import 'package:pfb/features/shared/presentation/widgets/empty_state_card.dart';
import 'package:pfb/models/product_model.dart';
import 'package:pfb/models/ride_model.dart';
import 'package:pfb/services/admin_preview_scope.dart';
import 'package:pfb/services/firebase_service.dart';
import 'package:pfb/shared/widgets/app_section_title.dart';
import 'package:pfb/shared/widgets/app_status_chip.dart';
import 'package:pfb/shared/widgets/app_surface_card.dart';

class ProductListScreen extends StatefulWidget {
  final bool showBottomNav;

  const ProductListScreen({super.key, this.showBottomNav = true});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _repo            = ProductRepository();
  final _firebaseService = FirebaseService();
  final _searchCtrl      = TextEditingController();

  String _selectedCategory = 'All';

  bool _matchesSearch(ProductModel product, String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return product.name.toLowerCase().contains(q) ||
        product.description.toLowerCase().contains(q) ||
        product.normalizedCategories.any((c) => c.toLowerCase().contains(q)) ||
        product.variants.any((v) => v.toLowerCase().contains(q));
  }

  bool _matchesCategory(ProductModel product, String category) {
    if (category == 'All') return true;
    return product.hasCategory(category);
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final sc = sheetContext.appColors;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Handle ──────────────────────────────────────────
                Center(
                  child: Container(
                    width:  42,
                    height: 4,
                    decoration: BoxDecoration(
                      color:        sc.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Gold accent + title ─────────────────────────────
                Row(
                  children: [
                    Container(
                      width:  4,
                      height: 20,
                      decoration: BoxDecoration(
                        color:        sc.brandPrimary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Phlakes Notifications',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize:   18,
                        color:      sc.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Sign in to receive order updates, delivery tracking, '
                  'and account notifications from Phlakes Fabrics.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color:    sc.textSecondary,
                    height:   1.5,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Gold sign-in button ─────────────────────────────
                SizedBox(
                  width:  double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(sheetContext).pop();
                      await _goToLogin();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: sc.brandPrimary,
                      foregroundColor: AppPalette.secondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Sign In',
                      style: GoogleFonts.poppins(
                        fontWeight:   FontWeight.w700,
                        letterSpacing: 0.4,
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

  Widget _buildBottomNavIcon({
    required IconData icon,
    required int count,
  }) {
    final colors    = context.appColors;
    final showBadge = count > 0;
    final badgeText = count > 99 ? '99+' : '$count';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (showBadge)
          Positioned(
            right: -8,
            top:   -6,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color:        colors.error,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: colors.surface, width: 1.2),
              ),
              child: Center(
                child: Text(
                  badgeText,
                  style: GoogleFonts.poppins(
                    color:      Colors.white,
                    fontSize:   8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _firebaseService.seedDefaultCategoriesIfMissing();
    _firebaseService.seedDefaultAppSettings();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previewController = AdminPreviewScope.of(context);
    final colors            = context.appColors;
    final isDark            = context.isDarkMode;

    final body = SafeArea(
      child: StreamBuilder<Map<String, dynamic>?>(
        stream: _firebaseService.watchUserProfile(),
        builder: (context, profileSnapshot) {
          final profile      = profileSnapshot.data ?? {};
          final authUser     = FirebaseAuth.instance.currentUser;

          final profileDisplayName =
              (profile['displayName'] ?? '').toString().trim();
          final authDisplayName = (authUser?.displayName ?? '').trim();
          final authEmail       = (authUser?.email ?? '').trim();

          final displayName = profileDisplayName.isNotEmpty
              ? profileDisplayName
              : (authDisplayName.isNotEmpty
                  ? authDisplayName
                  : (_isGuest
                      ? 'Guest'
                      : (authEmail.isNotEmpty ? authEmail : 'User')));

          final profilePhotoUrl =
              (profile['photoUrl'] ?? '').toString().trim();
          final authPhotoUrl  = (authUser?.photoURL ?? '').trim();
          final headerPhotoUrl =
              profilePhotoUrl.isNotEmpty ? profilePhotoUrl : authPhotoUrl;
          final hasHeaderPhoto = _hasValidImage(headerPhotoUrl);

          return StreamBuilder<List<String>>(
            stream: _firebaseService.watchCategories(),
            builder: (context, categorySnapshot) {
              final dynamicCategories = categorySnapshot.data ?? const <String>[];
              final categories        = ['All', ...dynamicCategories];

              final effectiveSelectedCategory =
                  categories.contains(_selectedCategory)
                      ? _selectedCategory
                      : 'All';

              return StreamBuilder<List<RideModel>>(
                stream: _firebaseService.watchUserRides(),
                builder: (context, rideSnapshot) {
                  final rides = rideSnapshot.data ?? [];
                  final activeServices = rides
                      .where((r) => r.isActive)
                      .toList()
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                  return StreamBuilder<List<ProductModel>>(
                    stream: _repo.watchProducts(),
                    builder: (context, productSnapshot) {

                      // ── Loading skeleton ───────────────────────────
                      if (productSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return GridView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: 6,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:   3,
                            childAspectRatio: 0.62,
                            crossAxisSpacing: 12,
                            mainAxisSpacing:  12,
                          ),
                          itemBuilder: (_, __) => AppSurfaceCard(
                            padding:      const EdgeInsets.all(10),
                            borderRadius: BorderRadius.circular(20),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: AppShimmerLoader(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(14),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10),
                                AppShimmerLoader(height: 12, width: 70),
                                SizedBox(height: 8),
                                AppShimmerLoader(height: 10, width: 50),
                              ],
                            ),
                          ),
                        );
                      }

                      final items  = productSnapshot.data ?? [];
                      final query  = _searchCtrl.text.trim().toLowerCase();

                      final filtered = items.where((p) {
                        return _matchesSearch(p, query) &&
                            _matchesCategory(p, effectiveSelectedCategory);
                      }).toList();

                      final trendingItems =
                          items.where((p) => p.isTrending).toList();

                      return CustomScrollView(
                        slivers: [

                          // ── Header ─────────────────────────────────
                          SliverToBoxAdapter(
                            child: _PhlakesHeader(
                              colors:          colors,
                              isDark:          isDark,
                              displayName:     displayName,
                              isGuest:         _isGuest,
                              headerPhotoUrl:  headerPhotoUrl,
                              hasHeaderPhoto:  hasHeaderPhoto,
                              firebaseService: _firebaseService,
                              onNotificationTap: _openNotifications,
                            ),
                          ),

                          // ── Guest Banner ───────────────────────────
                          if (_isGuest)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                child: _GuestBanner(
                                  colors:      colors,
                                  onSignIn:    _goToLogin,
                                ),
                              ),
                            ),

                          // ── Admin Preview Banner ───────────────────
                          if (previewController.isPreviewMode)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 10),
                                child: _AdminPreviewBadge(colors: colors),
                              ),
                            ),

                          // ── Search Bar ─────────────────────────────
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16),
                              child: TextField(
                                controller: _searchCtrl,
                                onChanged:  (_) => setState(() {}),
                                decoration: const InputDecoration(
                                  hintText: 'Search fabrics, categories...',
                                  prefixIcon: Icon(Icons.search_rounded),
                                ),
                              ),
                            ),
                          ),

                          const SliverToBoxAdapter(
                              child: SizedBox(height: 12)),

                          // ── Delivery Location ──────────────────────
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16),
                              child: StreamBuilder<String>(
                                stream:
                                    _firebaseService.watchSelectedAddress(),
                                builder: (context, addressSnapshot) {
                                  final selectedAddress =
                                      addressSnapshot.data ?? '';

                                  return StreamBuilder<String>(
                                    stream: _firebaseService
                                        .watchVendorPickupAddress(),
                                    builder: (context, vendorSnapshot) {
                                      final vendorAddress =
                                          vendorSnapshot.data ??
                                              AppConstants
                                                  .defaultVendorLocation;

                                      return _DeliveryLocationCard(
                                        colors:          colors,
                                        isGuest:         _isGuest,
                                        selectedAddress: selectedAddress,
                                        vendorAddress:   vendorAddress,
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),

                          const SliverToBoxAdapter(
                              child: SizedBox(height: 12)),

                          // ── Main Action Cards ──────────────────────
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _MainActionCard(
                                      title: 'Book a Ride',
                                      subtitle: 'Fast & reliable',
                                      icon: Icons
                                          .directions_car_filled_rounded,
                                      gradient: LinearGradient(
                                        colors: [
                                          AppPalette.secondary,
                                          const Color(0xFF2A2A2A),
                                        ],
                                        begin: Alignment.topLeft,
                                        end:   Alignment.bottomRight,
                                      ),
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const RiderHomeScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _MainActionCard(
                                      title: 'Browse Fabrics',
                                      subtitle: 'Premium collection',
                                      icon: Icons
                                          .shopping_bag_outlined,
                                      gradient: LinearGradient(
                                        colors: [
                                          AppPalette.primary,
                                          AppPalette.primaryDark,
                                        ],
                                        begin: Alignment.topLeft,
                                        end:   Alignment.bottomRight,
                                      ),
                                      onTap: () {},
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SliverToBoxAdapter(
                              child: SizedBox(height: 12)),

                          // ── Quick Actions ──────────────────────────
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _QuickActionItem(
                                      icon:  Icons.payments_outlined,
                                      label: 'Pay',
                                      color: colors.brandPrimary,
                                      onTap: _isGuest ? _goToLogin : () {},
                                    ),
                                  ),
                                  Expanded(
                                    child: _QuickActionItem(
                                      icon:  Icons.receipt_long_rounded,
                                      label: 'Orders',
                                      color: colors.info,
                                      onTap: _isGuest
                                          ? _goToLogin
                                          : () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      OrderScreen(),
                                                ),
                                              );
                                            },
                                    ),
                                  ),
                                  Expanded(
                                    child: _QuickActionItem(
                                      icon:  Icons.history_rounded,
                                      label: 'History',
                                      color: colors.success,
                                      onTap: _isGuest
                                          ? _goToLogin
                                          : () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      OrderScreen(),
                                                ),
                                              );
                                            },
                                    ),
                                  ),
                                  Expanded(
                                    child: _QuickActionItem(
                                      icon:  Icons.favorite_outline_rounded,
                                      label: 'Wishlist',
                                      color: colors.error,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const ProfileScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SliverToBoxAdapter(
                              child: SizedBox(height: 16)),

                          // ── Category Chips ─────────────────────────
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: 40,
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16),
                                scrollDirection: Axis.horizontal,
                                itemBuilder: (_, i) {
                                  final item     = categories[i];
                                  final selected =
                                      item == effectiveSelectedCategory;

                                  return FilterChip(
                                    label: Text(item),
                                    selected: selected,
                                    onSelected: (_) => setState(
                                      () => _selectedCategory = item,
                                    ),
                                    selectedColor: colors.brandPrimary,
                                    backgroundColor: colors.surfaceAlt,
                                    checkmarkColor: AppPalette.secondary,
                                    side: BorderSide(
                                      color: selected
                                          ? colors.brandPrimary
                                          : colors.border,
                                    ),
                                    labelStyle: GoogleFonts.poppins(
                                      color: selected
                                          ? AppPalette.secondary
                                          : colors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize:   12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(999),
                                    ),
                                  );
                                },
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 8),
                                itemCount: categories.length,
                              ),
                            ),
                          ),

                          const SliverToBoxAdapter(
                              child: SizedBox(height: 12)),

                          // ── Active Services ────────────────────────
                          if (activeServices.isNotEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 0, 16, 12),
                                child: Column(
                                  children:
                                      activeServices.map((service) {
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: ActiveServiceCard(
                                        icon: service.type == 'delivery'
                                            ? Icons.delivery_dining_rounded
                                            : Icons.local_taxi_rounded,
                                        title: service.type == 'delivery'
                                            ? 'Delivery ${service.driver ?? 'in progress'}'
                                            : 'Driver: ${service.driver ?? 'Searching...'}',
                                        subtitle:
                                            '${service.pickup} → ${service.destination}',
                                        status:      service.status,
                                        eta:         service.eta.isEmpty
                                            ? null
                                            : service.eta,
                                        trailingText: service.eta.isEmpty
                                            ? (service.type == 'delivery'
                                                ? 'Delivery in progress 📦'
                                                : 'Driver is coming 🚗')
                                            : 'ETA: ${service.eta}',
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  RideDetailScreen(
                                                ride: service,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),

                          // ── Trending Section ───────────────────────
                          SliverToBoxAdapter(
                            child: _SectionHeader(
                              title: 'Trending Now 🔥',
                              colors: colors,
                            ),
                          ),

                          if (trendingItems.isEmpty)
                            const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: EmptyStateCard(
                                  icon: Icons.local_fire_department_outlined,
                                  title: 'No trending products yet',
                                  subtitle:
                                      'Mark products as trending from admin.',
                                ),
                              ),
                            )
                          else
                            SliverToBoxAdapter(
                              child: SizedBox(
                                height: 220,
                                child: ListView.separated(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  scrollDirection: Axis.horizontal,
                                  itemCount: trendingItems.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 12),
                                  itemBuilder: (_, i) {
                                    final product = trendingItems[i];
                                    return _TrendingProductCard(
                                      product: product,
                                      colors:  colors,
                                      onTap:   () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ProductDetailScreen(
                                              product: product,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),

                          const SliverToBoxAdapter(
                              child: SizedBox(height: 18)),

                          // ── All Products ───────────────────────────
                          SliverToBoxAdapter(
                            child: _SectionHeader(
                              title: 'All Products',
                              colors: colors,
                            ),
                          ),

                          if (filtered.isEmpty)
                            const SliverFillRemaining(
                              hasScrollBody: false,
                              child: Padding(
                                padding:
                                    EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: EmptyStateCard(
                                  icon: Icons.inventory_2_outlined,
                                  title: 'No products found',
                                  subtitle:
                                      'Try another search or category.',
                                ),
                              ),
                            )
                          else
                            StreamBuilder<List<String>>(
                              stream: _firebaseService.watchFavorites(),
                              builder: (context, favSnapshot) {
                                final favorites = favSnapshot.data ?? [];

                                return SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 0, 16, 8),
                                  sliver: SliverGrid(
                                    delegate:
                                        SliverChildBuilderDelegate(
                                      (_, i) {
                                        final product  = filtered[i];
                                        final isFavorite =
                                            favorites.contains(product.id);

                                        return _ProductGridCard(
                                          product:    product,
                                          isFavorite: isFavorite,
                                          colors:     colors,
                                          isGuest:    _isGuest,
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    ProductDetailScreen(
                                                  product: product,
                                                ),
                                              ),
                                            );
                                          },
                                          onFavoriteTap: () async {
                                            if (_isGuest) {
                                              await _goToLogin();
                                              return;
                                            }
                                            await _firebaseService
                                                .toggleFavorite(product.id);
                                          },
                                        );
                                      },
                                      childCount: filtered.length,
                                    ),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount:   3,
                                      childAspectRatio: 0.62,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing:  12,
                                    ),
                                  ),
                                );
                              },
                            ),

                          // ── Phlakes Promo Banner ───────────────────
                          SliverToBoxAdapter(
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              child: _PromoBanner(
                                colors:  colors,
                                isGuest: _isGuest,
                              ),
                            ),
                          ),
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
        backgroundColor: colors.scaffold,
        body: body,
      );
    }

    return StreamBuilder<int>(
      stream: _firebaseService.watchUnreadNotificationCount(),
      builder: (context, notifSnapshot) {
        final unreadNotifications = notifSnapshot.data ?? 0;

        return Scaffold(
          backgroundColor: colors.scaffold,
          body: body,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: 0,
            onTap: (index) {
              if (index == 1) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const CartScreen()),
                );
              } else if (index == 2) {
                if (_isGuest) {
                  _goToLogin();
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => OrderScreen()),
                );
              } else if (index == 3) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const ProfileScreen()),
                );
              }
            },
            items: [
              BottomNavigationBarItem(
                icon: _buildBottomNavIcon(
                  icon:  Icons.home_rounded,
                  count: unreadNotifications,
                ),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon:  Icon(Icons.shopping_bag_outlined),
                label: 'Cart',
              ),
              const BottomNavigationBarItem(
                icon:  Icon(Icons.receipt_long_rounded),
                label: 'Orders',
              ),
              const BottomNavigationBarItem(
                icon:  Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Phlakes Header
// ─────────────────────────────────────────────────────────────────────────────

class _PhlakesHeader extends StatelessWidget {
  final AppThemeColors colors;
  final bool isDark;
  final String displayName;
  final bool isGuest;
  final String headerPhotoUrl;
  final bool hasHeaderPhoto;
  final FirebaseService firebaseService;
  final VoidCallback onNotificationTap;

  const _PhlakesHeader({
    required this.colors,
    required this.isDark,
    required this.displayName,
    required this.isGuest,
    required this.headerPhotoUrl,
    required this.hasHeaderPhoto,
    required this.firebaseService,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Row(
        children: [
          // ── Avatar with gold ring ──────────────────────────────────
          Container(
            width:  50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Gold ring — luxury brand touch
              border: Border.all(
                color: colors.brandPrimary.withOpacity(0.60),
                width: 2,
              ),
              image: hasHeaderPhoto
                  ? DecorationImage(
                      image: NetworkImage(headerPhotoUrl),
                      fit:   BoxFit.cover,
                    )
                  : null,
              // Dark charcoal fallback bg
              color: isDark
                  ? AppPalette.darkSurface
                  : AppPalette.lightSurfaceAlt,
            ),
            child: !hasHeaderPhoto
                ? Center(
                    child: Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : 'P',
                      style: GoogleFonts.montserrat(
                        color:      colors.brandPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize:   18,
                      ),
                    ),
                  )
                : null,
          ),

          const SizedBox(width: 12),

          // ── Brand + Greeting ───────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand name row
                Row(
                  children: [
                    // Gold "PF" badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical:   4,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppPalette.primaryDark,
                            AppPalette.primary,
                          ],
                          begin: Alignment.topLeft,
                          end:   Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color:      AppPalette.primary.withOpacity(0.30),
                            blurRadius: 6,
                            offset:     const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'PF',
                        style: GoogleFonts.montserrat(
                          color:       AppPalette.secondary,
                          fontSize:    12,
                          fontWeight:  FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Brand name — gold for PHLAKES
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'PHLAKES',
                            style: GoogleFonts.montserrat(
                              color:       colors.brandPrimary,
                              fontSize:    16,
                              fontWeight:  FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          TextSpan(
                            text: ' FABRICS',
                            style: GoogleFonts.montserrat(
                              color: isDark
                                  ? Colors.white70
                                  : AppPalette.secondary,
                              fontSize:   14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  isGuest
                      ? 'Welcome, Guest 👋'
                      : 'Hi, $displayName 👋',
                  style: GoogleFonts.poppins(
                    color:    colors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),

          // ── Notification Bell ──────────────────────────────────────
          StreamBuilder<int>(
            stream: firebaseService.watchUnreadNotificationCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              final showBadge   = unreadCount > 0;
              final badgeText   =
                  unreadCount > 99 ? '99+' : '$unreadCount';

              return GestureDetector(
                onTap: onNotificationTap,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width:  44,
                      height: 44,
                      decoration: BoxDecoration(
                        color:  colors.surface,
                        shape:  BoxShape.circle,
                        border: Border.all(
                          color: colors.brandPrimary.withOpacity(0.20),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:      colors.shadow,
                            blurRadius: 10,
                            offset:     const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.notifications_none_rounded,
                        color: colors.brandPrimary,
                        size:  22,
                      ),
                    ),
                    if (showBadge)
                      Positioned(
                        right: -3,
                        top:   -3,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth:  18,
                            minHeight: 18,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical:   2,
                          ),
                          decoration: BoxDecoration(
                            color:        colors.error,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: colors.surface,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              badgeText,
                              style: GoogleFonts.poppins(
                                color:      Colors.white,
                                fontSize:   9,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Guest Banner
// ─────────────────────────────────────────────────────────────────────────────

class _GuestBanner extends StatelessWidget {
  final AppThemeColors colors;
  final VoidCallback onSignIn;

  const _GuestBanner({required this.colors, required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        // Gold-tinted surface for guest banner
        color:        colors.paleGold,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.brandPrimary.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color:  colors.brandPrimary.withOpacity(0.15),
              shape:  BoxShape.circle,
            ),
            child: Icon(
              Icons.person_outline_rounded,
              color: colors.brandPrimary,
              size:  18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Sign in to save favourites, book rides, and checkout.',
              style: GoogleFonts.poppins(
                color:      colors.brown,
                fontWeight: FontWeight.w600,
                fontSize:   12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSignIn,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color:        colors.brandPrimary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Sign In',
                style: GoogleFonts.poppins(
                  color:      AppPalette.secondary,
                  fontWeight: FontWeight.w700,
                  fontSize:   12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Admin Preview Badge
// ─────────────────────────────────────────────────────────────────────────────

class _AdminPreviewBadge extends StatelessWidget {
  final AppThemeColors colors;

  const _AdminPreviewBadge({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppPalette.primaryDark,
            AppPalette.primary,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.visibility_rounded,
            color: AppPalette.secondary,
            size:  16,
          ),
          const SizedBox(width: 8),
          Text(
            'Admin Preview Mode — Phlakes Fabrics',
            style: GoogleFonts.poppins(
              color:      AppPalette.secondary,
              fontWeight: FontWeight.w700,
              fontSize:   12,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Delivery Location Card
// ─────────────────────────────────────────────────────────────────────────────

class _DeliveryLocationCard extends StatelessWidget {
  final AppThemeColors colors;
  final bool isGuest;
  final String selectedAddress;
  final String vendorAddress;

  const _DeliveryLocationCard({
    required this.colors,
    required this.isGuest,
    required this.selectedAddress,
    required this.vendorAddress,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                color: colors.brandPrimary,
                size:  20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Delivery location',
                  style: GoogleFonts.poppins(
                    color:      colors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize:   13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isGuest
                ? 'Sign in to save and use delivery addresses'
                : (selectedAddress.isEmpty
                    ? 'No saved address selected yet'
                    : selectedAddress),
            style: GoogleFonts.poppins(
              color: (isGuest || selectedAddress.isEmpty)
                  ? colors.textSecondary
                  : colors.textPrimary,
              fontSize: 11,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            'Phlakes Pickup: $vendorAddress',
            style: GoogleFonts.poppins(
              color:      colors.brandPrimary,
              fontSize:   11,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Header with gold accent bar
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final AppThemeColors colors;

  const _SectionHeader({required this.title, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          // Gold vertical accent bar
          Container(
            width:  3.5,
            height: 20,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppPalette.primaryDark,
                  AppPalette.primaryLight,
                ],
                begin: Alignment.topCenter,
                end:   Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          AppSectionTitle(
            title:         title,
            spacingBottom: 0,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Promo Banner — Phlakes luxury gradient
// ─────────────────────────────────────────────────────────────────────────────

class _PromoBanner extends StatelessWidget {
  final AppThemeColors colors;
  final bool isGuest;

  const _PromoBanner({required this.colors, required this.isGuest});

  @override
  Widget build(BuildContext context) {
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        // Luxury gradient: black → gold — mirrors Phlakes store aesthetic
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0D0D0D),
            Color(0xFF1A1A0A),
            AppPalette.primaryDark,
          ],
          stops: [0.0, 0.5, 1.0],
          begin: Alignment.centerLeft,
          end:   Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color:      AppPalette.primary.withOpacity(0.22),
            blurRadius: 16,
            offset:     const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Gold "PF" icon
          Container(
            width:  40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppPalette.primary.withOpacity(0.60),
                width: 1.5,
              ),
              color: Colors.white.withOpacity(0.08),
            ),
            child: Center(
              child: Text(
                'PF',
                style: GoogleFonts.montserrat(
                  color:       AppPalette.primary,
                  fontSize:    13,
                  fontWeight:  FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isGuest
                  ? 'Sign in to unlock wishlist, checkout, ride booking, and personal tracking on Phlakes Fabrics.'
                  : 'Live route pricing now powers rides & deliveries across Nigeria! Premium fabrics await. 🚀',
              style: GoogleFonts.poppins(
                color:      Colors.white,
                fontWeight: FontWeight.w600,
                fontSize:   12.5,
                height:     1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product Grid Card
// ─────────────────────────────────────────────────────────────────────────────

class _ProductGridCard extends StatelessWidget {
  final ProductModel product;
  final bool isFavorite;
  final AppThemeColors colors;
  final bool isGuest;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  const _ProductGridCard({
    required this.product,
    required this.isFavorite,
    required this.colors,
    required this.isGuest,
    required this.onTap,
    required this.onFavoriteTap,
  });

  bool get _hasValidImage =>
      product.imageUrl.trim().isNotEmpty &&
      (product.imageUrl.startsWith('http://') ||
          product.imageUrl.startsWith('https://'));

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppSurfaceCard(
        padding:      EdgeInsets.zero,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  // ── Product image ──────────────────────────────────
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: _hasValidImage
                        ? Image.network(
                            product.imageUrl,
                            width:     double.infinity,
                            fit:       BoxFit.cover,
                            loadingBuilder: (ctx, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: ctx
                                    .colorScheme.surfaceContainerHighest,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => Container(
                              color: context
                                  .colorScheme.surfaceContainerHighest,
                              child: const Center(
                                child: Icon(
                                    Icons.image_not_supported),
                              ),
                            ),
                          )
                        : Container(
                            color: context
                                .colorScheme.surfaceContainerHighest,
                            child: const Center(
                              child:
                                  Icon(Icons.image_not_supported),
                            ),
                          ),
                  ),

                  // ── Status chips ───────────────────────────────────
                  Positioned(
                    top:  8,
                    left: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.isTrending)
                          const AppStatusChip(
                            label: 'Trending',
                            tone:  AppStatusChipTone.warning,
                          ),
                        if (product.featured)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: AppStatusChip(
                              label: 'Featured',
                              tone:  AppStatusChipTone.primary,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ── Favourite button ───────────────────────────────
                  Positioned(
                    top:   8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onFavoriteTap,
                      child: Container(
                        width:  28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.surface.withOpacity(0.90),
                          boxShadow: [
                            BoxShadow(
                              color:      Colors.black.withOpacity(0.10),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
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

            // ── Product info ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize:   12,
                      color:      colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.primaryCategory,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color:    colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '₦${product.price.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            color:      colors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize:   12,
                          ),
                        ),
                      ),
                      // ── Gold "Buy" pill ──────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical:   4,
                        ),
                        decoration: BoxDecoration(
                          // Gold gradient pill
                          gradient: const LinearGradient(
                            colors: [
                              AppPalette.primaryDark,
                              AppPalette.primary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Buy',
                          style: GoogleFonts.poppins(
                            // Black text on gold pill
                            color:      AppPalette.secondary,
                            fontWeight: FontWeight.w700,
                            fontSize:   10,
                          ),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Trending Product Card
// ─────────────────────────────────────────────────────────────────────────────

class _TrendingProductCard extends StatelessWidget {
  final ProductModel product;
  final AppThemeColors colors;
  final VoidCallback onTap;

  const _TrendingProductCard({
    required this.product,
    required this.colors,
    required this.onTap,
  });

  bool get _hasValidImage =>
      product.imageUrl.trim().isNotEmpty &&
      (product.imageUrl.startsWith('http://') ||
          product.imageUrl.startsWith('https://'));

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppSurfaceCard(
        padding:      EdgeInsets.zero,
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          width: 175,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                              fit:   BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: context
                                    .colorScheme.surfaceContainerHighest,
                                child: const Center(
                                  child: Icon(Icons.image_not_supported),
                                ),
                              ),
                            )
                          : Container(
                              color: context
                                  .colorScheme.surfaceContainerHighest,
                              child: const Center(
                                child: Icon(Icons.image_not_supported),
                              ),
                            ),
                    ),
                    // ── Gold gradient overlay at bottom ────────────
                    Positioned(
                      bottom: 0,
                      left:   0,
                      right:  0,
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.45),
                            ],
                            begin: Alignment.topCenter,
                            end:   Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    // ── Trending badge ─────────────────────────────
                    Positioned(
                      top:  8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical:   3,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppPalette.primaryDark,
                              AppPalette.primary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.local_fire_department_rounded,
                              color: AppPalette.secondary,
                              size:  10,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Hot',
                              style: GoogleFonts.poppins(
                                color:      AppPalette.secondary,
                                fontSize:   9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize:   13,
                        color:      colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      product.primaryCategory,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color:    colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Price in gold
                    Text(
                      '₦${product.price.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        fontSize:   14,
                        color:      colors.brandPrimary,
                      ),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Action Card — luxury gradient cards
// ─────────────────────────────────────────────────────────────────────────────

class _MainActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _MainActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          gradient:     gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(0.18),
              blurRadius: 12,
              offset:     const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment:  MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width:  44,
                height: 44,
                decoration: BoxDecoration(
                  color:  Colors.white.withOpacity(0.15),
                  shape:  BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.30),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size:  24,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color:      Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize:   14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color:    Colors.white.withOpacity(0.75),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Action Item
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            Container(
              width:  50,
              height: 50,
              decoration: BoxDecoration(
                color:  color.withOpacity(0.10),
                shape:  BoxShape.circle,
                border: Border.all(
                  color: color.withOpacity(0.25),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: color,
                size:  22,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize:   11,
                color:      colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
