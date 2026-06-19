import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/config/routes/route_names.dart';
import 'package:pfb/core/routing/app_router.dart';
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
  bool _isAdmin = false;
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

    if (_isAdmin && !isPreviewMode && index == 3) {
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
                                    'Preview Mode (User View)',
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
                      Expanded(
                        child: IndexedStack(
                          index: _currentIndex,
                          children: _screens,
                        ),
                      ),
                    ],
                  ),
                  bottomNavigationBar: Container(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      boxShadow: [
                        BoxShadow(
                          color: colors.shadow,
                          blurRadius: 18,
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
                        currentIndex: _currentIndex,
                        type: BottomNavigationBarType.fixed,
                        backgroundColor: colors.surface,
                        selectedItemColor: colors.brandPrimary,
                        unselectedItemColor: colors.textSecondary,
                        selectedLabelStyle: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                        unselectedLabelStyle: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                        elevation: 0,
                        onTap: (index) => _handleTabTap(index, isPreviewMode),
                        items: [
                          const BottomNavigationBarItem(
                            icon: Icon(Icons.home_rounded),
                            label: 'Home',
                          ),
                          BottomNavigationBarItem(
                            icon: _BadgeIcon(
                              icon: Icons.shopping_cart_rounded,
                              count: cartCount,
                            ),
                            label: 'Cart',
                          ),
                          const BottomNavigationBarItem(
                            icon: Icon(Icons.receipt_long_rounded),
                            label: 'Orders',
                          ),
                          BottomNavigationBarItem(
                            icon: _BadgeIcon(
                              icon: _isAdmin && !isPreviewMode
                                  ? Icons.admin_panel_settings_rounded
                                  : Icons.person_rounded,
                              count: favCount,
                              photoUrl: (_isAdmin && !isPreviewMode)
                                  ? null
                                  : photoUrl,
                            ),
                            label: _isAdmin && !isPreviewMode
                                ? 'Admin'
                                : 'Profile',
                          ),
                        ],
                      ),
                    ),
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

class _BadgeIcon extends StatelessWidget {
  final IconData icon;
  final int count;
  final String? photoUrl;

  const _BadgeIcon({
    required this.icon,
    required this.count,
    this.photoUrl,
  });

  bool _hasValidImage(String? url) {
    if (url == null) return false;
    final value = url.trim();
    return value.isNotEmpty &&
        (value.startsWith('http://') || value.startsWith('https://'));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final Widget mainContent = _hasValidImage(photoUrl)
        ? Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: NetworkImage(photoUrl!.trim()),
                fit: BoxFit.cover,
              ),
              border: Border.all(
                color: colors.borderSoft,
                width: 1,
              ),
            ),
          )
        : Icon(
            icon,
            color: colors.iconPrimary,
          );

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(2),
          child: mainContent,
        ),
        if (count > 0)
          Positioned(
            right: -8,
            top: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: colors.error,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colors.surface,
                  width: 1.2,
                ),
              ),
              constraints: const BoxConstraints(minWidth: 18),
              child: Text(
                count > 99 ? '99+' : '$count',
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
    );
  }
}
