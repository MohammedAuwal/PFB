import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/config/routes/route_names.dart';
import 'package:pfb/core/routing/app_router.dart';
import 'package:pfb/core/theme/app_theme.dart';
import 'package:pfb/core/theme/build_context_theme_x.dart';
import 'package:pfb/features/cart/presentation/screens/cart_screen.dart';
import 'package:pfb/features/orders/presentation/screens/order_screen.dart';
import 'package:pfb/features/products/presentation/screens/product_list_screen.dart';
import 'package:pfb/features/profile/presentation/screens/profile_screen.dart';
import 'package:pfb/services/admin_preview_scope.dart';
import 'package:pfb/services/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  static const _tabKey = 'main_shell_tab_index';

  final _firebaseService = FirebaseService();
  int _currentIndex = 0;
  bool _isAdmin     = false;
  bool _loadingRole = true;

  late final List<Widget> _screens = [
    const ProductListScreen(showBottomNav: false),
    const CartScreen(showScaffold: false),
    OrderScreen(showScaffold: false),
    const ProfileScreen(showScaffold: false),
  ];

  @override
  void initState() {
    super.initState();
    _loadTab();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final isAdmin = await _firebaseService.isAdmin();
    if (!mounted) return;
    setState(() {
      _isAdmin      = isAdmin;
      _loadingRole  = false;
    });
  }

  Future<void> _loadTab() async {
    final prefs      = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt(_tabKey) ?? 0;
    if (!mounted) return;
    setState(() => _currentIndex = savedIndex);
  }

  Future<void> _saveTab(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_tabKey, index);
  }

  Future<void> _backToAdmin() async {
    AdminPreviewScope.of(context).exitPreviewMode();
    if (!mounted) return;
    await AppRouter.clearAndGo(context, RouteNames.admin);
  }

  void _handleTabTap(int index, bool isPreviewMode) {
    if (_loadingRole) return;

    if (_isAdmin && !isPreviewMode && index == 3) {
      _backToAdmin();
      return;
    }

    setState(() => _currentIndex = index);
    _saveTab(index);
  }

  bool _hasValidImage(String? url) {
    if (url == null) return false;
    final v = url.trim();
    return v.isNotEmpty &&
        (v.startsWith('http://') || v.startsWith('https://'));
  }

  @override
  Widget build(BuildContext context) {
    final previewController = AdminPreviewScope.of(context);
    final isPreviewMode     = previewController.isPreviewMode;
    final colors            = context.appColors;
    final isDark            = context.isDarkMode;

    return StreamBuilder<int>(
      stream: _firebaseService.watchCartCount(),
      builder: (context, cartSnapshot) {
        final cartCount = cartSnapshot.data ?? 0;

        return StreamBuilder<List<String>>(
          stream: _firebaseService.watchFavorites(),
          builder: (context, favSnapshot) {
            final favCount = favSnapshot.data?.length ?? 0;

            return StreamBuilder<Map<String, dynamic>?>(
              stream: _firebaseService.watchUserProfile(),
              builder: (context, userSnapshot) {
                final photoUrl =
                    (userSnapshot.data?['photoUrl'] ?? '').toString();

                return Scaffold(
                  backgroundColor: colors.scaffold,
                  body: Column(
                    children: [
                      // ── Admin Preview Banner ─────────────────────────
                      if (!_loadingRole && _isAdmin && isPreviewMode)
                        _AdminPreviewBanner(
                          colors:       colors,
                          onBackToAdmin: _backToAdmin,
                        ),

                      Expanded(
                        child: IndexedStack(
                          index:    _currentIndex,
                          children: _screens,
                        ),
                      ),
                    ],
                  ),

                  // ── Bottom Navigation Bar ────────────────────────────
                  bottomNavigationBar: _PhlakesBottomNav(
                    currentIndex:  _currentIndex,
                    cartCount:     cartCount,
                    favCount:      favCount,
                    photoUrl:      photoUrl,
                    isAdmin:       _isAdmin,
                    isPreviewMode: isPreviewMode,
                    colors:        colors,
                    isDark:        isDark,
                    onTap: (index) => _handleTabTap(index, isPreviewMode),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Admin Preview Banner
// ─────────────────────────────────────────────────────────────────────────────

class _AdminPreviewBanner extends StatelessWidget {
  final AppThemeColors colors;
  final VoidCallback onBackToAdmin;

  const _AdminPreviewBanner({
    required this.colors,
    required this.onBackToAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        // Gold gradient banner — luxury admin preview indicator
        gradient: LinearGradient(
          colors: [
            AppPalette.primaryDark,
            AppPalette.primary,
            AppPalette.primaryLight,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Icon(
              Icons.visibility_rounded,
              color: AppPalette.secondary,   // black icon on gold
              size:  18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Preview Mode — User View',
                style: GoogleFonts.poppins(
                  color:      AppPalette.secondary,
                  fontWeight: FontWeight.w700,
                  fontSize:   13,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            TextButton(
              onPressed: onBackToAdmin,
              style: TextButton.styleFrom(
                foregroundColor: AppPalette.secondary,
                backgroundColor: Colors.black.withOpacity(0.12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical:   8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Back to Admin',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize:   12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Phlakes Bottom Navigation Bar
// ─────────────────────────────────────────────────────────────────────────────

class _PhlakesBottomNav extends StatelessWidget {
  final int currentIndex;
  final int cartCount;
  final int favCount;
  final String photoUrl;
  final bool isAdmin;
  final bool isPreviewMode;
  final AppThemeColors colors;
  final bool isDark;
  final ValueChanged<int> onTap;

  const _PhlakesBottomNav({
    required this.currentIndex,
    required this.cartCount,
    required this.favCount,
    required this.photoUrl,
    required this.isAdmin,
    required this.isPreviewMode,
    required this.colors,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Inactive color: light mode #8A8A8A, dark mode #6B6B6B
    final inactiveColor = isDark
        ? const Color(0xFF6B6B6B)
        : const Color(0xFF8A8A8A);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        // Subtle gold top border — luxury accent
        border: Border(
          top: BorderSide(
            color: colors.brandPrimary.withOpacity(0.18),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color:      isDark
                ? Colors.black.withOpacity(0.50)
                : Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset:     const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex:        currentIndex,
          type:                BottomNavigationBarType.fixed,
          backgroundColor:     Colors.transparent,
          selectedItemColor:   colors.brandPrimary,   // gold when active
          unselectedItemColor: inactiveColor,
          selectedLabelStyle: GoogleFonts.poppins(
            fontWeight:   FontWeight.w700,
            fontSize:     11,
            letterSpacing: 0.2,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize:   11,
          ),
          elevation: 0,
          onTap:     onTap,
          items: [
            // ── Home ───────────────────────────────────────────────
            const BottomNavigationBarItem(
              icon:  Icon(Icons.home_rounded),
              label: 'Home',
            ),

            // ── Cart with badge ────────────────────────────────────
            BottomNavigationBarItem(
              icon: _NavBadgeIcon(
                icon:        Icons.shopping_bag_outlined,
                activeIcon:  Icons.shopping_bag_rounded,
                count:       cartCount,
                isActive:    currentIndex == 1,
                activeColor: colors.brandPrimary,
                badgeColor:  colors.error,
              ),
              label: 'Cart',
            ),

            // ── Orders ─────────────────────────────────────────────
            const BottomNavigationBarItem(
              icon:  Icon(Icons.receipt_long_rounded),
              label: 'Orders',
            ),

            // ── Profile / Admin ────────────────────────────────────
            BottomNavigationBarItem(
              icon: _NavBadgeIcon(
                icon: isAdmin && !isPreviewMode
                    ? Icons.admin_panel_settings_rounded
                    : Icons.person_outline_rounded,
                activeIcon: isAdmin && !isPreviewMode
                    ? Icons.admin_panel_settings_rounded
                    : Icons.person_rounded,
                count:       favCount,
                isActive:    currentIndex == 3,
                activeColor: colors.brandPrimary,
                badgeColor:  colors.brandPrimary,   // gold badge for profile
                photoUrl:    isAdmin && !isPreviewMode ? null : photoUrl,
              ),
              label: isAdmin && !isPreviewMode ? 'Admin' : 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nav Badge Icon
// ─────────────────────────────────────────────────────────────────────────────

class _NavBadgeIcon extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final int count;
  final bool isActive;
  final Color activeColor;
  final Color badgeColor;
  final String? photoUrl;

  const _NavBadgeIcon({
    required this.icon,
    required this.activeIcon,
    required this.count,
    required this.isActive,
    required this.activeColor,
    required this.badgeColor,
    this.photoUrl,
  });

  bool _hasValidImage(String? url) {
    if (url == null) return false;
    final v = url.trim();
    return v.isNotEmpty &&
        (v.startsWith('http://') || v.startsWith('https://'));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    Widget mainContent;

    if (_hasValidImage(photoUrl)) {
      // ── User avatar with gold ring when active ──────────────────
      mainContent = Container(
        width:  26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: NetworkImage(photoUrl!.trim()),
            fit:   BoxFit.cover,
          ),
          border: Border.all(
            color: isActive
                ? activeColor                   // gold ring when active
                : colors.borderSoft,
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color:      activeColor.withOpacity(0.30),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
      );
    } else {
      mainContent = Icon(
        isActive ? activeIcon : icon,
        // Icon color is handled by BottomNavigationBar itself
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      alignment:    Alignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(2),
          child: mainContent,
        ),
        if (count > 0)
          Positioned(
            right: -10,
            top:   -6,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 5,
                vertical:   1.5,
              ),
              decoration: BoxDecoration(
                // Gold badge for profile count, error for cart
                color:        badgeColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colors.surface,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color:      badgeColor.withOpacity(0.40),
                    blurRadius: 4,
                    spreadRadius: 0,
                  ),
                ],
              ),
              constraints: const BoxConstraints(minWidth: 18),
              child: Text(
                count > 99 ? '99+' : '$count',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color:      Colors.white,
                  fontSize:   9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
