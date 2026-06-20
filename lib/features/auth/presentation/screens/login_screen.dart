import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/config/routes/route_names.dart';
import 'package:pfb/core/routing/app_router.dart';
import 'package:pfb/core/theme/app_theme.dart';
import 'package:pfb/features/cart/presentation/screens/cart_screen.dart';
import 'package:pfb/features/orders/presentation/screens/order_screen.dart';
import 'package:pfb/features/profile/presentation/screens/profile_screen.dart';
import 'package:pfb/features/rider/presentation/screens/rider_home_screen.dart';
import 'package:pfb/services/firebase_auth_service.dart';
import 'package:pfb/services/firebase_service.dart';

class LoginScreen extends StatefulWidget {
  final String? redirectTo;

  const LoginScreen({super.key, this.redirectTo});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuthService _authService    = FirebaseAuthService();
  final FirebaseService     _firebaseService = FirebaseService();

  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _loading       = false;
  bool _googleLoading = false;
  bool _obscurePassword = true;

  late final AnimationController _animController;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve:  Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end:   Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve:  Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _goAfterLogin() async {
    if (!mounted) return;
    try {
      await _firebaseService.ensureUserProfile();
      await _firebaseService.syncLocalCartToFirestore();
    } catch (_) {}

    bool isAdmin = false;
    try {
      isAdmin = await _firebaseService.isAdmin();
    } catch (_) {}

    if (!mounted) return;

    if (isAdmin) {
      await AppRouter.clearAndGo(context, RouteNames.admin);
      return;
    }

    switch (widget.redirectTo) {
      case RouteNames.redirectCart:
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const CartScreen()),
          (r) => false,
        );
        return;
      case RouteNames.redirectOrders:
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => OrderScreen()),
          (r) => false,
        );
        return;
      case RouteNames.redirectProfile:
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
          (r) => false,
        );
        return;
      case RouteNames.redirectRider:
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const RiderHomeScreen()),
          (r) => false,
        );
        return;
      default:
        await AppRouter.clearAndGo(context, RouteNames.mainShell);
        return;
    }
  }

  Future<void> _login() async {
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnack('Email and password are required');
      return;
    }

    setState(() => _loading = true);
    try {
      final user = await _authService.signInWithEmailPassword(
        email:    email,
        password: password,
      );
      if (user == null) throw AuthFailure('Login failed. Please try again.');
      if (!mounted) return;
      await _goAfterLogin();
    } catch (e) {
      if (!mounted) return;
      _showSnack('$e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _googleLoading = true);
    try {
      final user = await _authService.signInWithGoogle();
      if (user == null) throw AuthFailure('Google sign-in did not complete.');
      if (!mounted) return;
      await _goAfterLogin();
    } catch (e) {
      if (!mounted) return;
      _showSnack('$e', isError: true);
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _continueAsGuest() async {
    await AppRouter.clearAndGo(context, RouteNames.mainShell);
  }

  Future<void> _goToSignup() async {
    await AppRouter.clearAndGo(context, RouteNames.signup);
  }

  void _showSnack(String message, {bool isError = false}) {
    final colors = AppTheme.colorsOf(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
        ),
        backgroundColor: isError
            ? colors.error
            : AppPalette.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          // Light: premium white → warm ivory
          // Dark:  deep black  → subtle dark charcoal
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF0B0B0B),
                    const Color(0xFF161410),
                    const Color(0xFF0B0B0B),
                  ]
                : [
                    const Color(0xFFFFFFFF),
                    const Color(0xFFF8F5EE),
                    const Color(0xFFFFFFFF),
                  ],
            begin: Alignment.topCenter,
            end:   Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // ── Ambient gold glow circles ──────────────────────────────
            Positioned(
              top:  -100,
              left: -80,
              child: _GlowCircle(
                size:    300,
                color:   colors.brandPrimary,
                opacity: isDark ? 0.10 : 0.07,
              ),
            ),
            Positioned(
              top:   200,
              right: -50,
              child: _GlowCircle(
                size:    200,
                color:   colors.brandPrimary,
                opacity: isDark ? 0.07 : 0.05,
              ),
            ),
            Positioned(
              bottom: -80,
              left:   -30,
              child: _GlowCircle(
                size:    240,
                color:   AppPalette.secondary,
                opacity: isDark ? 0.25 : 0.06,
              ),
            ),

            // ── Main content ───────────────────────────────────────────
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 40,
                      ),
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child:   SlideTransition(
                          position: _slideAnim,
                          child: Column(
                            children: [
                              const SizedBox(height: 52),

                              // ── Brand Logo ─────────────────────────────
                              _PhlakesBrandLogo(
                                colors: colors,
                                isDark: isDark,
                              ),

                              const SizedBox(height: 30),

                              // ── Login Card ─────────────────────────────
                              _buildLoginCard(colors, isDark),

                              const SizedBox(height: 24),

                              Text(
                                'By continuing, you agree to our Terms & Privacy Policy.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color:    colors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),

                              const SizedBox(height: 10),

                              TextButton(
                                onPressed: _continueAsGuest,
                                style: TextButton.styleFrom(
                                  foregroundColor: colors.textSecondary,
                                ),
                                child: Text(
                                  'Continue as Guest',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize:   13.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginCard(AppThemeColors colors, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
      decoration: BoxDecoration(
        color:        colors.card.withOpacity(isDark ? 0.85 : 0.90),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          // Subtle gold border on the card
          color: colors.brandPrimary.withOpacity(0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color:      isDark
                ? Colors.black.withOpacity(0.40)
                : Colors.black.withOpacity(0.06),
            blurRadius: 28,
            offset:     const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card header ─────────────────────────────────────────
          Text(
            'Welcome back',
            style: GoogleFonts.poppins(
              color:      colors.textPrimary,
              fontSize:   22,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.redirectTo == null
                ? 'Sign in to your Phlakes Fabrics account.'
                : 'Sign in to continue where you stopped.',
            style: GoogleFonts.poppins(
              color:    colors.textSecondary,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 22),

          // ── Email field ─────────────────────────────────────────
          _LuxuryField(
            controller:   _emailCtrl,
            hint:         'Email address',
            icon:         Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 14),

          // ── Password field ──────────────────────────────────────
          _LuxuryField(
            controller:  _passwordCtrl,
            hint:        'Password',
            icon:        Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            suffix: IconButton(
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: colors.textSecondary,
                size:  22,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Sign in button — GOLD ───────────────────────────────
          _GoldButton(
            label:      'Sign in',
            isLoading:  _loading,
            onPressed:  _loading ? null : _login,
          ),

          const SizedBox(height: 20),

          // ── Divider ─────────────────────────────────────────────
          _GoldDivider(colors: colors),

          const SizedBox(height: 20),

          // ── Google sign in ──────────────────────────────────────
          _GoogleButton(
            isLoading: _googleLoading,
            onPressed: _googleLoading ? null : _loginWithGoogle,
            colors:    colors,
          ),

          const SizedBox(height: 24),

          // ── Sign up link ────────────────────────────────────────
          Center(
            child: Column(
              children: [
                Text(
                  'New to Phlakes Fabrics?',
                  style: GoogleFonts.poppins(
                    color:    colors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _goToSignup,
                  child: Text(
                    'Create an account',
                    style: GoogleFonts.poppins(
                      color:      colors.brandPrimary,
                      fontSize:   16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Phlakes Brand Logo — Black circle + shimmering PF + PHLAKES FABRICS text
// ─────────────────────────────────────────────────────────────────────────────

class _PhlakesBrandLogo extends StatelessWidget {
  final AppThemeColors colors;
  final bool isDark;

  const _PhlakesBrandLogo({
    required this.colors,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Logo emblem ─────────────────────────────────────────────
        Container(
          width:  80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Deep black background — matches actual Phlakes logo
            gradient: const RadialGradient(
              colors: [
                Color(0xFF2E2E2E),
                Color(0xFF0D0D0D),
              ],
              center: Alignment.topLeft,
              radius: 1.5,
            ),
            border: Border.all(
              color: AppPalette.primary.withOpacity(0.50),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color:      AppPalette.primary.withOpacity(
                  isDark ? 0.35 : 0.20,
                ),
                blurRadius:   20,
                spreadRadius: 2,
                offset:       const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: ShaderMask(
              blendMode:    BlendMode.srcIn,
              shaderCallback: (bounds) {
                return const LinearGradient(
                  colors: [
                    AppPalette.primaryDark,
                    AppPalette.premiumGold,
                    AppPalette.primaryLight,
                  ],
                  begin: Alignment.topLeft,
                  end:   Alignment.bottomRight,
                ).createShader(bounds);
              },
              child: Text(
                'PF',
                style: GoogleFonts.montserrat(
                  color:      Colors.white,
                  fontSize:   28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 18),

        // ── "PHLAKES" — brand gold ───────────────────────────────────
        Text(
          'PHLAKES',
          style: GoogleFonts.montserrat(
            color:       colors.brandPrimary,
            fontSize:    28,
            fontWeight:  FontWeight.w900,
            letterSpacing: 4,
          ),
        ),

        const SizedBox(height: 2),

        // ── "FABRICS" — secondary ────────────────────────────────────
        Text(
          'FABRICS',
          style: GoogleFonts.montserrat(
            color: isDark ? Colors.white70 : AppPalette.secondary,
            fontSize:    13,
            fontWeight:  FontWeight.w600,
            letterSpacing: 6,
          ),
        ),

        const SizedBox(height: 10),

        // ── Gold accent line ─────────────────────────────────────────
        Container(
          width:  50,
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                colors.brandPrimary,
                Colors.transparent,
              ],
            ),
            borderRadius: BorderRadius.circular(1),
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Premium Fabrics. Unmatched Quality.',
          style: GoogleFonts.poppins(
            color:     colors.textSecondary,
            fontSize:  12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Luxury Input Field — clean with gold focus ring
// ─────────────────────────────────────────────────────────────────────────────

class _LuxuryField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffix;
  final TextInputType? keyboardType;

  const _LuxuryField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText  = false,
    this.suffix,
    this.keyboardType,
  });

  @override
  State<_LuxuryField> createState() => _LuxuryFieldState();
}

class _LuxuryFieldState extends State<_LuxuryField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return Focus(
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color:        colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _focused
                ? colors.brandPrimary          // gold focus ring
                : colors.border,
            width: _focused ? 1.8 : 1.0,
          ),
          boxShadow: _focused
              ? [
                  BoxShadow(
                    color:      colors.brandPrimary.withOpacity(0.12),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: TextField(
          controller:   widget.controller,
          obscureText:  widget.obscureText,
          keyboardType: widget.keyboardType,
          cursorColor:  colors.brandPrimary,
          style: GoogleFonts.poppins(
            color:    colors.textPrimary,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            filled:    false,
            hintText:  widget.hint,
            hintStyle: GoogleFonts.poppins(
              color:    colors.textSecondary,
              fontSize: 14,
            ),
            prefixIcon: Icon(
              widget.icon,
              color: _focused
                  ? colors.brandPrimary       // gold icon when focused
                  : colors.textSecondary,
              size: 22,
            ),
            suffixIcon:          widget.suffix,
            border:              InputBorder.none,
            enabledBorder:       InputBorder.none,
            focusedBorder:       InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical:   18,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gold CTA Button
// ─────────────────────────────────────────────────────────────────────────────

class _GoldButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _GoldButton({
    required this.label,
    required this.isLoading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:  double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          // Gold background + black text — luxury CTA
          backgroundColor: AppPalette.primary,
          foregroundColor: AppPalette.secondary,
          elevation:       0,
          shadowColor:     AppPalette.primary.withOpacity(0.30),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width:  22,
                height: 22,
                child:  CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color:       AppPalette.secondary,
                ),
              )
            : Text(
                label,
                style: GoogleFonts.poppins(
                  fontWeight:   FontWeight.w700,
                  fontSize:     16,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Google Sign-In Button
// ─────────────────────────────────────────────────────────────────────────────

class _GoogleButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final AppThemeColors colors;

  const _GoogleButton({
    required this.isLoading,
    required this.onPressed,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:  double.infinity,
      height: 58,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: colors.surface.withOpacity(0.5),
          side: BorderSide(
            color: colors.brandPrimary.withOpacity(0.35),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width:  22,
                height: 22,
                child:  CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color:       colors.brandPrimary,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network(
                    'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                    width:  22,
                    height: 22,
                    errorBuilder: (_, __, ___) => Text(
                      'G',
                      style: GoogleFonts.poppins(
                        color:      colors.textPrimary,
                        fontSize:   20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Continue with Google',
                    style: GoogleFonts.poppins(
                      color:      colors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize:   15,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gold Divider
// ─────────────────────────────────────────────────────────────────────────────

class _GoldDivider extends StatelessWidget {
  final AppThemeColors colors;

  const _GoldDivider({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, colors.border],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: GoogleFonts.poppins(
              color:    colors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.border, Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ambient Glow Circle
// ─────────────────────────────────────────────────────────────────────────────

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _GlowCircle({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(opacity),
        boxShadow: [
          BoxShadow(
            color:      color.withOpacity(opacity * 0.7),
            blurRadius: size * 0.4,
            spreadRadius: size * 0.05,
          ),
        ],
      ),
    );
  }
}
