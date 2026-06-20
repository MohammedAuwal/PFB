import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/config/routes/route_names.dart';
import 'package:pfb/core/routing/app_router.dart';
import 'package:pfb/core/theme/build_context_theme_x.dart';
import 'package:pfb/features/cart/presentation/screens/cart_screen.dart';
import 'package:pfb/features/favorites/presentation/screens/favorites_screen.dart';
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
  bool _isAdmin = false;
  bool _loadingRole = true;

  late final List<Widget> _screens = [
    const ProductListScreen(showBottomNav: false),
    const CartScreen(showScaffold: false),
    OrderScreen(showScaffold: false),
    const FavoritesScreen(showScaffold: false),
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
      _isAdmin = isAdmin;
      _loadingRole = false;
    });
  }

  Future<void> _loadTab() async {
    final prefs = await SharedPreferences.getInstance();
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

    // Last tab (index 4) = Profile — if admin not in preview, go back to admin
    if (_isAdmin && !isPreviewMode && index == 4) {
      _backToAdmin();
      return;
    }

    setState(() => _currentIndex = index);
    _saveTab(index);
  }

  bool _hasValidImage(String? url) {
    if (url == null) return false;
    final value = url.trim();
    return value.isNotEmpty &&
        (value.startsWith('http://') || value.startsWith('https://'));
  }

  @override
  Widget build(BuildContext context) {
    final previewController = AdminPreviewScope.of(context);
    final isPreviewMode = previewController.isPreviewMode;
    final colors = context.appColors;

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
                      // ── Admin Preview Banner ────────────────────────
                      if (!_loadingRole && _isAdmin && isPreviewMode)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colors.brandPrimary,
                                colors.brandPrimary.withOpacity(0.75),
                              ],
                            ),
                          ),
                          child: SafeArea(
                            bottom: false,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.visibility_rounded,
                                  color: Colors.black,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Preview Mode — Customer View',
                                    style: GoogleFonts.poppins(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _backToAdmin,
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  child: Text(
                                    'Back to Admin',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // ── Screen Body ─────────────────────────────────
                      Expanded(
                        child: IndexedStack(
                          index: _currentIndex,
                          children: _screens,
                        ),
                      ),
                    ],
                  ),

                  // ── Bottom Navigation Bar ────────────────────────────
                  bottomNavigationBar: _IsmailTexBottomNav(
                    currentIndex: _currentIndex,
                    cartCount: cartCount,
                    favCount: favCount,
                    isAdmin: _isAdmin,
                    isPreviewMode: isPreviewMode,
                    photoUrl: _hasValidImage(photoUrl) ? photoUrl : null,
                    onTap: (i) => _handleTabTap(i, isPreviewMode),
                    colors: colors,
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

// ── IsmailTex Bottom Navigation Bar ───────────────────────────────────────────

class _IsmailTexBottomNav extends StatelessWidget {
  final int currentIndex;
  final int cartCount;
  final int favCount;
  final bool isAdmin;
  final bool isPreviewMode;
  final String? photoUrl;
  final ValueChanged<int> onTap;
  final dynamic colors;

  const _IsmailTexBottomNav({
    required this.currentIndex,
    required this.cartCount,
    required this.favCount,
    required this.isAdmin,
    required this.isPreviewMode,
    required this.photoUrl,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        boxShadow: [
          BoxShadow(
            color: c.shadow,
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
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // ── Home ──────────────────────────────────────────────
              _NavItem(
                icon: Icons.home_rounded,
                outlinedIcon: Icons.home_outlined,
                label: 'Home',
                selected: currentIndex == 0,
                onTap: () => onTap(0),
              ),

              // ── Cart ──────────────────────────────────────────────
              _NavItem(
                icon: Icons.shopping_bag_rounded,
                outlinedIcon: Icons.shopping_bag_outlined,
                label: 'Cart',
                selected: currentIndex == 1,
                badgeCount: cartCount,
                onTap: () => onTap(1),
              ),

              // ── Orders ────────────────────────────────────────────
              _NavItem(
                icon: Icons.receipt_long_rounded,
                outlinedIcon: Icons.receipt_long_outlined,
                label: 'Orders',
                selected: currentIndex == 2,
                onTap: () => onTap(2),
              ),

              // ── Wishlist ──────────────────────────────────────────
              _NavItem(
                icon: Icons.favorite_rounded,
                outlinedIcon: Icons.favorite_border_rounded,
                label: 'Wishlist',
                selected: currentIndex == 3,
                badgeCount: favCount,
                onTap: () => onTap(3),
              ),

              // ── Profile / Admin ───────────────────────────────────
              _NavItem(
                icon: isAdmin && !isPreviewMode
                    ? Icons.admin_panel_settings_rounded
                    : Icons.person_rounded,
                outlinedIcon: isAdmin && !isPreviewMode
                    ? Icons.admin_panel_settings_outlined
                    : Icons.person_outline_rounded,
                label: isAdmin && !isPreviewMode ? 'Admin' : 'Profile',
                selected: currentIndex == 4,
                photoUrl: isAdmin && !isPreviewMode ? null : photoUrl,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Individual Nav Item ────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData outlinedIcon;
  final String label;
  final bool selected;
  final int badgeCount;
  final String? photoUrl;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.outlinedIcon,
    required this.label,
    required this.selected,
    this.badgeCount = 0,
    this.photoUrl,
    required this.onTap,
  });

  bool _hasValidPhoto() {
    if (photoUrl == null) return false;
    final v = photoUrl!.trim();
    return v.isNotEmpty &&
        (v.startsWith('http://') || v.startsWith('https://'));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: selected
            ? BoxDecoration(
                color: colors.brandPrimary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Icon / Photo
                if (_hasValidPhoto())
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: NetworkImage(photoUrl!),
                        fit: BoxFit.cover,
                      ),
                      border: Border.all(
                        color: selected
                            ? colors.brandPrimary
                            : colors.borderSoft,
                        width: selected ? 2 : 1,
                      ),
                    ),
                  )
                else
                  Icon(
                    selected ? icon : outlinedIcon,
                    color: selected
                        ? colors.brandPrimary
                        : colors.iconPrimary,
                    size: 24,
                  ),

                // Badge
                if (badgeCount > 0)
                  Positioned(
                    right: -10,
                    top: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.error,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colors.surface,
                          width: 1.5,
                        ),
                      ),
                      constraints: const BoxConstraints(minWidth: 18),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? colors.brandPrimary
                    : colors.textSecondary,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
