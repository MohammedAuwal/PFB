import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/config/routes/route_names.dart';
import 'package:pfb/core/routing/app_router.dart';
import 'package:pfb/core/theme/app_theme.dart';
import 'package:pfb/services/firebase_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  bool _navigated = false;
  bool _booting = false;
  String? _errorText;

  late final AnimationController _introController;
  late final AnimationController _pulseController;

  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _textSlideAnimation;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutBack),
    );

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _introController.forward();
    _pulseController.repeat(reverse: true);
    _start();
  }

  Future<void> _start() async {
    if (_booting) return;
    _booting = true;

    try {
      await Future.any([
        _bootstrap(),
        Future.delayed(const Duration(seconds: 12), () {
          throw Exception(
            'App startup timed out. Please check your internet and try again.',
          );
        }),
      ]);
    } catch (e) {
      if (!mounted) return;

      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('permission-denied') ||
          errorStr.contains('permission denied')) {
        await _safeNavigate(RouteNames.mainShell);
        return;
      }

      setState(() => _errorText = e.toString());
    } finally {
      _booting = false;
    }
  }

  Future<void> _safeNavigate(String routeName) async {
    if (!mounted || _navigated) return;
    _navigated = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await AppRouter.clearAndGo(context, routeName);
    });
  }

  Future<void> _bootstrap() async {
    final firebaseService = FirebaseService();

    unawaited(firebaseService.seedDefaultAppSettingsSafely());
    unawaited(firebaseService.seedDefaultCategoriesIfMissingSafely());

    final user = firebaseService.currentUser;

    if (user != null) {
      unawaited(firebaseService.ensureUserProfileSafely());
      unawaited(firebaseService.syncLocalCartToFirestoreSafely());

      bool isAdmin = false;
      try {
        isAdmin = await firebaseService
            .isAdmin()
            .timeout(const Duration(seconds: 6));
      } catch (_) {
        isAdmin = false;
      }

      if (isAdmin) {
        await _safeNavigate(RouteNames.admin);
        return;
      }
    }

    await _safeNavigate(RouteNames.mainShell);
  }

  Future<void> _retry() async {
    setState(() {
      _errorText = null;
      _navigated = false;
    });
    await _start();
  }

  @override
  void dispose() {
    _introController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.scaffold,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // ── Background: light = silver-white paper, dark = deep black
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  colors: [
                    Color(0xFF111111),
                    Color(0xFF1C1010), // very subtle red tint at bottom
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : const LinearGradient(
                  colors: [
                    Color(0xFFF8F6F3), // logo paper white
                    Color(0xFFEFECE8), // slightly warmer at bottom
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: _errorText == null
                      ? _buildLoadingContent(colors, isDark)
                      : _buildErrorContent(colors),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingContent(AppThemeColors colors, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Animated Logo ───────────────────────────────────────────
        ScaleTransition(
          scale: _pulseAnimation,
          child: _ITEXLogo(colors: colors, isDark: isDark),
        ),

        const SizedBox(height: 28),

        // ── App Name ────────────────────────────────────────────────
        SlideTransition(
          position: _textSlideAnimation,
          child: Column(
            children: [
              // "ISMAIL" in black, "TEX" in red — mirrors the actual logo
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'ISMAIL',
                      style: GoogleFonts.montserrat(
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF1A1A1A),
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    TextSpan(
                      text: 'TEX',
                      style: GoogleFonts.montserrat(
                        color: colors.brandPrimary,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              // Divider line — mirrors the red line under tagline in logo
              Container(
                width: 48,
                height: 2.5,
                decoration: BoxDecoration(
                  color: colors.brandPrimary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              // Tagline from logo
              Text(
                'We weave a better tomorrow.',
                style: GoogleFonts.poppins(
                  color: isDark
                      ? colors.textSecondary
                      : const Color(0xFF4A4A4A),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'A quality you can trust.',
                style: GoogleFonts.poppins(
                  color: colors.brandPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 36),

        // ── Loading indicator ───────────────────────────────────────
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.5, end: 1),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: child,
            );
          },
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              color: colors.brandPrimary,
              strokeWidth: 2.8,
              backgroundColor: colors.brandPrimary.withOpacity(0.15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorContent(AppThemeColors colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            color: colors.error.withOpacity(0.08),
            shape: BoxShape.circle,
            border: Border.all(
              color: colors.error.withOpacity(0.25),
              width: 2,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.wifi_off_rounded,
              color: colors.error,
              size: 44,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Unable to load IsmailTex',
          style: GoogleFonts.poppins(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          _errorText!,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: colors.textSecondary,
            fontSize: 12.5,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _retry,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(
            'Retry',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

// ── ITEX Logo Widget ───────────────────────────────────────────────────────────

class _ITEXLogo extends StatelessWidget {
  final AppThemeColors colors;
  final bool isDark;

  const _ITEXLogo({required this.colors, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow ring
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.brandPrimary.withOpacity(isDark ? 0.08 : 0.06),
            border: Border.all(
              color: colors.brandPrimary.withOpacity(0.20),
              width: 1.5,
            ),
          ),
        ),
        // Inner logo circle — red background mirrors brand
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppPalette.primary,       // #CC2222
                AppPalette.primaryDark,   // #A61818
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppPalette.primary.withOpacity(isDark ? 0.50 : 0.35),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // "iT" styled like the logo icon
                Text(
                  'iT',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                // Small dot above the "i" — mirrors the dot in the logo icon
                Positioned(
                  top: 14,
                  right: 18,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Brand black swoosh bottom-left — subtle, mirrors logo swoosh
        Positioned(
          bottom: 10,
          left: 10,
          child: Container(
            width: 28,
            height: 5,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.15)
                  : const Color(0xFF1A1A1A).withOpacity(0.15),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ],
    );
  }
}
