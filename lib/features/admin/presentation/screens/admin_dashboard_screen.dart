import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pfb/config/routes/route_names.dart';
import 'package:pfb/core/constants/app_constants.dart';
import 'package:pfb/core/routing/app_router.dart';
import 'package:pfb/core/theme/app_theme.dart';
import 'package:pfb/core/theme/theme_scope.dart';
import 'package:pfb/features/admin/presentation/screens/add_product_screen.dart';
import 'package:pfb/features/admin/presentation/screens/admin_escalation_dashboard_screen.dart';
import 'package:pfb/features/admin/presentation/screens/admin_orders_screen.dart';
import 'package:pfb/features/admin/presentation/screens/admin_rides_screen.dart';
import 'package:pfb/features/admin/presentation/screens/edit_product_screen.dart';
import 'package:pfb/features/admin/presentation/screens/manage_admin_locations_screen.dart';
import 'package:pfb/features/admin/presentation/screens/manage_categories_screen.dart';
import 'package:pfb/features/admin/presentation/screens/manage_products_screen.dart';
import 'package:pfb/features/admin/presentation/screens/payment_settings_screen.dart';
import 'package:pfb/features/admin/presentation/screens/super_admin_analytics_screen.dart';
import 'package:pfb/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:pfb/features/products/presentation/screens/product_detail_screen.dart';
import 'package:pfb/models/app_notification_model.dart';
import 'package:pfb/models/product_model.dart';
import 'package:pfb/services/admin_preview_scope.dart';
import 'package:pfb/services/firebase_auth_service.dart';
import 'package:pfb/services/firebase_service.dart';
import 'package:pfb/services/notification_navigation_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _authService     = FirebaseAuthService();
  final _firebaseService = FirebaseService();
  final _adminNameCtrl   = TextEditingController();
  final _adminEmailCtrl  = TextEditingController();

  bool _addingAdmin = false;
  bool _loggingOut  = false;

  bool get _isSuperAdmin => AppConstants.isSuperAdminUid(
        FirebaseAuth.instance.currentUser?.uid,
      );

  bool _hasValidImage(String url) {
    final v = url.trim();
    return v.isNotEmpty &&
        (v.startsWith('http://') || v.startsWith('https://'));
  }

  void _showSnack(String message, {bool isError = false}) {
    final colors = AppTheme.colorsOf(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
        ),
        backgroundColor: isError ? colors.error : AppPalette.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _addAdmin() async {
    final name  = _adminNameCtrl.text.trim();
    final email = _adminEmailCtrl.text.trim().toLowerCase();

    if (name.isEmpty || email.isEmpty) {
      _showSnack('Admin name and email are required', isError: true);
      return;
    }

    setState(() => _addingAdmin = true);

    try {
      final userQuery = await _firebaseService.firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        if (!mounted) return;
        _showSnack(
          'User not found. The person must create an account first.',
          isError: true,
        );
        return;
      }

      final realUid = userQuery.docs.first.id;

      await _firebaseService.addAdmin(uid: realUid, email: email);

      await _firebaseService.firestore
          .collection(AppConstants.adminsCollection)
          .doc(realUid)
          .set({'displayName': name}, SetOptions(merge: true));

      _adminNameCtrl.clear();
      _adminEmailCtrl.clear();

      if (!mounted) return;
      _showSnack('$name is now an Admin ✓');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _addingAdmin = false);
    }
  }

  Future<void> _switchToUserView() async {
    AdminPreviewScope.of(context).enterPreviewMode();
    if (!mounted) return;
    await AppRouter.clearAndGo(context, RouteNames.mainShell);
  }

  Future<void> _logout() async {
    if (_loggingOut) return;

    final colors = AppTheme.colorsOf(context);

    final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
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
                  'Log out?',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color:      colors.textPrimary,
                  ),
                ),
              ],
            ),
            content: Text(
              'You are about to sign out of the admin account.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                height:   1.5,
                color:    colors.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                style: TextButton.styleFrom(
                  foregroundColor: colors.textSecondary,
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.primary,
                  foregroundColor: AppPalette.secondary,
                  elevation:       0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Log out',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldLogout || !mounted) return;

    setState(() => _loggingOut = true);
    try {
      AdminPreviewScope.of(context).reset();
      await _authService.signOut();
      if (!mounted) return;
      await AppRouter.clearAndGo(context, RouteNames.login);
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _firebaseService.seedDefaultCategoriesIfMissingSafely();
    _firebaseService.seedDefaultAppSettingsSafely();
  }

  @override
  void dispose() {
    _adminNameCtrl.dispose();
    _adminEmailCtrl.dispose();
    super.dispose();
  }

  Widget _buildStatsSection() {
    if (_isSuperAdmin) {
      return Column(
        children: [
          StreamBuilder<int>(
            stream: _firebaseService.watchProductsCount(),
            builder: (context, pSnap) {
              return StreamBuilder<int>(
                stream: _firebaseService.watchOrdersCount(),
                builder: (context, oSnap) {
                  final colors = AppTheme.colorsOf(context);
                  return Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Products',
                          value: '${pSnap.data ?? 0}',
                          icon:  Icons.inventory_2_rounded,
                          color: colors.brandPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Orders',
                          value: '${oSnap.data ?? 0}',
                          icon:  Icons.receipt_long_rounded,
                          color: colors.warning,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 12),
          StreamBuilder<int>(
            stream: _firebaseService.watchRidesCount(),
            builder: (context, rSnap) {
              return StreamBuilder<int>(
                stream: _firebaseService.watchAdminsCount(),
                builder: (context, aSnap) {
                  final colors = AppTheme.colorsOf(context);
                  return Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Rides',
                          value: '${rSnap.data ?? 0}',
                          icon:  Icons.local_taxi_rounded,
                          color: colors.info,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Admins',
                          value: '${aSnap.data ?? 1}',
                          icon:  Icons.admin_panel_settings_rounded,
                          color: colors.success,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      );
    }

    return Column(
      children: [
        StreamBuilder<List<ProductModel>>(
          stream: _firebaseService.watchMyUploadedProducts(),
          builder: (context, productsSnap) {
            return StreamBuilder<int>(
              stream: _firebaseService.watchAssignedOrdersCount(),
              builder: (context, ordersSnap) {
                final colors = AppTheme.colorsOf(context);
                return Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'My Products',
                        value: '${productsSnap.data?.length ?? 0}',
                        icon:  Icons.inventory_2_rounded,
                        color: colors.brandPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Assigned Orders',
                        value: '${ordersSnap.data ?? 0}',
                        icon:  Icons.receipt_long_rounded,
                        color: colors.warning,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
        const SizedBox(height: 12),
        StreamBuilder<int>(
          stream: _firebaseService.watchAssignedRidesCount(),
          builder: (context, ridesSnap) {
            return StreamBuilder<int>(
              stream: _firebaseService.watchAssignedActiveWorkloadCount(),
              builder: (context, workloadSnap) {
                final colors = AppTheme.colorsOf(context);
                return Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Assigned Rides',
                        value: '${ridesSnap.data ?? 0}',
                        icon:  Icons.local_taxi_rounded,
                        color: colors.info,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Active Workload',
                        value: '${workloadSnap.data ?? 0}',
                        icon:  Icons.bolt_rounded,
                        color: colors.success,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeScope.of(context);
    final colors          = AppTheme.colorsOf(context);
    final isDark          = themeController.isDarkMode;

    return Scaffold(
      backgroundColor: colors.scaffold,

      // ── App Bar ──────────────────────────────────────────────────────
      appBar: AppBar(
        elevation:              0,
        scrolledUnderElevation: 0,
        backgroundColor:        colors.scaffold,
        surfaceTintColor:       Colors.transparent,
        title: Row(
          children: [
            // ── Phlakes PF badge ────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical:   6,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppPalette.primaryDark,
                    AppPalette.primary,
                  ],
                  begin: Alignment.topLeft,
                  end:   Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color:      AppPalette.primary.withOpacity(0.30),
                    blurRadius: 8,
                    offset:     const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                'PF',
                style: GoogleFonts.montserrat(
                  // Black text on gold badge
                  color:       AppPalette.secondary,
                  fontSize:    13,
                  fontWeight:  FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isSuperAdmin
                        ? 'Super Admin Dashboard'
                        : 'Admin Dashboard',
                    style: GoogleFonts.poppins(
                      color:      colors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize:   14,
                    ),
                  ),
                  Text(
                    _isSuperAdmin
                        ? 'Full platform control — Phlakes Fabrics'
                        : 'Manage products & assigned requests',
                    style: GoogleFonts.poppins(
                      color:    colors.textSecondary,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // ── Notifications ──────────────────────────────────────
          StreamBuilder<int>(
            stream: _firebaseService.watchUnreadNotificationCount(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return IconButton(
                tooltip: 'Notifications',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                },
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      color: colors.iconPrimary,
                    ),
                    if (count > 0)
                      Positioned(
                        right: -4,
                        top:   -4,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth:  16,
                            minHeight: 16,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical:   1,
                          ),
                          decoration: BoxDecoration(
                            color:        colors.error,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: colors.scaffold,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              count > 99 ? '99+' : '$count',
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
                ),
              );
            },
          ),

          // ── Theme Toggle ───────────────────────────────────────
          IconButton(
            tooltip: isDark ? 'Light mode' : 'Dark mode',
            onPressed: () => themeController
                .toggleDarkMode(!themeController.isDarkMode),
            icon: Icon(
              isDark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              color: colors.iconPrimary,
            ),
          ),

          // ── User View ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: TextButton.icon(
              onPressed: _switchToUserView,
              style: TextButton.styleFrom(
                foregroundColor: colors.brandPrimary,
              ),
              icon: Icon(
                Icons.visibility_outlined,
                color: colors.brandPrimary,
                size:  18,
              ),
              label: Text(
                'User View',
                style: GoogleFonts.poppins(
                  color:      colors.brandPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize:   12,
                ),
              ),
            ),
          ),

          // ── Logout ─────────────────────────────────────────────
          IconButton(
            onPressed: _loggingOut ? null : _logout,
            icon: _loggingOut
                ? SizedBox(
                    width:  18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color:       colors.brandPrimary,
                    ),
                  )
                : Icon(
                    Icons.logout_rounded,
                    color: colors.iconPrimary,
                  ),
          ),
        ],
      ),

      // ── Gold FAB ─────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppPalette.primary,
        foregroundColor: AppPalette.secondary,
        elevation:       4,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddProductScreen()),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Add Product',
          style: GoogleFonts.poppins(
            fontWeight:   FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),

      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Admin Mode Banner ────────────────────────────────
                Container(
                  margin:  const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    // Luxury black → gold gradient banner
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              const Color(0xFF0D0D0D),
                              const Color(0xFF1A1A08),
                              AppPalette.primaryDark.withOpacity(0.60),
                            ]
                          : [
                              AppPalette.secondary,
                              const Color(0xFF2A2A2A),
                              AppPalette.primaryDark,
                            ],
                      stops: const [0.0, 0.55, 1.0],
                      begin: Alignment.centerLeft,
                      end:   Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color:      AppPalette.primary.withOpacity(0.18),
                        blurRadius: 14,
                        offset:     const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:  Colors.white.withOpacity(0.12),
                          shape:  BoxShape.circle,
                          border: Border.all(
                            color: AppPalette.primary.withOpacity(0.35),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.admin_panel_settings_rounded,
                          color: AppPalette.primary,
                          size:  22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isSuperAdmin
                                  ? 'Super Admin Mode'
                                  : 'Admin Mode',
                              style: GoogleFonts.montserrat(
                                color:       AppPalette.primary,
                                fontWeight:  FontWeight.w900,
                                fontSize:    13,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _isSuperAdmin
                                  ? 'Full control over the Phlakes Fabrics platform.'
                                  : 'Manage your uploaded products, categories, and requests.',
                              style: GoogleFonts.poppins(
                                color:    Colors.white70,
                                fontSize: 11.5,
                                height:   1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Stats ────────────────────────────────────────────
                _buildStatsSection(),
                const SizedBox(height: 20),

                // ── Notifications Panel ──────────────────────────────
                _NotificationsPanel(
                  colors:          colors,
                  firebaseService: _firebaseService,
                ),
                const SizedBox(height: 20),

                // ── Quick Action Cards ───────────────────────────────
                _QuickActionsGrid(
                  isSuperAdmin:    _isSuperAdmin,
                  colors:          colors,
                  firebaseService: _firebaseService,
                  onSwitchToUserView: _switchToUserView,
                ),

                const SizedBox(height: 20),

                // ── Add Admin Panel (Super Admin only) ───────────────
                if (_isSuperAdmin) ...[
                  _AddAdminPanel(
                    colors:           colors,
                    adminNameCtrl:    _adminNameCtrl,
                    adminEmailCtrl:   _adminEmailCtrl,
                    addingAdmin:      _addingAdmin,
                    onAddAdmin:       _addAdmin,
                    firebaseService:  _firebaseService,
                  ),
                  const SizedBox(height: 20),
                ],

                // ── My Products Header ───────────────────────────────
                Row(
                  children: [
                    Container(
                      width:  3.5,
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
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
                    Text(
                      'My Uploaded Products',
                      style: GoogleFonts.poppins(
                        color:      colors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize:   17,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ]),
            ),
          ),

          // ── Products List ────────────────────────────────────────────
          StreamBuilder<List<ProductModel>>(
            stream: _firebaseService.watchMyUploadedProducts(),
            builder: (context, snapshot) {
              final colors = AppTheme.colorsOf(context);

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppPalette.primary,
                      ),
                    ),
                  ),
                );
              }

              final items = snapshot.data ?? [];

              if (items.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color:        colors.card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: colors.brandPrimary.withOpacity(0.15),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width:  56,
                            height: 56,
                            decoration: BoxDecoration(
                              color:  colors.brandPrimary.withOpacity(0.08),
                              shape:  BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.inventory_2_outlined,
                              color: colors.brandPrimary,
                              size:  28,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'No products uploaded yet',
                            style: GoogleFonts.poppins(
                              color:      colors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize:   15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap "Add Product" to add your first fabric',
                            style: GoogleFonts.poppins(
                              color:    colors.textSecondary,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = items[index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color:        colors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colors.borderSoft,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:      Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset:     const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width:  56,
                              height: 56,
                              child: _hasValidImage(product.imageUrl)
                                  ? Image.network(
                                      product.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          Container(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        child: Icon(
                                          Icons.image_not_supported,
                                          color: colors.textSecondary,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
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
                              color:      colors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '₦${product.price.toStringAsFixed(0)} · '
                            '${product.normalizedCategories.join(', ')} · '
                            'Stock: ${product.stockQuantity}',
                            style: GoogleFonts.poppins(
                              // Gold price text — brand consistent
                              color:    colors.brandPrimary,
                              fontSize: 12,
                            ),
                          ),
                          trailing: PopupMenuButton<String>(
                            color:      colors.surfaceAlt,
                            iconColor:  colors.textSecondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            onSelected: (value) async {
                              if (value == 'preview') {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailScreen(
                                      product: product,
                                    ),
                                  ),
                                );
                              } else if (value == 'edit') {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => EditProductScreen(
                                      product: product,
                                    ),
                                  ),
                                );
                              } else if (value == 'delete') {
                                await _firebaseService
                                    .deleteProduct(product.id);
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'preview',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.visibility_outlined,
                                      color: colors.textPrimary,
                                      size:  16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Preview',
                                      style: GoogleFonts.poppins(
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit_outlined,
                                      color: colors.brandPrimary,
                                      size:  16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Edit',
                                      style: GoogleFonts.poppins(
                                        color: colors.brandPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline_rounded,
                                      color: colors.error,
                                      size:  16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Delete',
                                      style: GoogleFonts.poppins(
                                        color: colors.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: items.length,
                  ),
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
// Notifications Panel
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationsPanel extends StatelessWidget {
  final AppThemeColors colors;
  final FirebaseService firebaseService;

  const _NotificationsPanel({
    required this.colors,
    required this.firebaseService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.brandPrimary.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  // Gold icon background
                  color:        AppPalette.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: AppPalette.primary,
                  size:  18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Notifications',
                style: GoogleFonts.poppins(
                  color:      colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize:   15,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: colors.brandPrimary,
                ),
                child: Text(
                  'View All',
                  style: GoogleFonts.poppins(
                    color:      colors.brandPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize:   12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          StreamBuilder<List<AppNotificationModel>>(
            stream: firebaseService.watchAdminNotifications(),
            builder: (context, snapshot) {
              final notifications = snapshot.data ?? [];

              if (notifications.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.inbox_rounded,
                        color: colors.textSecondary,
                        size:  18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'No notifications yet',
                        style: GoogleFonts.poppins(
                          color:    colors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final recent = notifications.take(5).toList();

              return Column(
                children: recent.map((n) {
                  return InkWell(
                    onTap: () async {
                      await firebaseService.markNotificationAsRead(
                        n.id,
                        recipientCollection: n.recipientCollection,
                      );
                      await NotificationNavigationService.instance
                          .handlePayload({
                        'type':                   n.type,
                        'targetScreen':           n.targetScreen,
                        'targetId':               n.targetId,
                        'notificationId':         n.id,
                        'notificationCollection': n.recipientCollection,
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin:  const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: n.isRead
                            ? colors.surfaceAlt
                            : AppPalette.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: n.isRead
                              ? colors.borderSoft
                              : AppPalette.primary.withOpacity(0.22),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Unread gold dot
                          if (!n.isRead)
                            Container(
                              width:  8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: const BoxDecoration(
                                color: AppPalette.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  n.title,
                                  style: GoogleFonts.poppins(
                                    color:      colors.textPrimary,
                                    fontWeight: n.isRead
                                        ? FontWeight.w500
                                        : FontWeight.w700,
                                    fontSize:   12.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  n.body,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    color:    colors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: colors.textSecondary,
                            size:  18,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Actions Grid
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActionsGrid extends StatelessWidget {
  final bool isSuperAdmin;
  final AppThemeColors colors;
  final FirebaseService firebaseService;
  final VoidCallback onSwitchToUserView;

  const _QuickActionsGrid({
    required this.isSuperAdmin,
    required this.colors,
    required this.firebaseService,
    required this.onSwitchToUserView,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon:  Icons.add_box_outlined,
                title: 'Add Product',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AddProductScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon:  Icons.inventory_2_outlined,
                title: 'Manage Products',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ManageProductsScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon:  Icons.receipt_long_rounded,
                title: isSuperAdmin ? 'All Orders' : 'My Orders',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AdminOrdersScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon:  Icons.local_taxi_rounded,
                title: isSuperAdmin ? 'All Rides' : 'My Rides',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AdminRidesScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon:  Icons.category_outlined,
                title: 'Categories',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ManageCategoriesScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: isSuperAdmin
                  ? _ActionCard(
                      icon:  Icons.location_city_rounded,
                      title: 'Locations',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const ManageAdminLocationsScreen(),
                          ),
                        );
                      },
                    )
                  : _ActionCard(
                      icon:  Icons.visibility_outlined,
                      title: 'User Preview',
                      onTap: onSwitchToUserView,
                    ),
            ),
          ],
        ),
        if (isSuperAdmin) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon:  Icons.payments_rounded,
                  title: 'Payment Settings',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PaymentSettingsScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  icon:  Icons.visibility_outlined,
                  title: 'User Preview',
                  onTap: onSwitchToUserView,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon:  Icons.warning_amber_rounded,
                  title: 'Escalations',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AdminEscalationDashboardScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  icon:  Icons.analytics_rounded,
                  title: 'Analytics',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            const SuperAdminAnalyticsScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Admin Panel
// ─────────────────────────────────────────────────────────────────────────────

class _AddAdminPanel extends StatelessWidget {
  final AppThemeColors colors;
  final TextEditingController adminNameCtrl;
  final TextEditingController adminEmailCtrl;
  final bool addingAdmin;
  final VoidCallback onAddAdmin;
  final FirebaseService firebaseService;

  const _AddAdminPanel({
    required this.colors,
    required this.adminNameCtrl,
    required this.adminEmailCtrl,
    required this.addingAdmin,
    required this.onAddAdmin,
    required this.firebaseService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:        colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.brandPrimary.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset:     const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:        AppPalette.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_add_rounded,
                  color: AppPalette.primary,
                  size:  18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Add Admin',
                style: GoogleFonts.poppins(
                  color:      colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize:   16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Fields
          _Field(controller: adminNameCtrl, hint: 'Admin Name'),
          const SizedBox(height: 12),
          _Field(
            controller: adminEmailCtrl,
            hint:       'Admin Email (must be a registered user)',
          ),
          const SizedBox(height: 16),

          // Gold button
          SizedBox(
            width:  double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: addingAdmin ? null : onAddAdmin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.primary,
                foregroundColor: AppPalette.secondary,
                elevation:       0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: addingAdmin
                  ? const SizedBox(
                      width:  20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color:       AppPalette.secondary,
                      ),
                    )
                  : Text(
                      'Add Admin',
                      style: GoogleFonts.poppins(
                        fontWeight:   FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 18),

          // Current admins list
          Row(
            children: [
              Icon(
                Icons.people_alt_rounded,
                color: colors.textSecondary,
                size:  16,
              ),
              const SizedBox(width: 6),
              Text(
                'Current Admins',
                style: GoogleFonts.poppins(
                  color:      colors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize:   13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          StreamBuilder<List<Map<String, dynamic>>>(
            stream: firebaseService.watchAdmins(),
            builder: (context, snapshot) {
              final admins = snapshot.data ?? [];

              if (admins.isEmpty) {
                return Text(
                  'No extra admins yet',
                  style: GoogleFonts.poppins(
                    color: colors.textSecondary,
                  ),
                );
              }

              return Column(
                children: admins.map((admin) {
                  final displayName =
                      (admin['displayName'] ?? admin['email'] ?? 'A')
                          .toString();
                  final initial =
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A';
                  final email =
                      (admin['email'] ?? '').toString();

                  return Container(
                    margin:  const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical:   10,
                    ),
                    decoration: BoxDecoration(
                      color:        colors.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.borderSoft),
                    ),
                    child: Row(
                      children: [
                        // Gold avatar
                        Container(
                          width:  36,
                          height: 36,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                AppPalette.primaryDark,
                                AppPalette.primary,
                              ],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: GoogleFonts.montserrat(
                                color:      AppPalette.secondary,
                                fontWeight: FontWeight.w800,
                                fontSize:   14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: GoogleFonts.poppins(
                                  color:      colors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize:   13,
                                ),
                              ),
                              Text(
                                email,
                                style: GoogleFonts.poppins(
                                  color:    colors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical:   4,
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
                          child: Text(
                            'Admin',
                            style: GoogleFonts.poppins(
                              color:      AppPalette.secondary,
                              fontSize:   10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat Card
// ─────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSoft),
        boxShadow: [
          BoxShadow(
            color:      color.withOpacity(0.08),
            blurRadius: 10,
            offset:     const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:        color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.poppins(
              color:      color,
              fontWeight: FontWeight.w800,
              fontSize:   22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.poppins(
              color:      colors.textSecondary,
              fontSize:   11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action Card
// ─────────────────────────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return Material(
      color:        colors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical:   14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.borderSoft,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  // Gold-tinted icon background
                  color:        AppPalette.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: AppPalette.primary.withOpacity(0.20),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: AppPalette.primary,
                  size:  18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    color:      colors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize:   12.5,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.textSecondary,
                size:  18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Text Field
// ─────────────────────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;

  const _Field({
    required this.controller,
    required this.hint,
    this.maxLines    = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return TextField(
      controller:   controller,
      maxLines:     maxLines,
      keyboardType: keyboardType,
      cursorColor:  AppPalette.primary,
      style: GoogleFonts.poppins(color: colors.textPrimary),
      decoration: InputDecoration(
        hintText:  hint,
        hintStyle: GoogleFonts.poppins(color: colors.textSecondary),
        filled:    true,
        fillColor: colors.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   BorderSide(color: colors.borderSoft),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   BorderSide(color: colors.borderSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   BorderSide(
            color: AppPalette.primary,
            width: 1.8,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical:   14,
        ),
      ),
    );
  }
}
