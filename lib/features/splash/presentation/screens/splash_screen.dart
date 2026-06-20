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
  bool _booting   = false;
  String? _errorText;

  late final AnimationController _introController;
  late final AnimationController _pulseController;
  late final AnimationController _shimmerController;

  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _textSlideAnimation;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1000),
    );

    _pulseController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 2000),
    );

    _shimmerController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 2500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _introController,
      curve:  Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve:  Curves.easeOutBack,
      ),
    );

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end:   Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve:  Curves.easeOutCubic,
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve:  Curves.easeInOut,
      ),
    );

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _shimmerController,
        curve:  Curves.easeInOut,
      ),
    );

    _introController.forward();
    _pulseController.repeat(reverse: true);
    _shimmerController.repeat();
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
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.scaffold,
      body: Container(
        width:  double.infinity,
        height: double.infinity,
        // ── Background gradient matches Phlakes brand ──────────────
        decoration: BoxDecoration(
          gradient: isDark
              // Dark: deep black with subtle gold warmth at bottom
              ? const LinearGradient(
                  colors: [
                    Color(0xFF0B0B0B),
                    Color(0xFF121008),  // very subtle gold tint
                  ],
                  begin: Alignment.topCenter,
                  end:   Alignment.bottomCenter,
                )
              // Light: premium clean white, warm at bottom
              : const LinearGradient(
                  colors: [
                    Color(0xFFFFFFFF),
                    Color(0xFFF8F5EE),  // warm ivory bottom
                  ],
                  begin: Alignment.topCenter,
                  end:   Alignment.bottomCenter,
                ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child:   ScaleTransition(
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
        // ── Animated Logo ────────────────────────────────────────────
        ScaleTransition(
          scale: _pulseAnimation,
          child: _PhlakesLogoWidget(
            colors:           colors,
            isDark:           isDark,
            shimmerAnimation: _shimmerAnimation,
          ),
        ),

        const SizedBox(height: 32),

        // ── Brand Name ───────────────────────────────────────────────
        SlideTransition(
          position: _textSlideAnimation,
          child: _buildBrandText(colors, isDark),
        ),

        const SizedBox(height: 40),

        // ── Gold loading indicator ───────────────────────────────────
        TweenAnimationBuilder<double>(
          tween:    Tween<double>(begin: 0.4, end: 1.0),
          duration: const Duration(milliseconds: 900),
          curve:    Curves.easeInOut,
          builder:  (context, value, child) => Opacity(
            opacity: value,
            child:   child,
          ),
          child: SizedBox(
            width:  30,
            height: 30,
            child: CircularProgressIndicator(
              color:           colors.brandPrimary,
              strokeWidth:     2.5,
              backgroundColor: colors.brandPrimary.withOpacity(0.15),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── Loading label ────────────────────────────────────────────
        Text(
          'Loading your experience...',
          style: GoogleFonts.poppins(
            color:    colors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildBrandText(AppThemeColors colors, bool isDark) {
    return Column(
      children: [
        // ── "PHLAKES" in gold — mirrors store signage ──────────────
        Text(
          'PHLAKES',
          style: GoogleFonts.montserrat(
            color:       colors.brandPrimary,   // metallic gold
            fontSize:    34,
            fontWeight:  FontWeight.w900,
            letterSpacing: 5,
          ),
        ),

        const SizedBox(height: 2),

        // ── "FABRICS" in charcoal/white ────────────────────────────
        Text(
          'FABRICS',
          style: GoogleFonts.montserrat(
            color: isDark ? Colors.white : AppPalette.secondary,
            fontSize:    16,
            fontWeight:  FontWeight.w600,
            letterSpacing: 8,
          ),
        ),

        const SizedBox(height: 12),

        // ── Gold divider line ──────────────────────────────────────
        Container(
          width:  60,
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

        const SizedBox(height: 10),

        // ── Tagline ────────────────────────────────────────────────
        Text(
          'Premium Fabrics. Unmatched Quality.',
          style: GoogleFonts.poppins(
            color:     colors.textSecondary,
            fontSize:  12.5,
            fontStyle: FontStyle.italic,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorContent(AppThemeColors colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Error icon with gold-tinted container ──────────────────
        Container(
          width:  110,
          height: 110,
          decoration: BoxDecoration(
            color:  colors.brandPrimary.withOpacity(0.08),
            shape:  BoxShape.circle,
            border: Border.all(
              color: colors.brandPrimary.withOpacity(0.25),
              width: 2,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.wifi_off_rounded,
              color: colors.brandPrimary,
              size:  44,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Unable to load Phlakes Fabrics',
          style: GoogleFonts.poppins(
            color:      colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize:   20,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          _errorText!,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color:  colors.textSecondary,
            fontSize: 12.5,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 28),
        // ── Retry button — Gold CTA ────────────────────────────────
        SizedBox(
          width:  180,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _retry,
            icon:  const Icon(Icons.refresh_rounded),
            label: Text(
              'Retry',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.brandPrimary,
              foregroundColor: AppPalette.secondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Phlakes Logo Widget — Black circle + Gold P emblem
// Mirrors the actual Phlakes Fabrics app icon
// ─────────────────────────────────────────────────────────────────────────────

class _PhlakesLogoWidget extends StatelessWidget {
  final AppThemeColors colors;
  final bool isDark;
  final Animation<double> shimmerAnimation;

  const _PhlakesLogoWidget({
    required this.colors,
    required this.isDark,
    required this.shimmerAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // ── Outer glow ring — gold ───────────────────────────────────
        Container(
          width:  150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.brandPrimary.withOpacity(isDark ? 0.06 : 0.04),
            border: Border.all(
              color: colors.brandPrimary.withOpacity(0.20),
              width: 1.5,
            ),
          ),
        ),

        // ── Middle ring — dotted gold effect ────────────────────────
        Container(
          width:  120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.brandPrimary.withOpacity(0.06),
            border: Border.all(
              color: colors.brandPrimary.withOpacity(0.30),
              width: 1,
            ),
          ),
        ),

        // ── Inner logo circle — deep black background ────────────────
        Container(
          width:  90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Deep black (matches the actual Phlakes logo bg)
            gradient: const RadialGradient(
              colors: [
                Color(0xFF2A2A2A),
                Color(0xFF0D0D0D),
              ],
              center: Alignment.topLeft,
              radius: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color:      AppPalette.primary.withOpacity(
                  isDark ? 0.45 : 0.28,
                ),
                blurRadius:   24,
                spreadRadius: 3,
                offset:       const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: AnimatedBuilder(
              animation: shimmerAnimation,
              builder:   (context, child) {
                return ShaderMask(
                  blendMode:    BlendMode.srcIn,
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      colors: [
                        AppPalette.primaryDark,
                        AppPalette.premiumGold,
                        AppPalette.primaryLight,
                        AppPalette.primary,
                        AppPalette.primaryDark,
                      ],
                      stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                      begin: Alignment(shimmerAnimation.value - 1, 0),
                      end:   Alignment(shimmerAnimation.value, 0),
                    ).createShader(bounds);
                  },
                  child: child!,
                );
              },
              // "PF" styled to mirror the Phlakes logo emblem
              child: Text(
                'PF',
                style: GoogleFonts.montserrat(
                  color:      Colors.white, // overridden by ShaderMask
                  fontSize:   28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
            ),
          ),
        ),

        // ── Small gold dot accent — top right ───────────────────────
        Positioned(
          top:   20,
          right: 20,
          child: Container(
            width:  8,
            height: 8,
            decoration: BoxDecoration(
              color: colors.brandPrimary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color:      colors.brandPrimary.withOpacity(0.60),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
