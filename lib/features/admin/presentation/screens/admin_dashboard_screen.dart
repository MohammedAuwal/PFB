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
  final _authService = FirebaseAuthService();
  final _firebaseService = FirebaseService();
  final _adminNameCtrl = TextEditingController();
  final _adminEmailCtrl = TextEditingController();

  bool _addingAdmin = false;
  bool _loggingOut = false;

  bool get _isSuperAdmin => AppConstants.isSuperAdminUid(
        FirebaseAuth.instance.currentUser?.uid,
      );

  bool _hasValidImage(String url) {
    final value = url.trim();
    return value.isNotEmpty &&
        (value.startsWith('http://') || value.startsWith('https://'));
  }

  Future<void> _addAdmin() async {
    final name = _adminNameCtrl.text.trim();
    final email = _adminEmailCtrl.text.trim().toLowerCase();

    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin name and email are required'),
        ),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'User not found. The person must create an account in the app first.',
            ),
          ),
        );
        return;
      }

      final realUid = userQuery.docs.first.id;

      await _firebaseService.addAdmin(
        uid: realUid,
        email: email,
      );

      await _firebaseService.firestore
          .collection(AppConstants.adminsCollection)
          .doc(realUid)
          .set({
        'displayName': name,
      }, SetOptions(merge: true));

      _adminNameCtrl.clear();
      _adminEmailCtrl.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Success! $name is now an Admin.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: $e'),
        ),
      );
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

    final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            final colors = AppTheme.colorsOf(dialogContext);

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Log out?',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              content: Text(
                'You are about to sign out of the admin account.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  height: 1.5,
                  color: colors.textSecondary,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(
                    'Log out',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
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
                  return Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Products',
                          value: '${pSnap.data ?? 0}',
                          icon: Icons.inventory_2_rounded,
                          color: AppTheme.colorsOf(context).brandPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Orders',
                          value: '${oSnap.data ?? 0}',
                          icon: Icons.receipt_long_rounded,
                          color: AppTheme.colorsOf(context).warning,
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
                  return Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Rides',
                          value: '${rSnap.data ?? 0}',
                          icon: Icons.local_taxi_rounded,
                          color: AppTheme.colorsOf(context).info,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Admins',
                          value: '${aSnap.data ?? 1}',
                          icon: Icons.admin_panel_settings_rounded,
                          color: AppTheme.colorsOf(context).palePurple,
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
                return Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'My Products',
                        value: '${productsSnap.data?.length ?? 0}',
                        icon: Icons.inventory_2_rounded,
                        color: AppTheme.colorsOf(context).brandPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Assigned Orders',
                        value: '${ordersSnap.data ?? 0}',
                        icon: Icons.receipt_long_rounded,
                        color: AppTheme.colorsOf(context).warning,
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
                return Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Assigned Rides',
                        value: '${ridesSnap.data ?? 0}',
                        icon: Icons.local_taxi_rounded,
                        color: AppTheme.colorsOf(context).info,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Active Workload',
                        value: '${workloadSnap.data ?? 0}',
                        icon: Icons.bolt_rounded,
                        color: AppTheme.colorsOf(context).palePurple,
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
    final colors = AppTheme.colorsOf(context);

    return Scaffold(
      backgroundColor: colors.scaffold,
      appBar: AppBar(
        elevation: 0,
        title: Row(
          children: [
            // ── ITEX Brand Logo Badge ──────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
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
                    color: colors.brandPrimary.withOpacity(0.35),
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
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    _isSuperAdmin
                        ? 'Full platform control — IsmailTex'
                        : 'Manage your products & assigned requests',
                    style: GoogleFonts.poppins(
                      color: colors.textSecondary,
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
          // ── Notifications Bell ─────────────────────────────
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
                        top: -4,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: colors.error,
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
                                color: Colors.white,
                                fontSize: 8,
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
          // ── Theme Toggle ───────────────────────────────────
          IconButton(
            tooltip: 'Toggle theme',
            onPressed: () =>
                themeController.toggleDarkMode(!themeController.isDarkMode),
            icon: Icon(
              themeController.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              color: colors.iconPrimary,
            ),
          ),
          // ── User View Switch ───────────────────────────────
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: TextButton.icon(
              onPressed: _switchToUserView,
              icon: Icon(
                Icons.visibility_outlined,
                color: colors.brandPrimary,
                size: 18,
              ),
              label: Text(
                'User View',
                style: GoogleFonts.poppins(
                  color: colors.brandPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          // ── Logout ─────────────────────────────────────────
          IconButton(
            onPressed: _loggingOut ? null : _logout,
            icon: _loggingOut
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.iconPrimary,
                    ),
                  )
                : Icon(
                    Icons.logout_rounded,
                    color: colors.iconPrimary,
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: colors.brandPrimary,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddProductScreen()),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Add Product',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  // ── Admin Mode Banner ──────────────────────────
                  Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colors.brandPrimary.withOpacity(0.12),
                          colors.brandPrimary.withOpacity(0.04),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: colors.brandPrimary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.brandPrimary.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.admin_panel_settings_rounded,
                            color: colors.brandPrimary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isSuperAdmin
                                    ? 'Super Admin Mode'
                                    : 'Admin Mode — IsmailTex',
                                style: GoogleFonts.poppins(
                                  color: colors.brandPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isSuperAdmin
                                    ? 'You have full control over the IsmailTex platform.'
                                    : 'Manage your uploaded products, categories, and requests assigned to you.',
                                style: GoogleFonts.poppins(
                                  color: colors.textSecondary,
                                  fontSize: 11.5,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Stats ──────────────────────────────────────
                  _buildStatsSection(),
                  const SizedBox(height: 18),

                  // ── ITEX Notifications Panel ───────────────────
                  Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.borderSoft),
                      boxShadow: [
                        BoxShadow(
                          color: colors.brandPrimary.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: colors.brandPrimary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.notifications_active_rounded,
                                color: colors.brandPrimary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'ITEX Notifications',
                              style: GoogleFonts.poppins(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const NotificationsScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'View All',
                                style: GoogleFonts.poppins(
                                  color: colors.brandPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        StreamBuilder<List<AppNotificationModel>>(
                          stream: _firebaseService.watchAdminNotifications(),
                          builder: (context, snapshot) {
                            final notifications = snapshot.data ?? [];
                            if (notifications.isEmpty) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.inbox_rounded,
                                      color: colors.textSecondary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'No ITEX notifications yet',
                                      style: GoogleFonts.poppins(
                                        color: colors.textSecondary,
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
                                    await _firebaseService
                                        .markNotificationAsRead(
                                      n.id,
                                      recipientCollection:
                                          n.recipientCollection,
                                    );
                                    await NotificationNavigationService
                                        .instance
                                        .handlePayload({
                                      'type': n.type,
                                      'targetScreen': n.targetScreen,
                                      'targetId': n.targetId,
                                      'notificationId': n.id,
                                      'notificationCollection':
                                          n.recipientCollection,
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: n.isRead
                                          ? colors.surfaceAlt
                                          : colors.brandPrimary
                                              .withOpacity(0.08),
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      border: Border.all(
                                        color: n.isRead
                                            ? colors.borderSoft
                                            : colors.brandPrimary
                                                .withOpacity(0.25),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        if (!n.isRead)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            margin: const EdgeInsets.only(
                                              right: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: colors.brandPrimary,
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
                                                  color: colors.textPrimary,
                                                  fontWeight: n.isRead
                                                      ? FontWeight.w500
                                                      : FontWeight.w700,
                                                  fontSize: 12.5,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                n.body,
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: GoogleFonts.poppins(
                                                  color: colors.textSecondary,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.chevron_right_rounded,
                                          color: colors.textSecondary,
                                          size: 18,
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
                  ),

                  // ── Quick Action Cards ─────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.add_box_outlined,
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
                          icon: Icons.inventory_2_outlined,
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
                          icon: Icons.receipt_long_rounded,
                          title: _isSuperAdmin ? 'All Orders' : 'My Orders',
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
                          icon: Icons.local_taxi_rounded,
                          title: _isSuperAdmin
                              ? 'All Rides / Delivery'
                              : 'My Rides / Delivery',
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
                          icon: Icons.category_outlined,
                          title: 'Categories',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const ManageCategoriesScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      if (_isSuperAdmin) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.location_city_rounded,
                            title: 'Locations',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const ManageAdminLocationsScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ] else ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.visibility_outlined,
                            title: 'User Preview',
                            onTap: _switchToUserView,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (_isSuperAdmin) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.payments_rounded,
                            title: 'Payment Settings',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const PaymentSettingsScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.visibility_outlined,
                            title: 'User Preview',
                            onTap: _switchToUserView,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.warning_amber_rounded,
                            title: 'Escalations',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AdminEscalationDashboardScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.analytics_rounded,
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
                  const SizedBox(height: 18),

                  // ── Add Admin Panel (Super Admin only) ─────────
                  if (_isSuperAdmin) ...[
                    _sectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color:
                                      colors.brandPrimary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.person_add_rounded,
                                  color: colors.brandPrimary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Add Admin',
                                style: GoogleFonts.poppins(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _Field(
                            controller: _adminNameCtrl,
                            hint: 'Admin Name',
                          ),
                          const SizedBox(height: 12),
                          _Field(
                            controller: _adminEmailCtrl,
                            hint: 'Admin Email (must be a registered user)',
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _addingAdmin ? null : _addAdmin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.brandPrimary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _addingAdmin
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      'Add Admin',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(
                                Icons.people_alt_rounded,
                                color: colors.textSecondary,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Current Admins',
                                style: GoogleFonts.poppins(
                                  color: colors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          StreamBuilder<List<Map<String, dynamic>>>(
                            stream: _firebaseService.watchAdmins(),
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
                                  return Container(
                                    margin:
                                        const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.surfaceAlt,
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      border: Border.all(
                                          color: colors.borderSoft),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: colors
                                              .brandPrimary
                                              .withOpacity(0.15),
                                          child: Text(
                                            ((admin['displayName'] ??
                                                            admin['email'] ??
                                                            'A')
                                                        .toString()
                                                        .isNotEmpty
                                                    ? (admin['displayName'] ??
                                                            admin['email'] ??
                                                            'A')
                                                        .toString()[0]
                                                        .toUpperCase()
                                                    : 'A'),
                                            style: GoogleFonts.poppins(
                                              color: colors.brandPrimary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                (admin['displayName'] ??
                                                        admin['email'] ??
                                                        '')
                                                    .toString(),
                                                style: GoogleFonts.poppins(
                                                  color: colors.textPrimary,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              Text(
                                                (admin['email'] ?? '')
                                                    .toString(),
                                                style: GoogleFonts.poppins(
                                                  color:
                                                      colors.textSecondary,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colors.brandPrimary
                                                .withOpacity(0.12),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            'Admin',
                                            style: GoogleFonts.poppins(
                                              color: colors.brandPrimary,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
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
                    ),
                    const SizedBox(height: 18),
                  ],

                  // ── My Uploaded Products Header ─────────────────
                  Row(
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
                      Text(
                        'My Uploaded Products',
                        style: GoogleFonts.poppins(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // ── Products List ──────────────────────────────────────
          StreamBuilder<List<ProductModel>>(
            stream: _firebaseService.watchMyUploadedProducts(),
            builder: (context, snapshot) {
              final colors = AppTheme.colorsOf(context);

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              final items = snapshot.data ?? [];

              if (items.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: colors.borderSoft),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            color: colors.textSecondary,
                            size: 40,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No products uploaded yet',
                            style: GoogleFonts.poppins(
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap "Add Product" to get started on IsmailTex',
                            style: GoogleFonts.poppins(
                              color: colors.textSecondary,
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
                          color: colors.card,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: colors.borderSoft),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
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
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '₦${product.price.toStringAsFixed(2)} • ${product.normalizedCategories.join(', ')} • Stock ${product.stockQuantity}',
                            style: GoogleFonts.poppins(
                              color: colors.brandPrimary,
                              fontSize: 12,
                            ),
                          ),
                          trailing: PopupMenuButton<String>(
                            color: colors.surfaceAlt,
                            iconColor: colors.textSecondary,
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
                                    Icon(Icons.visibility_outlined,
                                        color: colors.textPrimary,
                                        size: 16),
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
                                    Icon(Icons.edit_outlined,
                                        color: colors.textPrimary,
                                        size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Edit',
                                      style: GoogleFonts.poppins(
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline_rounded,
                                        color: colors.error, size: 16),
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

  Widget _sectionCard({required Widget child}) {
    final colors = AppTheme.colorsOf(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.borderSoft),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: colors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action Card ───────────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.borderSoft),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.brandPrimary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: colors.brandPrimary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.textSecondary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Text Field ────────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(color: colors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: colors.textSecondary),
        filled: true,
        fillColor: colors.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.borderSoft),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.borderSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.brandPrimary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
