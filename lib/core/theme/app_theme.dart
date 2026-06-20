// lib/core/theme/app_theme.dart
import 'dart:ui';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Phlakes Fabrics Brand Analysis from Logo + Store Reference Images:
//
//  PRIMARY   → Metallic Gold   #D4AF37  (Logo lettering, store signage)
//  PRIMARY DARK → Deep Gold    #C9981A  (Pressed/gradient end)
//  PRIMARY LIGHT → Bright Gold #E6C766  (Hover states, tinted surfaces)
//
//  SECONDARY → Deep Charcoal   #1A1A1A  (Store fascia, logo background)
//  ACCENT    → Rich Gold       #FFD700  (Premium sparingly used)
//
//  Light Mode Background → Premium White  #FAFAFA  (Marble-like, clean)
//  Dark Mode Background  → Deep Black     #0B0B0B  (Store exterior)
//  Dark Mode Surface     → Dark Charcoal  #161616  (Secondary dark bg)
//
//  Brand Feel: Luxury Textile Showroom — Rolex / LV / Mercedes aesthetic
// ─────────────────────────────────────────────────────────────────────────────

class AppPalette {
  AppPalette._();

  // ── Brand Core ─────────────────────────────────────────────────
  /// Primary brand gold — exact metallic gold from Phlakes Fabrics logo & signage
  static const Color primary = Color(0xFFD4AF37);

  /// Primary dark — deeper antique gold for pressed / gradient end
  static const Color primaryDark = Color(0xFFC9981A);

  /// Primary light — brighter champagne gold for hover / tinted surfaces
  static const Color primaryLight = Color(0xFFE6C766);

  /// Premium gold — used very sparingly for ultra-premium highlights
  static const Color premiumGold = Color(0xFFFFD700);

  /// Secondary — deep charcoal black (store fascia + logo background)
  static const Color secondary = Color(0xFF1A1A1A);

  /// Secondary light — slightly lifted charcoal for surfaces
  static const Color secondaryLight = Color(0xFF2A2A2A);

  /// Accent — warm gold-brown for depth and contrast
  static const Color accent = Color(0xFFB8860B);

  // ── Semantic ───────────────────────────────────────────────────
  static const Color success = Color(0xFF22AD5C);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error   = Color(0xFFDC2626);
  static const Color info    = Color(0xFF2563EB);

  // ── Light Mode ─────────────────────────────────────────────────
  /// Premium clean white — like the marble interior of the Phlakes store
  static const Color lightScaffold   = Color(0xFFFAFAFA);
  static const Color lightSurface    = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFF5F5F5);
  static const Color lightCard       = Color(0xFFFFFFFF);

  /// Border uses a warm gold-tinted silver
  static const Color lightBorder     = Color(0xFFE8E0D0);
  static const Color lightBorderSoft = Color(0xFFF0EBE0);

  static const Color lightText       = Color(0xFF111111); // near black, premium
  static const Color lightTextSoft   = Color(0xFF666666); // muted secondary text
  static const Color lightIcon       = Color(0xFF111111);
  static const Color lightShadow     = Color(0x14000000);

  // ── Dark Mode ──────────────────────────────────────────────────
  /// Deep black — matches the Phlakes store exterior night aesthetic
  static const Color darkScaffold    = Color(0xFF0B0B0B);
  static const Color darkSurface     = Color(0xFF1E1E1E);
  static const Color darkSurfaceAlt  = Color(0xFF161616);
  static const Color darkCard        = Color(0xFF1E1E1E);

  /// Borders: very subtle gold tint in dark mode for brand cohesion
  static const Color darkBorder      = Color(0x35D4AF37);
  static const Color darkBorderSoft  = Color(0x1AD4AF37);

  static const Color darkText        = Color(0xFFFFFFFF);
  static const Color darkTextSoft    = Color(0xFFB5B5B5);
  static const Color darkIcon        = Color(0xFFFFFFFF);
  static const Color darkShadow      = Color(0x55000000);

  // ── Tonal Palette (Luxury Fabric Categories) ───────────────────
  /// Champagne — Lace / Chiffon category tint
  static const Color champagne    = Color(0xFFF7E7CE);

  /// Ivory — Cotton / Linen category tint
  static const Color ivory        = Color(0xFFFFFBF0);

  /// Deep Gold — Aso Oke / Ankara category tint
  static const Color deepGold     = Color(0xFFFFF3CD);

  /// Royal Gold — Silk / Velvet category tint
  static const Color royalGold    = Color(0xFFFFF8E1);

  /// Warm Black — Velvet category
  static const Color warmBlack    = Color(0xFF0D0D0D);

  /// Warm Cream — for cream surface cards
  static const Color cream        = Color(0xFFFDF6E3);

  /// Brown — warm accent text
  static const Color brown        = Color(0xFF8B6914);

  /// Dark Brown — deep warm contrast text
  static const Color darkBrown    = Color(0xFF3D2B00);

  /// Muted purple — accent variety (kept minimal for luxury)
  static const Color purple       = Color(0xFF6D28D9);

  // ── Pale tones (light backgrounds for chips/cards) ─────────────
  static const Color palePurple   = Color(0xFFF5F0FF);
  static const Color paleBlue     = Color(0xFFEFF6FF);
  static const Color paleGreen    = Color(0xFFECFDF5);
  static const Color paleOrange   = Color(0xFFFFF7ED);
  static const Color paleRed      = Color(0xFFFFF0F0);

  /// Pale gold — primary tinted light background for cards/chips
  static const Color paleGold     = Color(0xFFFFFBF0);

  // ── Dark-mode tonal backgrounds ────────────────────────────────
  /// Dark gold tint — for highlighted containers in dark mode
  static const Color darkPaleGold   = Color(0xFF1F1A08);
  static const Color darkPaleOrange = Color(0xFF1F1208);
  static const Color darkPaleGreen  = Color(0xFF0A1F14);
  static const Color darkPaleBlue   = Color(0xFF0A1428);
  static const Color darkPalePurple = Color(0xFF160D2E);
  static const Color darkPaleRed    = Color(0xFF2A0A0A);
}

// ─────────────────────────────────────────────────────────────────────────────
// AppThemeColors — ThemeExtension
// ─────────────────────────────────────────────────────────────────────────────

class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color brandPrimary;
  final Color brandSecondary;
  final Color brandAccent;
  final Color premiumGold;
  final Color scaffold;
  final Color surface;
  final Color surfaceAlt;
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final Color iconPrimary;
  final Color border;
  final Color borderSoft;
  final Color shadow;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color cream;
  final Color champagne;
  final Color ivory;
  final Color brown;
  final Color darkBrown;
  final Color purple;
  final Color palePurple;
  final Color paleBlue;
  final Color paleGreen;
  final Color paleOrange;
  final Color paleRed;
  final Color paleGold;

  // Contrast helpers
  final Color iconOnPrimary;
  final Color iconOnSecondary;
  final Color textOnPrimary;
  final Color textOnSecondary;
  final Color iconOnTint;
  final Color iconOnLightTint;
  final Color iconOnDarkTint;
  final Color textOnTint;
  final Color textOnLightTint;
  final Color textOnDarkTint;

  const AppThemeColors({
    required this.brandPrimary,
    required this.brandSecondary,
    required this.brandAccent,
    required this.premiumGold,
    required this.scaffold,
    required this.surface,
    required this.surfaceAlt,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.iconPrimary,
    required this.border,
    required this.borderSoft,
    required this.shadow,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.cream,
    required this.champagne,
    required this.ivory,
    required this.brown,
    required this.darkBrown,
    required this.purple,
    required this.palePurple,
    required this.paleBlue,
    required this.paleGreen,
    required this.paleOrange,
    required this.paleRed,
    required this.paleGold,
    required this.iconOnPrimary,
    required this.iconOnSecondary,
    required this.textOnPrimary,
    required this.textOnSecondary,
    required this.iconOnTint,
    required this.iconOnLightTint,
    required this.iconOnDarkTint,
    required this.textOnTint,
    required this.textOnLightTint,
    required this.textOnDarkTint,
  });

  // ── Light Factory ────────────────────────────────────────────────

  factory AppThemeColors.light() {
    return const AppThemeColors(
      brandPrimary:   AppPalette.primary,
      brandSecondary: AppPalette.secondary,
      brandAccent:    AppPalette.accent,
      premiumGold:    AppPalette.premiumGold,
      scaffold:       AppPalette.lightScaffold,
      surface:        AppPalette.lightSurface,
      surfaceAlt:     AppPalette.lightSurfaceAlt,
      card:           AppPalette.lightCard,
      textPrimary:    AppPalette.lightText,
      textSecondary:  AppPalette.lightTextSoft,
      iconPrimary:    AppPalette.lightIcon,
      border:         AppPalette.lightBorder,
      borderSoft:     AppPalette.lightBorderSoft,
      shadow:         AppPalette.lightShadow,
      success:        AppPalette.success,
      warning:        AppPalette.warning,
      error:          AppPalette.error,
      info:           AppPalette.info,
      cream:          AppPalette.cream,
      champagne:      AppPalette.champagne,
      ivory:          AppPalette.ivory,
      brown:          AppPalette.brown,
      darkBrown:      AppPalette.darkBrown,
      purple:         AppPalette.purple,
      palePurple:     AppPalette.palePurple,
      paleBlue:       AppPalette.paleBlue,
      paleGreen:      AppPalette.paleGreen,
      paleOrange:     AppPalette.paleOrange,
      paleRed:        AppPalette.paleRed,
      paleGold:       AppPalette.paleGold,
      // Gold buttons → black text for contrast (luxury feel)
      iconOnPrimary:   AppPalette.secondary,
      iconOnSecondary: Colors.white,
      textOnPrimary:   AppPalette.secondary,
      textOnSecondary: Colors.white,
      iconOnTint:      AppPalette.secondary,
      iconOnLightTint: AppPalette.primary,
      iconOnDarkTint:  Colors.white,
      textOnTint:      AppPalette.secondary,
      textOnLightTint: AppPalette.primary,
      textOnDarkTint:  Colors.white,
    );
  }

  // ── Dark Factory ─────────────────────────────────────────────────

  factory AppThemeColors.dark() {
    return const AppThemeColors(
      brandPrimary:   AppPalette.primary,      // gold stays gold in dark
      brandSecondary: AppPalette.darkText,
      brandAccent:    AppPalette.premiumGold,   // brighter gold accent in dark
      premiumGold:    AppPalette.premiumGold,
      scaffold:       AppPalette.darkScaffold,
      surface:        AppPalette.darkSurface,
      surfaceAlt:     AppPalette.darkSurfaceAlt,
      card:           AppPalette.darkCard,
      textPrimary:    AppPalette.darkText,
      textSecondary:  AppPalette.darkTextSoft,
      iconPrimary:    AppPalette.darkIcon,
      border:         AppPalette.darkBorder,
      borderSoft:     AppPalette.darkBorderSoft,
      shadow:         AppPalette.darkShadow,
      success:        AppPalette.success,
      warning:        AppPalette.warning,
      error:          AppPalette.error,
      info:           AppPalette.info,
      cream:          AppPalette.darkPaleGold,
      champagne:      AppPalette.darkPaleOrange,
      ivory:          AppPalette.darkPaleGold,
      brown:          AppPalette.champagne,
      darkBrown:      AppPalette.cream,
      purple:         AppPalette.purple,
      palePurple:     AppPalette.darkPalePurple,
      paleBlue:       AppPalette.darkPaleBlue,
      paleGreen:      AppPalette.darkPaleGreen,
      paleOrange:     AppPalette.darkPaleOrange,
      paleRed:        AppPalette.darkPaleRed,
      paleGold:       AppPalette.darkPaleGold,
      // Gold on dark → black text for readability
      iconOnPrimary:   AppPalette.secondary,
      iconOnSecondary: AppPalette.primary,
      textOnPrimary:   AppPalette.secondary,
      textOnSecondary: AppPalette.primary,
      iconOnTint:      AppPalette.secondary,
      iconOnLightTint: AppPalette.primary,
      iconOnDarkTint:  Colors.white,
      textOnTint:      AppPalette.secondary,
      textOnLightTint: AppPalette.primary,
      textOnDarkTint:  Colors.white,
    );
  }

  @override
  AppThemeColors copyWith({
    Color? brandPrimary,
    Color? brandSecondary,
    Color? brandAccent,
    Color? premiumGold,
    Color? scaffold,
    Color? surface,
    Color? surfaceAlt,
    Color? card,
    Color? textPrimary,
    Color? textSecondary,
    Color? iconPrimary,
    Color? border,
    Color? borderSoft,
    Color? shadow,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? cream,
    Color? champagne,
    Color? ivory,
    Color? brown,
    Color? darkBrown,
    Color? purple,
    Color? palePurple,
    Color? paleBlue,
    Color? paleGreen,
    Color? paleOrange,
    Color? paleRed,
    Color? paleGold,
    Color? iconOnPrimary,
    Color? iconOnSecondary,
    Color? textOnPrimary,
    Color? textOnSecondary,
    Color? iconOnTint,
    Color? iconOnLightTint,
    Color? iconOnDarkTint,
    Color? textOnTint,
    Color? textOnLightTint,
    Color? textOnDarkTint,
  }) {
    return AppThemeColors(
      brandPrimary:    brandPrimary    ?? this.brandPrimary,
      brandSecondary:  brandSecondary  ?? this.brandSecondary,
      brandAccent:     brandAccent     ?? this.brandAccent,
      premiumGold:     premiumGold     ?? this.premiumGold,
      scaffold:        scaffold        ?? this.scaffold,
      surface:         surface         ?? this.surface,
      surfaceAlt:      surfaceAlt      ?? this.surfaceAlt,
      card:            card            ?? this.card,
      textPrimary:     textPrimary     ?? this.textPrimary,
      textSecondary:   textSecondary   ?? this.textSecondary,
      iconPrimary:     iconPrimary     ?? this.iconPrimary,
      border:          border          ?? this.border,
      borderSoft:      borderSoft      ?? this.borderSoft,
      shadow:          shadow          ?? this.shadow,
      success:         success         ?? this.success,
      warning:         warning         ?? this.warning,
      error:           error           ?? this.error,
      info:            info            ?? this.info,
      cream:           cream           ?? this.cream,
      champagne:       champagne       ?? this.champagne,
      ivory:           ivory           ?? this.ivory,
      brown:           brown           ?? this.brown,
      darkBrown:       darkBrown       ?? this.darkBrown,
      purple:          purple          ?? this.purple,
      palePurple:      palePurple      ?? this.palePurple,
      paleBlue:        paleBlue        ?? this.paleBlue,
      paleGreen:       paleGreen       ?? this.paleGreen,
      paleOrange:      paleOrange      ?? this.paleOrange,
      paleRed:         paleRed         ?? this.paleRed,
      paleGold:        paleGold        ?? this.paleGold,
      iconOnPrimary:   iconOnPrimary   ?? this.iconOnPrimary,
      iconOnSecondary: iconOnSecondary ?? this.iconOnSecondary,
      textOnPrimary:   textOnPrimary   ?? this.textOnPrimary,
      textOnSecondary: textOnSecondary ?? this.textOnSecondary,
      iconOnTint:      iconOnTint      ?? this.iconOnTint,
      iconOnLightTint: iconOnLightTint ?? this.iconOnLightTint,
      iconOnDarkTint:  iconOnDarkTint  ?? this.iconOnDarkTint,
      textOnTint:      textOnTint      ?? this.textOnTint,
      textOnLightTint: textOnLightTint ?? this.textOnLightTint,
      textOnDarkTint:  textOnDarkTint  ?? this.textOnDarkTint,
    );
  }

  @override
  ThemeExtension<AppThemeColors> lerp(
    covariant ThemeExtension<AppThemeColors>? other,
    double t,
  ) {
    if (other is! AppThemeColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;

    return AppThemeColors(
      brandPrimary:    l(brandPrimary,    other.brandPrimary),
      brandSecondary:  l(brandSecondary,  other.brandSecondary),
      brandAccent:     l(brandAccent,     other.brandAccent),
      premiumGold:     l(premiumGold,     other.premiumGold),
      scaffold:        l(scaffold,        other.scaffold),
      surface:         l(surface,         other.surface),
      surfaceAlt:      l(surfaceAlt,      other.surfaceAlt),
      card:            l(card,            other.card),
      textPrimary:     l(textPrimary,     other.textPrimary),
      textSecondary:   l(textSecondary,   other.textSecondary),
      iconPrimary:     l(iconPrimary,     other.iconPrimary),
      border:          l(border,          other.border),
      borderSoft:      l(borderSoft,      other.borderSoft),
      shadow:          l(shadow,          other.shadow),
      success:         l(success,         other.success),
      warning:         l(warning,         other.warning),
      error:           l(error,           other.error),
      info:            l(info,            other.info),
      cream:           l(cream,           other.cream),
      champagne:       l(champagne,       other.champagne),
      ivory:           l(ivory,           other.ivory),
      brown:           l(brown,           other.brown),
      darkBrown:       l(darkBrown,       other.darkBrown),
      purple:          l(purple,          other.purple),
      palePurple:      l(palePurple,      other.palePurple),
      paleBlue:        l(paleBlue,        other.paleBlue),
      paleGreen:       l(paleGreen,       other.paleGreen),
      paleOrange:      l(paleOrange,      other.paleOrange),
      paleRed:         l(paleRed,         other.paleRed),
      paleGold:        l(paleGold,        other.paleGold),
      iconOnPrimary:   l(iconOnPrimary,   other.iconOnPrimary),
      iconOnSecondary: l(iconOnSecondary, other.iconOnSecondary),
      textOnPrimary:   l(textOnPrimary,   other.textOnPrimary),
      textOnSecondary: l(textOnSecondary, other.textOnSecondary),
      iconOnTint:      l(iconOnTint,      other.iconOnTint),
      iconOnLightTint: l(iconOnLightTint, other.iconOnLightTint),
      iconOnDarkTint:  l(iconOnDarkTint,  other.iconOnDarkTint),
      textOnTint:      l(textOnTint,      other.textOnTint),
      textOnLightTint: l(textOnLightTint, other.textOnLightTint),
      textOnDarkTint:  l(textOnDarkTint,  other.textOnDarkTint),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppTheme — ThemeData factories
// ─────────────────────────────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  static AppThemeColors colorsOf(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeColors>();
    assert(ext != null, 'AppThemeColors extension not found in ThemeData');
    return ext!;
  }

  // ── Light Theme ──────────────────────────────────────────────────
  // Premium White + Gold — Clean luxury textile showroom feel

  static ThemeData light() {
    const colors = AppThemeColors(
      brandPrimary:   AppPalette.primary,
      brandSecondary: AppPalette.secondary,
      brandAccent:    AppPalette.accent,
      premiumGold:    AppPalette.premiumGold,
      scaffold:       AppPalette.lightScaffold,
      surface:        AppPalette.lightSurface,
      surfaceAlt:     AppPalette.lightSurfaceAlt,
      card:           AppPalette.lightCard,
      textPrimary:    AppPalette.lightText,
      textSecondary:  AppPalette.lightTextSoft,
      iconPrimary:    AppPalette.lightIcon,
      border:         AppPalette.lightBorder,
      borderSoft:     AppPalette.lightBorderSoft,
      shadow:         AppPalette.lightShadow,
      success:        AppPalette.success,
      warning:        AppPalette.warning,
      error:          AppPalette.error,
      info:           AppPalette.info,
      cream:          AppPalette.cream,
      champagne:      AppPalette.champagne,
      ivory:          AppPalette.ivory,
      brown:          AppPalette.brown,
      darkBrown:      AppPalette.darkBrown,
      purple:         AppPalette.purple,
      palePurple:     AppPalette.palePurple,
      paleBlue:       AppPalette.paleBlue,
      paleGreen:      AppPalette.paleGreen,
      paleOrange:     AppPalette.paleOrange,
      paleRed:        AppPalette.paleRed,
      paleGold:       AppPalette.paleGold,
      iconOnPrimary:   AppPalette.secondary,
      iconOnSecondary: Colors.white,
      textOnPrimary:   AppPalette.secondary,
      textOnSecondary: Colors.white,
      iconOnTint:      AppPalette.secondary,
      iconOnLightTint: AppPalette.primary,
      iconOnDarkTint:  Colors.white,
      textOnTint:      AppPalette.secondary,
      textOnLightTint: AppPalette.primary,
      textOnDarkTint:  Colors.white,
    );

    final colorScheme = ColorScheme.light(
      primary:                 colors.brandPrimary,
      primaryContainer:        AppPalette.paleGold,
      onPrimaryContainer:      AppPalette.darkBrown,
      secondary:               colors.brandSecondary,
      secondaryContainer:      AppPalette.lightSurfaceAlt,
      onSecondaryContainer:    AppPalette.lightText,
      surface:                 colors.surface,
      error:                   colors.error,
      onPrimary:               AppPalette.secondary,   // black text on gold button
      onSecondary:             Colors.white,
      onSurface:               colors.textPrimary,
      onError:                 Colors.white,
      surfaceContainerHighest: AppPalette.lightSurfaceAlt,
      outline:                 AppPalette.lightBorder,
      outlineVariant:          AppPalette.lightBorderSoft,
    );

    return ThemeData(
      useMaterial3:              true,
      brightness:                Brightness.light,
      colorScheme:               colorScheme,
      primaryColor:              colors.brandPrimary,
      scaffoldBackgroundColor:   colors.scaffold,
      canvasColor:               colors.surface,
      dividerColor:              colors.border,
      shadowColor:               colors.shadow,
      splashColor:               colors.brandPrimary.withOpacity(0.10),
      highlightColor:            colors.brandPrimary.withOpacity(0.05),
      extensions:                const [colors],

      // ── Typography — Premium Poppins/Montserrat feel ──────────────
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppPalette.lightText,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        headlineLarge: TextStyle(
          color: AppPalette.lightText,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        headlineMedium: TextStyle(
          color: AppPalette.lightText,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        titleLarge: TextStyle(
          color: AppPalette.lightText,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
        titleMedium: TextStyle(
          color: AppPalette.lightText,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        titleSmall: TextStyle(
          color: AppPalette.lightText,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        bodyLarge:  TextStyle(color: AppPalette.lightText, fontSize: 16),
        bodyMedium: TextStyle(color: AppPalette.lightText, fontSize: 14),
        bodySmall:  TextStyle(color: AppPalette.lightTextSoft, fontSize: 12),
        labelLarge: TextStyle(
          color: AppPalette.lightText,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          color: AppPalette.lightTextSoft,
          letterSpacing: 0.8,
        ),
      ),

      // ── AppBar — minimal, premium ─────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor:        colors.scaffold,
        foregroundColor:        colors.textPrimary,
        elevation:              0,
        scrolledUnderElevation: 0,
        shadowColor:            Colors.transparent,
        surfaceTintColor:       Colors.transparent,
        iconTheme:              IconThemeData(color: colors.iconPrimary),
        actionsIconTheme:       IconThemeData(color: colors.iconPrimary),
        centerTitle:            true,
        titleTextStyle: const TextStyle(
          color:       AppPalette.lightText,
          fontSize:    18,
          fontWeight:  FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),

      iconTheme: IconThemeData(color: colors.iconPrimary),

      // ── Card — clean white, subtle gold border ────────────────────
      cardTheme: CardThemeData(
        color:       colors.card,
        elevation:   0,
        shadowColor: colors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.borderSoft, width: 1),
        ),
        margin: const EdgeInsets.all(0),
      ),

      // ── Elevated Button — Gold with black text (luxury CTA) ───────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.brandPrimary,     // gold
          foregroundColor: AppPalette.secondary,    // black text on gold
          elevation:       0,
          shadowColor:     colors.brandPrimary.withOpacity(0.30),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight:  FontWeight.w700,
            fontSize:    15,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // ── Outlined Button — Gold border, gold text ──────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.brandPrimary,
          side: BorderSide(color: colors.brandPrimary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // ── Text Button — Gold text ───────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.brandPrimary,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // ── Input — clean white, gold focus ring ──────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled:             true,
        fillColor:          colors.surface,
        hintStyle:          TextStyle(
          color:    colors.textSecondary,
          fontSize: 14,
        ),
        prefixIconColor:    colors.textSecondary,
        suffixIconColor:    colors.textSecondary,
        contentPadding:     const EdgeInsets.symmetric(
          horizontal: 16,
          vertical:   14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   BorderSide(
            color: colors.brandPrimary,
            width: 1.8,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   BorderSide(color: colors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   BorderSide(color: colors.error, width: 1.8),
        ),
      ),

      // ── Bottom Navigation — gold active, grey inactive ────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor:      colors.surface,
        selectedItemColor:    colors.brandPrimary,    // gold
        unselectedItemColor:  const Color(0xFF8A8A8A),
        selectedLabelStyle:   const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize:   11,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize:   11,
        ),
        type:                 BottomNavigationBarType.fixed,
        elevation:            12,
        showSelectedLabels:   true,
        showUnselectedLabels: true,
      ),

      // ── Chip — gold selected, light bg unselected ─────────────────
      chipTheme: ChipThemeData(
        backgroundColor:     colors.surfaceAlt,
        selectedColor:       colors.brandPrimary,
        disabledColor:       colors.borderSoft,
        side:                BorderSide(color: colors.border),
        labelStyle:          TextStyle(
          color:      colors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          color:      AppPalette.secondary,   // black on gold chip
          fontWeight: FontWeight.w600,
        ),
        shape:   RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      ),

      // ── Dialog ────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        elevation:       8,
        shadowColor:     colors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // ── Snackbar — black with gold action (brand) ─────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppPalette.secondary,        // brand black
        contentTextStyle: const TextStyle(
          color:      Colors.white,
          fontSize:   13,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: AppPalette.primaryLight,     // champagne gold action
        behavior:        SnackBarBehavior.floating,
        elevation:       6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // ── Switch — gold when on ─────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.brandPrimary;
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.brandPrimary.withOpacity(0.40);
          }
          return colors.border;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.brandPrimary,
      ),

      dividerTheme: DividerThemeData(
        color:     colors.borderSoft,
        thickness: 1,
        space:     1,
      ),

      listTileTheme: ListTileThemeData(
        tileColor:      Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical:   4,
        ),
      ),

      // ── FloatingActionButton — gold ───────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.brandPrimary,
        foregroundColor: AppPalette.secondary,
        elevation:       4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // ── TabBar ────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor:           colors.brandPrimary,
        unselectedLabelColor: colors.textSecondary,
        indicatorColor:       colors.brandPrimary,
        indicatorSize:        TabBarIndicatorSize.label,
        labelStyle: const TextStyle(
          fontWeight:   FontWeight.w700,
          fontSize:     14,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize:   14,
        ),
        dividerColor: Colors.transparent,
      ),
    );
  }

  // ── Dark Theme ───────────────────────────────────────────────────
  // Deep Black + Gold — Ultra premium night mode

  static ThemeData dark() {
    const colors = AppThemeColors(
      brandPrimary:   AppPalette.primary,
      brandSecondary: AppPalette.darkText,
      brandAccent:    AppPalette.premiumGold,
      premiumGold:    AppPalette.premiumGold,
      scaffold:       AppPalette.darkScaffold,
      surface:        AppPalette.darkSurface,
      surfaceAlt:     AppPalette.darkSurfaceAlt,
      card:           AppPalette.darkCard,
      textPrimary:    AppPalette.darkText,
      textSecondary:  AppPalette.darkTextSoft,
      iconPrimary:    AppPalette.darkIcon,
      border:         AppPalette.darkBorder,
      borderSoft:     AppPalette.darkBorderSoft,
      shadow:         AppPalette.darkShadow,
      success:        AppPalette.success,
      warning:        AppPalette.warning,
      error:          AppPalette.error,
      info:           AppPalette.info,
      cream:          AppPalette.darkPaleGold,
      champagne:      AppPalette.darkPaleOrange,
      ivory:          AppPalette.darkPaleGold,
      brown:          AppPalette.champagne,
      darkBrown:      AppPalette.cream,
      purple:         AppPalette.purple,
      palePurple:     AppPalette.darkPalePurple,
      paleBlue:       AppPalette.darkPaleBlue,
      paleGreen:      AppPalette.darkPaleGreen,
      paleOrange:     AppPalette.darkPaleOrange,
      paleRed:        AppPalette.darkPaleRed,
      paleGold:       AppPalette.darkPaleGold,
      iconOnPrimary:   AppPalette.secondary,
      iconOnSecondary: AppPalette.primary,
      textOnPrimary:   AppPalette.secondary,
      textOnSecondary: AppPalette.primary,
      iconOnTint:      AppPalette.secondary,
      iconOnLightTint: AppPalette.primary,
      iconOnDarkTint:  Colors.white,
      textOnTint:      AppPalette.secondary,
      textOnLightTint: AppPalette.primary,
      textOnDarkTint:  Colors.white,
    );

    final colorScheme = ColorScheme.dark(
      primary:                 colors.brandPrimary,
      primaryContainer:        AppPalette.darkPaleGold,
      onPrimaryContainer:      AppPalette.primaryLight,
      secondary:               colors.brandSecondary,
      secondaryContainer:      AppPalette.darkSurfaceAlt,
      onSecondaryContainer:    AppPalette.darkText,
      surface:                 colors.surface,
      error:                   colors.error,
      onPrimary:               AppPalette.secondary,    // black on gold
      onSecondary:             AppPalette.primary,      // gold on dark secondary
      onSurface:               colors.textPrimary,
      onError:                 Colors.white,
      surfaceContainerHighest: AppPalette.darkSurfaceAlt,
      outline:                 AppPalette.darkBorder,
      outlineVariant:          AppPalette.darkBorderSoft,
    );

    return ThemeData(
      useMaterial3:            true,
      brightness:              Brightness.dark,
      colorScheme:             colorScheme,
      primaryColor:            colors.brandPrimary,
      scaffoldBackgroundColor: colors.scaffold,
      canvasColor:             colors.surface,
      dividerColor:            colors.border,
      shadowColor:             colors.shadow,
      splashColor:             colors.brandPrimary.withOpacity(0.14),
      highlightColor:          colors.brandPrimary.withOpacity(0.07),
      extensions:              const [colors],

      // ── Typography — crisp white on black ────────────────────────
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppPalette.darkText,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        headlineLarge: TextStyle(
          color: AppPalette.darkText,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        headlineMedium: TextStyle(
          color: AppPalette.darkText,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        titleLarge: TextStyle(
          color: AppPalette.darkText,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
        titleMedium: TextStyle(
          color: AppPalette.darkText,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        titleSmall: TextStyle(
          color: AppPalette.darkText,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        bodyLarge:  TextStyle(color: AppPalette.darkText, fontSize: 16),
        bodyMedium: TextStyle(color: AppPalette.darkText, fontSize: 14),
        bodySmall:  TextStyle(color: AppPalette.darkTextSoft, fontSize: 12),
        labelLarge: TextStyle(
          color: AppPalette.darkText,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          color: AppPalette.darkTextSoft,
          letterSpacing: 0.8,
        ),
      ),

      // ── AppBar ────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor:        colors.scaffold,
        foregroundColor:        colors.textPrimary,
        elevation:              0,
        scrolledUnderElevation: 0,
        shadowColor:            Colors.transparent,
        surfaceTintColor:       Colors.transparent,
        iconTheme:              IconThemeData(color: colors.iconPrimary),
        actionsIconTheme:       IconThemeData(color: colors.iconPrimary),
        centerTitle:            true,
        titleTextStyle: const TextStyle(
          color:       AppPalette.darkText,
          fontSize:    18,
          fontWeight:  FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),

      iconTheme: IconThemeData(color: colors.iconPrimary),

      // ── Card — dark charcoal, gold border tint ────────────────────
      cardTheme: CardThemeData(
        color:       colors.card,
        elevation:   0,
        shadowColor: colors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.borderSoft, width: 1),
        ),
        margin: const EdgeInsets.all(0),
      ),

      // ── Elevated Button — Gold with black text ────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.brandPrimary,     // gold
          foregroundColor: AppPalette.secondary,    // black text on gold
          elevation:       0,
          shadowColor:     colors.brandPrimary.withOpacity(0.35),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight:  FontWeight.w700,
            fontSize:    15,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // ── Outlined Button ───────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.brandPrimary,
          side: BorderSide(color: colors.brandPrimary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // ── Text Button ───────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.brandPrimary,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // ── Input — dark fill, gold focus ring ───────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled:          true,
        fillColor:       colors.surfaceAlt,
        hintStyle:       TextStyle(
          color:    colors.textSecondary,
          fontSize: 14,
        ),
        prefixIconColor: colors.textSecondary,
        suffixIconColor: colors.textSecondary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical:   14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   BorderSide(
            color: colors.brandPrimary,
            width: 1.8,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   BorderSide(color: colors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   BorderSide(color: colors.error, width: 1.8),
        ),
      ),

      // ── Bottom Navigation — gold active ───────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor:      colors.surface,
        selectedItemColor:    colors.brandPrimary,    // gold
        unselectedItemColor:  const Color(0xFF6B6B6B),
        selectedLabelStyle:   const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize:   11,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize:   11,
        ),
        type:                 BottomNavigationBarType.fixed,
        elevation:            12,
        showSelectedLabels:   true,
        showUnselectedLabels: true,
      ),

      // ── Chip ──────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor:     colors.surfaceAlt,
        selectedColor:       colors.brandPrimary,
        disabledColor:       colors.borderSoft,
        side:                BorderSide(color: colors.border),
        labelStyle:          TextStyle(
          color:      colors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          color:      AppPalette.secondary,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      ),

      // ── Dialog ────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        elevation:       10,
        shadowColor:     colors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // ── Snackbar — deep charcoal gold-tinted, premium ─────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1A1600),    // very dark gold-tinted black
        contentTextStyle: const TextStyle(
          color:      Colors.white,
          fontSize:   13,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: AppPalette.primaryLight,
        behavior:        SnackBarBehavior.floating,
        elevation:       6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // ── Switch — gold when on ─────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.brandPrimary;
          return colors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.brandPrimary.withOpacity(0.40);
          }
          return colors.border;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.brandPrimary,
      ),

      dividerTheme: DividerThemeData(
        color:     colors.borderSoft,
        thickness: 1,
        space:     1,
      ),

      listTileTheme: ListTileThemeData(
        tileColor:      Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical:   4,
        ),
      ),

      // ── FloatingActionButton — gold ───────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.brandPrimary,
        foregroundColor: AppPalette.secondary,
        elevation:       4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // ── TabBar ────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor:           colors.brandPrimary,
        unselectedLabelColor: colors.textSecondary,
        indicatorColor:       colors.brandPrimary,
        indicatorSize:        TabBarIndicatorSize.label,
        labelStyle: const TextStyle(
          fontWeight:   FontWeight.w700,
          fontSize:     14,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize:   14,
        ),
        dividerColor: Colors.transparent,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GlassPanel — luxury glass effect, gold-tinted border
// ─────────────────────────────────────────────────────────────────────────────

class GlassPanel extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  const GlassPanel({
    super.key,
    required this.child,
    this.blur         = 15.0,
    this.opacity      = 0.6,
    this.width,
    this.height,
    this.padding      = const EdgeInsets.all(16.0),
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width:   width,
          height:  height,
          padding: padding,
          decoration: BoxDecoration(
            color:        colors.card.withOpacity(opacity),
            borderRadius: borderRadius,
            border: Border.all(
              color: colors.borderSoft,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color:      colors.shadow,
                blurRadius: 12,
                offset:     const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
