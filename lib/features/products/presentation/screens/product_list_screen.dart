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
  final _repo = ProductRepository();
  final _firebaseService = FirebaseService();
  final _searchCtrl = TextEditingController();

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
    final value = url.trim();
    return value.isNotEmpty &&
        (value.startsWith('http://') || value.startsWith('https://'));
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
        final sheetColors = sheetContext.appColors;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: sheetColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'ITEX Notifications',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: sheetColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to receive order, ride, delivery, and account notifications from IsmailTex.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: sheetColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(sheetContext).pop();
                      await _goToLogin();
                    },
                    child: Text(
                      'Sign In',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
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
    final colors = context.appColors;
    final showBadge = count > 0;
    final badgeText = count > 99 ? '99+' : '$count';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (showBadge)
          Positioned(
            right: -8,
            top: -6,
            child: Container(
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: colors.error,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: colors.surface, width: 1.2),
              ),
              child: Center(
                child: Text(
                  badgeText,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 8,
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
    final colors = context.appColors;

    final body = SafeArea(
      child: StreamBuilder<Map<String, dynamic>?>(
        stream: _firebaseService.watchUserProfile(),
        builder: (context, profileSnapshot) {
          final profile = profileSnapshot.data ?? {};
          final authUser = FirebaseAuth.instance.currentUser;

          final profileDisplayName =
              (profile['displayName'] ?? '').toString().trim();
          final authDisplayName = (authUser?.displayName ?? '').trim();
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
          final authPhotoUrl = (authUser?.photoURL ?? '').trim();
          final headerPhotoUrl =
              profilePhotoUrl.isNotEmpty ? profilePhotoUrl : authPhotoUrl;
          final hasHeaderPhoto = _hasValidImage(headerPhotoUrl);

          return StreamBuilder<List<String>>(
            stream: _firebaseService.watchCategories(),
            builder: (context, categorySnapshot) {
              final dynamicCategories =
                  categorySnapshot.data ?? const <String>[];
              final categories = ['All', ...dynamicCategories];

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
                            crossAxisCount: 3,
                            childAspectRatio: 0.62,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemBuilder: (_, __) {
                            return AppSurfaceCard(
                              padding: const EdgeInsets.all(10),
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
                            );
                          },
                        );
                      }

                      final items = productSnapshot.data ?? [];
                      final query = _searchCtrl.text.trim().toLowerCase();

                      final filtered = items.where((p) {
                        return _matchesSearch(p, query) &&
                            _matchesCategory(p, effectiveSelectedCategory);
                      }).toList();

                      final trendingItems =
                          items.where((p) => p.isTrending).toList();

                      return CustomScrollView(
                        slivers: [
                          // ── Header Row ────────────────────────────────
                          SliverToBoxAdapter(
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 14, 16, 10),
                              child: Row(
                                children: [
                                  // User Avatar
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: colors.brandPrimary
                                            .withOpacity(0.45),
                                        width: 2,
                                      ),
                                      image: hasHeaderPhoto
                                          ? DecorationImage(
                                              image:
                                                  NetworkImage(headerPhotoUrl),
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
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),

                                  // ── ITEX Brand + Greeting ────────────
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // ITEX Brand Badge
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 5,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    colors.brandPrimary,
                                                    colors.brandPrimary
                                                        .withOpacity(0.75),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: colors.brandPrimary
                                                        .withOpacity(0.30),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                'ITEX',
                                                style: GoogleFonts.cinzel(
                                                  color: Colors.white,
                                                  fontSize: 13,
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
                                        const SizedBox(height: 4),
                                        Text(
                                          _isGuest
                                              ? 'Welcome, Guest 👋'
                                              : 'Hi, $displayName 👋',
                                          style: GoogleFonts.poppins(
                                            color: colors.textSecondary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // ── Notification Bell ─────────────────
                                  StreamBuilder<int>(
                                    stream: _firebaseService
                                        .watchUnreadNotificationCount(),
                                    builder: (context, snapshot) {
                                      final unreadCount = snapshot.data ?? 0;
                                      final showBadge = unreadCount > 0;
                                      final badgeText = unreadCount > 99
                                          ? '99+'
                                          : '$unreadCount';

                                      return GestureDetector(
                                        onTap: _openNotifications,
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            Container(
                                              width: 42,
                                              height: 42,
                                              decoration: BoxDecoration(
                                                color: colors.surface,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: colors.shadow,
                                                    blurRadius: 12,
                                                    offset:
                                                        const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                Icons
                                                    .notifications_none_rounded,
                                                color: colors.iconOnLightTint,
                                              ),
                                            ),
                                            if (showBadge)
                                              Positioned(
                                                right: -4,
                                                top: -4,
                                                child: Container(
                                                  constraints:
                                                      const BoxConstraints(
                                                    minWidth: 18,
                                                    minHeight: 18,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 5,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: colors.error,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            999),
                                                    border: Border.all(
                                                      color: colors.surface,
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      badgeText,
                                                      style:
                                                          GoogleFonts.poppins(
                                                        color: Colors.white,
                                                        fontSize: 9,
                                                        fontWeight:
                                                            FontWeight.w700,
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
                            ),
                          ),

                          // ── Guest Banner ──────────────────────────────
                          if (_isGuest)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                child: AppSurfaceCard(
                                  color: colors.brandPrimary.withOpacity(0.10),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: colors.brandPrimary
                                              .withOpacity(0.15),
                                          shape: BoxShape.circle,
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
                                          'Browsing as guest. Sign in to save favourites, book rides, and checkout on IsmailTex.',
                                          style: GoogleFonts.poppins(
                                            color: colors.brown,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      TextButton(
                                        onPressed: _goToLogin,
                                        child: Text(
                                          'Sign In',
                                          style: GoogleFonts.poppins(
                                            color: colors.brown,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          // ── Admin Preview Banner ──────────────────────
                          if (previewController.isPreviewMode)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 10),
                                child: AppSurfaceCard(
                                  color: colors.brandPrimary.withOpacity(0.12),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.visibility_rounded,
                                        color: colors.brown,
                                        size: 18,
                                      ),
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
                              ),
                            ),

                          // ── Search Bar ────────────────────────────────
                          SliverToBoxAdapter(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: TextField(
                                controller: _searchCtrl,
                                onChanged: (_) => setState(() {}),
                                decoration: const InputDecoration(
                                  hintText:
                                      'Search products, categories, variants...',
                                  prefixIcon: Icon(Icons.search_rounded),
                                ),
                              ),
                            ),
                          ),

                          const SliverToBoxAdapter(
                              child: SizedBox(height: 12)),

                          // ── Delivery Location Card ────────────────────
                          SliverToBoxAdapter(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
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

                                      return AppSurfaceCard(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 14,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.location_on_rounded,
                                                  color: colors.brandPrimary,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    'Selected delivery location',
                                                    style: GoogleFonts.poppins(
                                                      color: colors.textPrimary,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              _isGuest
                                                  ? 'Sign in to save and use delivery addresses'
                                                  : (selectedAddress.isEmpty
                                                      ? 'No saved address selected yet'
                                                      : selectedAddress),
                                              style: GoogleFonts.poppins(
                                                color: (_isGuest ||
                                                        selectedAddress.isEmpty)
                                                    ? colors.textSecondary
                                                    : colors.textPrimary,
                                                fontSize: 11,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'IsmailTex Pickup: $vendorAddress',
                                              style: GoogleFonts.poppins(
                                                color: colors.textSecondary,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),

                          const SliverToBoxAdapter(
                              child: SizedBox(height: 12)),

                          // ── Main Action Cards ─────────────────────────
                          SliverToBoxAdapter(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _MainActionCard(
                                      title: 'Book a Ride',
                                      icon:
                                          Icons.directions_car_filled_rounded,
                                      iconBg: colors.paleBlue,
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
                                      title: 'Shop Products',
                                      icon: Icons.shopping_cart_rounded,
                                      iconBg: colors.paleOrange,
                                      onTap: () {},
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SliverToBoxAdapter(
                              child: SizedBox(height: 12)),

                          // ── Quick Action Row ──────────────────────────
                          SliverToBoxAdapter(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _QuickActionItem(
                                      icon: Icons.payments_outlined,
                                      label: 'Pay',
                                      onTap: _isGuest ? _goToLogin : () {},
                                    ),
                                  ),
                                  Expanded(
                                    child: _QuickActionItem(
                                      icon: Icons.receipt_long_rounded,
                                      label: 'My Orders',
                                      onTap: _isGuest
                                          ? _goToLogin
                                          : () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) => OrderScreen(),
                                                ),
                                              );
                                            },
                                    ),
                                  ),
                                  Expanded(
                                    child: _QuickActionItem(
                                      icon: Icons.history_rounded,
                                      label: 'History',
                                      onTap: _isGuest
                                          ? _goToLogin
                                          : () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) => OrderScreen(),
                                                ),
                                              );
                                            },
                                    ),
                                  ),
                                  Expanded(
                                    child: _QuickActionItem(
                                      icon: Icons.star_rounded,
                                      label: 'Favourites',
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
                              child: SizedBox(height: 14)),

                          // ── Category Chips ────────────────────────────
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: 40,
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16),
                                scrollDirection: Axis.horizontal,
                                itemBuilder: (_, i) {
                                  final item = categories[i];
                                  final selected =
                                      item == effectiveSelectedCategory;
                                  return ChoiceChip(
                                    label: Text(item),
                                    selected: selected,
                                    onSelected: (_) => setState(
                                      () => _selectedCategory = item,
                                    ),
                                    labelStyle: GoogleFonts.poppins(
                                      color: selected
                                          ? Colors.white
                                          : colors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
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
                              child: SizedBox(height: 10)),

                          // ── Active Services ───────────────────────────
                          if (activeServices.isNotEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                child: Column(
                                  children: activeServices.map((service) {
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
                                        status: service.status,
                                        eta: service.eta.isEmpty
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
                                              builder: (_) => RideDetailScreen(
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

                          // ── Trending Section ──────────────────────────
                          SliverToBoxAdapter(
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 10),
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
                                  const AppSectionTitle(
                                    title: 'Trending Now 🔥',
                                    spacingBottom: 0,
                                  ),
                                ],
                              ),
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
                                      'Mark products as trending from admin to show them here.',
                                ),
                              ),
                            )
                          else
                            SliverToBoxAdapter(
                              child: SizedBox(
                                height: 210,
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
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => ProductDetailScreen(
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
                              child: SizedBox(height: 16)),

                          // ── All Products Section ──────────────────────
                          SliverToBoxAdapter(
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 10),
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
                                  const AppSectionTitle(
                                    title: 'All Products',
                                    spacingBottom: 0,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          if (filtered.isEmpty)
                            const SliverFillRemaining(
                              hasScrollBody: false,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                                    delegate: SliverChildBuilderDelegate(
                                      (_, i) {
                                        final product = filtered[i];
                                        final isFavorite =
                                            favorites.contains(product.id);

                                        return GestureDetector(
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
                                          child: AppSurfaceCard(
                                            padding: EdgeInsets.zero,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Stack(
                                                    children: [
                                                      ClipRRect(
                                                        borderRadius:
                                                            const BorderRadius
                                                                .vertical(
                                                          top: Radius.circular(
                                                              20),
                                                        ),
                                                        child: _hasValidImage(
                                                                product.imageUrl)
                                                            ? Image.network(
                                                                product.imageUrl,
                                                                width: double
                                                                    .infinity,
                                                                fit:
                                                                    BoxFit.cover,
                                                                loadingBuilder:
                                                                    (context,
                                                                        child,
                                                                        progress) {
                                                                  if (progress ==
                                                                      null) {
                                                                    return child;
                                                                  }
                                                                  return Container(
                                                                    color: context
                                                                        .colorScheme
                                                                        .surfaceContainerHighest,
                                                                    child:
                                                                        const Center(
                                                                      child:
                                                                          CircularProgressIndicator(
                                                                        strokeWidth:
                                                                            2,
                                                                      ),
                                                                    ),
                                                                  );
                                                                },
                                                                errorBuilder: (_,
                                                                        __,
                                                                        ___) =>
                                                                    Container(
                                                                  color: context
                                                                      .colorScheme
                                                                      .surfaceContainerHighest,
                                                                  child:
                                                                      const Center(
                                                                    child: Icon(
                                                                      Icons
                                                                          .image_not_supported,
                                                                    ),
                                                                  ),
                                                                ),
                                                              )
                                                            : Container(
                                                                color: context
                                                                    .colorScheme
                                                                    .surfaceContainerHighest,
                                                                child:
                                                                    const Center(
                                                                  child: Icon(
                                                                    Icons
                                                                        .image_not_supported,
                                                                  ),
                                                                ),
                                                              ),
                                                      ),
                                                      // Status Chips
                                                      Positioned(
                                                        top: 8,
                                                        left: 8,
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            if (product
                                                                .isTrending)
                                                              const AppStatusChip(
                                                                label:
                                                                    'Trending',
                                                                tone:
                                                                    AppStatusChipTone
                                                                        .warning,
                                                              ),
                                                            if (product
                                                                .featured)
                                                              const Padding(
                                                                padding: EdgeInsets
                                                                    .only(
                                                                        top: 4),
                                                                child:
                                                                    AppStatusChip(
                                                                  label:
                                                                      'Featured',
                                                                  tone:
                                                                      AppStatusChipTone
                                                                          .primary,
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                      // Favourite Button
                                                      Positioned(
                                                        top: 8,
                                                        right: 8,
                                                        child: GestureDetector(
                                                          onTap: () async {
                                                            if (_isGuest) {
                                                              await _goToLogin();
                                                              return;
                                                            }
                                                            await _firebaseService
                                                                .toggleFavorite(
                                                                    product.id);
                                                          },
                                                          child: CircleAvatar(
                                                            radius: 14,
                                                            backgroundColor:
                                                                colors.surface,
                                                            child: Icon(
                                                              isFavorite
                                                                  ? Icons
                                                                      .favorite
                                                                  : Icons
                                                                      .favorite_border,
                                                              color: isFavorite
                                                                  ? colors.error
                                                                  : colors
                                                                      .iconPrimary,
                                                              size: 16,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                          8, 8, 8, 8),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        product.name,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 12,
                                                          color:
                                                              colors.textPrimary,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        product.primaryCategory,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontSize: 10,
                                                          color: colors
                                                              .textSecondary,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              '₦${product.price.toStringAsFixed(0)}',
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                color: colors
                                                                    .textPrimary,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ),
                                                          Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: colors
                                                                  .brandPrimary,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          999),
                                                            ),
                                                            child:
                                                                Text(
                                                              'Buy',
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                fontSize: 10,
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
                                      },
                                      childCount: filtered.length,
                                    ),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      childAspectRatio: 0.62,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                    ),
                                  ),
                                );
                              },
                            ),

                          // ── ITEX Promo Banner ─────────────────────────
                          SliverToBoxAdapter(
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      colors.brandPrimary,
                                      colors.cream,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colors.brandPrimary
                                          .withOpacity(0.25),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.20),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'ITEX',
                                        style: GoogleFonts.cinzel(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _isGuest
                                            ? 'Sign in to unlock favourites, delivery checkout, ride booking, and personal tracking on IsmailTex.'
                                            : 'Live route pricing now powers rides and deliveries on IsmailTex across Nigeria! 🚀',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12.5,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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
                    builder: (_) => const CartScreen(),
                  ),
                );
              } else if (index == 2) {
                if (_isGuest) {
                  _goToLogin();
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => OrderScreen(),
                  ),
                );
              } else if (index == 3) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ProfileScreen(),
                  ),
                );
              }
            },
            items: [
              BottomNavigationBarItem(
                icon: _buildBottomNavIcon(
                  icon: Icons.home_rounded,
                  count: unreadNotifications,
                ),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart_rounded),
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
        );
      },
    );
  }
}

// ── Trending Product Card ──────────────────────────────────────────────────────

class _TrendingProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const _TrendingProductCard({
    required this.product,
    required this.onTap,
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
          width: 170,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                  child: _hasValidImage
                      ? Image.network(
                          product.imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
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
                        fontSize: 13,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.primaryCategory,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₦${product.price.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        color: colors.brandPrimary,
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

// ── Main Action Card ───────────────────────────────────────────────────────────

class _MainActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconBg;
  final VoidCallback onTap;

  const _MainActionCard({
    required this.title,
    required this.icon,
    required this.iconBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppSurfaceCard(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 138,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    icon,
                    color: colors.iconOnLightTint,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Quick Action Item ──────────────────────────────────────────────────────────

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: colors.borderSoft),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: colors.iconOnLightTint,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
