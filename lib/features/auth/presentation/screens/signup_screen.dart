import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/config/routes/route_names.dart';
import 'package:pfb/core/routing/app_router.dart';
import 'package:pfb/core/theme/app_theme.dart';
import 'package:pfb/services/firebase_auth_service.dart';
import 'package:pfb/services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuthService _authService     = FirebaseAuthService();
  final FirebaseService     _firebaseService = FirebaseService();

  final _nameCtrl            = TextEditingController();
  final _emailCtrl           = TextEditingController();
  final _passwordCtrl        = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _loading               = false;
  bool _googleLoading         = false;
  bool _obscurePassword       = true;
  bool _obscureConfirmPassword = true;

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
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _goAfterSignup() async {
    try {
      await _firebaseService.ensureUserProfile();
      await _firebaseService.syncLocalCartToFirestore();
    } catch (_) {}

    if (!mounted) return;

    final isAdmin = await _firebaseService.isAdmin();
    if (!mounted) return;

    if (isAdmin) {
      await AppRouter.clearAndGo(context, RouteNames.admin);
      return;
    }
    await AppRouter.clearAndGo(context, RouteNames.mainShell);
  }

  Future<void> _signup() async {
    final name            = _nameCtrl.text.trim();
    final email           = _emailCtrl.text.trim();
    final password        = _passwordCtrl.text.trim();
    final confirmPassword = _confirmPasswordCtrl.text.trim();

    if (name.isEmpty || email.isEmpty ||
        password.isEmpty || confirmPassword.isEmpty) {
      _showSnack('All fields are required');
      return;
    }
    if (password != confirmPassword) {
      _showSnack('Passwords do not match');
      return;
    }
    if (password.length < 6) {
      _showSnack('Password must be at least 6 characters');
      return;
    }

    setState(() => _loading = true);
    try {
      final user = await _authService.signUpWithEmailPassword(
        email:    email,
        password: password,
      );
      if (user == null) {
        throw AuthFailure('Account creation failed. Please try again.');
      }
      await FirebaseAuth.instance.currentUser
          ?.updateProfile(displayName: name);
      if (!mounted) return;
      await _goAfterSignup();
    } catch (e) {
      if (!mounted) return;
      _showSnack('$e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signupWithGoogle() async {
    setState(() => _googleLoading = true);
    try {
      final user = await _authService.signInWithGoogle();
      if (user == null) throw AuthFailure('Google sign-up did not complete.');
      if (!mounted) return;
      await _goAfterSignup();
    } catch (e) {
      if (!mounted) return;
      _showSnack('$e', isError: true);
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _goToLogin() async {
    await AppRouter.clearAndGo(context, RouteNames.login);
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

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
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
            // ── Ambient glow circles ───────────────────────────────────
            Positioned(
              top:  -100,
              right: -60,
              child: _GlowCircle(
                size:    280,
                color:   colors.brandPrimary,
                opacity: isDark ? 0.09 : 0.06,
              ),
            ),
            Positioned(
              bottom: -80,
              left:   -40,
              child: _GlowCircle(
                size:    220,
                color:   AppPalette.secondary,
                opacity: isDark ? 0.22 : 0.05,
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
                              const SizedBox(height: 40),

                              // ── Brand Logo ─────────────────────────────
                              _PhlakesBrandLogo(
                                colors: colors,
                                isDark: isDark,
                                compact: true,
                              ),

                              const SizedBox(height: 28),

                              // ── Signup Card ────────────────────────────
                              _buildSignupCard(colors, isDark),

                              const SizedBox(height: 24),

                              Text(
                                'By continuing, you agree to our Terms & Privacy Policy.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color:    colors.textSecondary,
                                  fontSize: 12,
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

  Widget _buildSignupCard(AppThemeColors colors, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
      decoration: BoxDecoration(
        color:        colors.card.withOpacity(isDark ? 0.85 : 0.90),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
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
          Text(
            'Create account',
            style: GoogleFonts.poppins(
              color:      colors.textPrimary,
              fontSize:   22,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Join Phlakes Fabrics and discover premium quality.',
            style: GoogleFonts.poppins(
              color:    colors.textSecondary,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 22),

          _LuxuryField(
            controller: _nameCtrl,
            hint:       'Full name',
            icon:       Icons.person_outline_rounded,
          ),
          const SizedBox(height: 14),
          _LuxuryField(
            controller:   _emailCtrl,
            hint:         'Email address',
            icon:         Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
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
          const SizedBox(height: 14),
          _LuxuryField(
            controller:  _confirmPasswordCtrl,
            hint:        'Confirm password',
            icon:        Icons.lock_person_outlined,
            obscureText: _obscureConfirmPassword,
            suffix: IconButton(
              onPressed: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: colors.textSecondary,
                size:  22,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Gold CTA button ─────────────────────────────────────
          _GoldButton(
            label:     'Create account',
            isLoading: _loading,
            onPressed: _loading ? null : _signup,
          ),

          const SizedBox(height: 20),

          _GoldDivider(colors: colors),

          const SizedBox(height: 20),

          _GoogleButton(
            isLoading: _googleLoading,
            onPressed: _googleLoading ? null : _signupWithGoogle,
            colors:    colors,
          ),

          const SizedBox(height: 24),

          Center(
            child: Column(
              children: [
                Text(
                  'Already have an account?',
                  style: GoogleFonts.poppins(
                    color:    colors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _goToLogin,
                  child: Text(
                    'Sign in',
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
// Shared Phlakes Brand Logo (compact variant for signup)
// ─────────────────────────────────────────────────────────────────────────────

class _PhlakesBrandLogo extends StatelessWidget {
  final AppThemeColors colors;
  final bool isDark;
  final bool compact;

  const _PhlakesBrandLogo({
    required this.colors,
    required this.isDark,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final logoSize = compact ? 68.0 : 80.0;
    final titleSize = compact ? 24.0 : 28.0;

    return Column(
      children: [
        Container(
          width:  logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
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
                  isDark ? 0.30 : 0.18,
                ),
                blurRadius:   18,
                spreadRadius: 2,
                offset:       const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: ShaderMask(
              blendMode: BlendMode.srcIn,
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
                  fontSize:   compact ? 24.0 : 28.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        Text(
          'PHLAKES',
          style: GoogleFonts.montserrat(
            color:       colors.brandPrimary,
            fontSize:    titleSize,
            fontWeight:  FontWeight.w900,
            letterSpacing: 4,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          'FABRICS',
          style: GoogleFonts.montserrat(
            color: isDark ? Colors.white70 : AppPalette.secondary,
            fontSize:    compact ? 11.0 : 13.0,
            fontWeight:  FontWeight.w600,
            letterSpacing: 5,
          ),
        ),

        const SizedBox(height: 8),

        Container(
          width:  44,
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
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets (same as login_screen.dart — keep in sync)
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
      onFocusChange: (f) => setState(() => _focused = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color:        colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _focused ? colors.brandPrimary : colors.border,
            width: _focused ? 1.8 : 1.0,
          ),
          boxShadow: _focused
              ? [
                  BoxShadow(
                    color:      colors.brandPrimary.withOpacity(0.12),
                    blurRadius: 8,
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
              color: _focused ? colors.brandPrimary : colors.textSecondary,
              size:  22,
            ),
            suffixIcon:     widget.suffix,
            border:         InputBorder.none,
            enabledBorder:  InputBorder.none,
            focusedBorder:  InputBorder.none,
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
          backgroundColor: AppPalette.primary,
          foregroundColor: AppPalette.secondary,
          elevation:       0,
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
              color: colors.textSecondary,
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
            color:      color.withOpacity(opacity * 0.6),
            blurRadius: size * 0.4,
            spreadRadius: size * 0.04,
          ),
        ],
      ),
    );
  }
}
