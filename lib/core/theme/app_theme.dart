import 'dart:ui';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// IsmailTex Brand Analysis from Logo:
//
//  PRIMARY   → Vivid Red     #CC2222  (TEX lettering, logo icon, tagline)
//  SECONDARY → Pure Black    #1A1A1A  (ISMAIL lettering, swoosh)
//  ACCENT    → Deep Red      #A61818  (darker red for depth/hover)
//
//  Light Mode Background → Silver-white paper #F4F2EF (logo background)
//  Dark Mode Background  → Deep black         #111111 (bottom curve)
//  Dark Mode Surface     → Dark charcoal      #1A1A1A (secondary brand black)
// ─────────────────────────────────────────────────────────────────────────────

class AppPalette {
  AppPalette._();

  // ── Brand Core ─────────────────────────────────────────────────
  /// Primary brand red — exact "TEX" red from the IsmailTex logo
  static const Color primary = Color(0xFFCC2222);

  /// Primary dark — deeper red for pressed / gradient end
  static const Color primaryDark = Color(0xFFA61818);

  /// Primary light — soft red for tinted surfaces
  static const Color primaryLight = Color(0xFFE84040);

  /// Secondary — brand black ("ISMAIL" lettering + swoosh)
  static const Color secondary = Color(0xFF1A1A1A);

  /// Accent — red-tinted dark, used for hover / depth
  static const Color accent = Color(0xFF8B1111);

  // ── Semantic ───────────────────────────────────────────────────
  static const Color success = Color(0xFF22AD5C);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error   = Color(0xFFDC2626);
  static const Color info    = Color(0xFF2563EB);

  // ── Light Mode ─────────────────────────────────────────────────
  /// Matches the silver-white paper texture of the logo background
  static const Color lightScaffold   = Color(0xFFF4F2EF);
  static const Color lightSurface    = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFF0EEEB);
  static const Color lightCard       = Color(0xFFFFFFFF);

  /// Border uses a warm silver derived from the logo paper
  static const Color lightBorder     = Color(0xFFE0DCDA);
  static const Color lightBorderSoft = Color(0xFFEAE7E4);

  static const Color lightText       = Color(0xFF1A1A1A); // brand black
  static const Color lightTextSoft   = Color(0xFF6B6870);
  static const Color lightIcon       = Color(0xFF1A1A1A);
  static const Color lightShadow     = Color(0x16000000);

  // ── Dark Mode ──────────────────────────────────────────────────
  /// Matches the deep black bottom-curve of the logo
  static const Color darkScaffold    = Color(0xFF111111);
  static const Color darkSurface     = Color(0xFF1C1C1C);
  static const Color darkSurfaceAlt  = Color(0xFF161616);
  static const Color darkCard        = Color(0xFF1C1C1C);

  /// Borders: very subtle red tint in dark mode for brand cohesion
  static const Color darkBorder      = Color(0x30FFFFFF);
  static const Color darkBorderSoft  = Color(0x1AFFFFFF);

  static const Color darkText        = Color(0xFFF5F3F3);
  static const Color darkTextSoft    = Color(0xAAF5F3F3);
  static const Color darkIcon        = Color(0xFFF5F3F3);
  static const Color darkShadow      = Color(0x44000000);

  // ── Tonal Palette (derived from brand) ─────────────────────────
  /// Pale red — used for light tinted containers, warnings, subtle bg
  static const Color paleRed    = Color(0xFFFFF0F0);

  /// Warm off-white — logo paper tone, used for cream surfaces
  static const Color cream      = Color(0xFFF4EDE0);

  /// Rich brown — warm text on cream backgrounds
  static const Color brown      = Color(0xFF7A3B1E);

  /// Dark brown — deep warm contrast
  static const Color darkBrown  = Color(0xFF3D1A00);

  /// Muted purple — accent for variety
  static const Color purple     = Color(0xFF6D28D9);

  // ── Pale tones (light backgrounds for chips/cards) ─────────────
  static const Color palePurple = Color(0xFFF5F0FF);
  static const Color paleBlue   = Color(0xFFEFF6FF);
  static const Color paleGreen  = Color(0xFFECFDF5);
  static const Color paleOrange = Color(0xFFFFF7ED);

  // ── Dark-mode tonal backgrounds ────────────────────────────────
  /// Dark red tint — for highlighted containers in dark mode
  static const Color darkPaleRed    = Color(0xFF2A0A0A);
  static const Color darkPaleOrange = Color(0xFF1F1208);
  static const Color darkPaleGreen  = Color(0xFF0A1F14);
  static const Color darkPaleBlue   = Color(0xFF0A1428);
  static const Color darkPalePurple = Color(0xFF160D2E);
}

// ─────────────────────────────────────────────────────────────────────────────
// AppThemeColors — ThemeExtension
// ─────────────────────────────────────────────────────────────────────────────

class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color brandPrimary;
  final Color brandSecondary;
  final Color brandAccent;
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
  final Color brown;
  final Color darkBrown;
  final Color purple;
  final Color palePurple;
  final Color paleBlue;
  final Color paleGreen;
  final Color paleOrange;
  final Color paleRed;

  // Contrast helpers
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
    required this.brown,
    required this.darkBrown,
    required this.purple,
    required this.palePurple,
    required this.paleBlue,
    required this.paleGreen,
    required this.paleOrange,
    required this.paleRed,
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
      brown:          AppPalette.brown,
      darkBrown:      AppPalette.darkBrown,
      purple:         AppPalette.purple,
      palePurple:     AppPalette.palePurple,
      paleBlue:       AppPalette.paleBlue,
      paleGreen:      AppPalette.paleGreen,
      paleOrange:     AppPalette.paleOrange,
      paleRed:        AppPalette.paleRed,
      // On a red/dark tint → white text/icons
      iconOnTint:      Colors.white,
      iconOnLightTint: AppPalette.primary,
      iconOnDarkTint:  Colors.white,
      textOnTint:      Colors.white,
      textOnLightTint: AppPalette.primary,
      textOnDarkTint:  Colors.white,
    );
  }

  // ── Dark Factory ─────────────────────────────────────────────────

  factory AppThemeColors.dark() {
    return const AppThemeColors(
      brandPrimary:   AppPalette.primaryLight,   // slightly brighter red on dark
      brandSecondary: AppPalette.darkText,        // white label text in dark
      brandAccent:    AppPalette.primary,
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
      cream:          AppPalette.darkPaleOrange,  // warm dark tone
      brown:          AppPalette.paleOrange,       // reversed for dark
      darkBrown:      AppPalette.cream,
      purple:         AppPalette.purple,
      palePurple:     AppPalette.darkPalePurple,
      paleBlue:       AppPalette.darkPaleBlue,
      paleGreen:      AppPalette.darkPaleGreen,
      paleOrange:     AppPalette.darkPaleOrange,
      paleRed:        AppPalette.darkPaleRed,
      iconOnTint:      Colors.white,
      iconOnLightTint: AppPalette.primaryLight,
      iconOnDarkTint:  Colors.white,
      textOnTint:      Colors.white,
      textOnLightTint: AppPalette.primaryLight,
      textOnDarkTint:  Colors.white,
    );
  }

  @override
  AppThemeColors copyWith({
    Color? brandPrimary,
    Color? brandSecondary,
    Color? brandAccent,
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
    Color? brown,
    Color? darkBrown,
    Color? purple,
    Color? palePurple,
    Color? paleBlue,
    Color? paleGreen,
    Color? paleOrange,
    Color? paleRed,
    Color? iconOnTint,
    Color? iconOnLightTint,
    Color? iconOnDarkTint,
    Color? textOnTint,
    Color? textOnLightTint,
    Color? textOnDarkTint,
  }) {
    return AppThemeColors(
      brandPrimary:   brandPrimary   ?? this.brandPrimary,
      brandSecondary: brandSecondary ?? this.brandSecondary,
      brandAccent:    brandAccent    ?? this.brandAccent,
      scaffold:       scaffold       ?? this.scaffold,
      surface:        surface        ?? this.surface,
      surfaceAlt:     surfaceAlt     ?? this.surfaceAlt,
      card:           card           ?? this.card,
      textPrimary:    textPrimary    ?? this.textPrimary,
      textSecondary:  textSecondary  ?? this.textSecondary,
      iconPrimary:    iconPrimary    ?? this.iconPrimary,
      border:         border         ?? this.border,
      borderSoft:     borderSoft     ?? this.borderSoft,
      shadow:         shadow         ?? this.shadow,
      success:        success        ?? this.success,
      warning:        warning        ?? this.warning,
      error:          error          ?? this.error,
      info:           info           ?? this.info,
      cream:          cream          ?? this.cream,
      brown:          brown          ?? this.brown,
      darkBrown:      darkBrown      ?? this.darkBrown,
      purple:         purple         ?? this.purple,
      palePurple:     palePurple     ?? this.palePurple,
      paleBlue:       paleBlue       ?? this.paleBlue,
      paleGreen:      paleGreen      ?? this.paleGreen,
      paleOrange:     paleOrange     ?? this.paleOrange,
      paleRed:        paleRed        ?? this.paleRed,
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
      brown:           l(brown,           other.brown),
      darkBrown:       l(darkBrown,       other.darkBrown),
      purple:          l(purple,          other.purple),
      palePurple:      l(palePurple,      other.palePurple),
      paleBlue:        l(paleBlue,        other.paleBlue),
      paleGreen:       l(paleGreen,       other.paleGreen),
      paleOrange:      l(paleOrange,      other.paleOrange),
      paleRed:         l(paleRed,         other.paleRed),
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

  static ThemeData light() {
    const colors = AppThemeColors(
      brandPrimary:   AppPalette.primary,
      brandSecondary: AppPalette.secondary,
      brandAccent:    AppPalette.accent,
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
      brown:          AppPalette.brown,
      darkBrown:      AppPalette.darkBrown,
      purple:         AppPalette.purple,
      palePurple:     AppPalette.palePurple,
      paleBlue:       AppPalette.paleBlue,
      paleGreen:      AppPalette.paleGreen,
      paleOrange:     AppPalette.paleOrange,
      paleRed:        AppPalette.paleRed,
      iconOnTint:      Colors.white,
      iconOnLightTint: AppPalette.primary,
      iconOnDarkTint:  Colors.white,
      textOnTint:      Colors.white,
      textOnLightTint: AppPalette.primary,
      textOnDarkTint:  Colors.white,
    );

    final colorScheme = ColorScheme.light(
      primary:          colors.brandPrimary,
      primaryContainer: AppPalette.paleRed,
      secondary:        colors.brandSecondary,
      surface:          colors.surface,
      error:            colors.error,
      onPrimary:        Colors.white,
      onSecondary:      Colors.white,
      onSurface:        colors.textPrimary,
      onError:          Colors.white,
      surfaceContainerHighest: AppPalette.lightSurfaceAlt,
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
      splashColor:               colors.brandPrimary.withOpacity(0.08),
      highlightColor:            colors.brandPrimary.withOpacity(0.04),
      extensions:                const [colors],

      textTheme: const TextTheme(
        displayLarge:  TextStyle(color: AppPalette.lightText, fontWeight: FontWeight.w800),
        headlineLarge: TextStyle(color: AppPalette.lightText, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(color: AppPalette.lightText, fontWeight: FontWeight.bold),
        titleLarge:    TextStyle(color: AppPalette.lightText, fontSize: 18, fontWeight: FontWeight.w700),
        titleMedium:   TextStyle(color: AppPalette.lightText, fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge:     TextStyle(color: AppPalette.lightText),
        bodyMedium:    TextStyle(color: AppPalette.lightText),
        bodySmall:     TextStyle(color: AppPalette.lightTextSoft),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor:       colors.scaffold,
        foregroundColor:       colors.textPrimary,
        elevation:             0,
        scrolledUnderElevation: 0,
        shadowColor:           Colors.transparent,
        iconTheme:             IconThemeData(color: colors.iconPrimary),
        actionsIconTheme:      IconThemeData(color: colors.iconPrimary),
        titleTextStyle: const TextStyle(
          color:      AppPalette.lightText,
          fontSize:   18,
          fontWeight: FontWeight.w700,
        ),
      ),

      iconTheme: IconThemeData(color: colors.iconPrimary),

      cardTheme: CardThemeData(
        color:       colors.card,
        elevation:   0,
        shadowColor: colors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: colors.borderSoft),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.brandPrimary,    // red
          foregroundColor: Colors.white,
          elevation:       2,
          shadowColor:     colors.brandPrimary.withOpacity(0.35),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.brandPrimary,
          side: BorderSide(color: colors.brandPrimary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.brandPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled:      true,
        fillColor:   colors.surface,
        hintStyle:   TextStyle(color: colors.textSecondary, fontSize: 14),
        prefixIconColor: colors.textSecondary,
        suffixIconColor: colors.textSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.brandPrimary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.error, width: 1.5),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor:      colors.surface,
        selectedItemColor:    colors.brandPrimary,
        unselectedItemColor:  colors.textSecondary,
        selectedLabelStyle:   const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
        type:                 BottomNavigationBarType.fixed,
        elevation:            10,
        showSelectedLabels:   true,
        showUnselectedLabels: true,
      ),

      chipTheme: ChipThemeData(
        backgroundColor:    colors.surface,
        selectedColor:      colors.brandPrimary,
        disabledColor:      colors.borderSoft,
        side:               BorderSide(color: colors.border),
        labelStyle:         TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w500),
        secondaryLabelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        elevation:       8,
        shadowColor:     colors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1A1A1A),  // brand black
        contentTextStyle: const TextStyle(
          color:      Colors.white,
          fontSize:   13,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: AppPalette.primaryLight,
        behavior:  SnackBarBehavior.floating,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),

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
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          return Colors.transparent;
        }),
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
        tileColor:         Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  // ── Dark Theme ───────────────────────────────────────────────────

  static ThemeData dark() {
    const colors = AppThemeColors(
      brandPrimary:   AppPalette.primaryLight,
      brandSecondary: AppPalette.darkText,
      brandAccent:    AppPalette.primary,
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
      cream:          AppPalette.darkPaleOrange,
      brown:          AppPalette.paleOrange,
      darkBrown:      AppPalette.cream,
      purple:         AppPalette.purple,
      palePurple:     AppPalette.darkPalePurple,
      paleBlue:       AppPalette.darkPaleBlue,
      paleGreen:      AppPalette.darkPaleGreen,
      paleOrange:     AppPalette.darkPaleOrange,
      paleRed:        AppPalette.darkPaleRed,
      iconOnTint:      Colors.white,
      iconOnLightTint: AppPalette.primaryLight,
      iconOnDarkTint:  Colors.white,
      textOnTint:      Colors.white,
      textOnLightTint: AppPalette.primaryLight,
      textOnDarkTint:  Colors.white,
    );

    final colorScheme = ColorScheme.dark(
      primary:          colors.brandPrimary,
      primaryContainer: AppPalette.darkPaleRed,
      secondary:        colors.brandSecondary,
      surface:          colors.surface,
      error:            colors.error,
      onPrimary:        Colors.white,
      onSecondary:      Colors.white,
      onSurface:        colors.textPrimary,
      onError:          Colors.white,
      surfaceContainerHighest: AppPalette.darkSurfaceAlt,
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
      splashColor:             colors.brandPrimary.withOpacity(0.12),
      highlightColor:          colors.brandPrimary.withOpacity(0.06),
      extensions:              const [colors],

      textTheme: const TextTheme(
        displayLarge:   TextStyle(color: AppPalette.darkText, fontWeight: FontWeight.w800),
        headlineLarge:  TextStyle(color: AppPalette.darkText, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(color: AppPalette.darkText, fontWeight: FontWeight.bold),
        titleLarge:     TextStyle(color: AppPalette.darkText, fontSize: 18, fontWeight: FontWeight.w700),
        titleMedium:    TextStyle(color: AppPalette.darkText, fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge:      TextStyle(color: AppPalette.darkText),
        bodyMedium:     TextStyle(color: AppPalette.darkText),
        bodySmall:      TextStyle(color: AppPalette.darkTextSoft),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor:        colors.scaffold,
        foregroundColor:        colors.textPrimary,
        elevation:              0,
        scrolledUnderElevation: 0,
        shadowColor:            Colors.transparent,
        iconTheme:              IconThemeData(color: colors.iconPrimary),
        actionsIconTheme:       IconThemeData(color: colors.iconPrimary),
        titleTextStyle: const TextStyle(
          color:      AppPalette.darkText,
          fontSize:   18,
          fontWeight: FontWeight.w700,
        ),
      ),

      iconTheme: IconThemeData(color: colors.iconPrimary),

      cardTheme: CardThemeData(
        color:       colors.card,
        elevation:   0,
        shadowColor: colors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: colors.borderSoft),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.brandPrimary,  // bright red on dark
          foregroundColor: Colors.white,
          elevation:       3,
          shadowColor:     colors.brandPrimary.withOpacity(0.45),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.brandPrimary,
          side: BorderSide(color: colors.brandPrimary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.brandPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled:      true,
        fillColor:   colors.surfaceAlt,
        hintStyle:   TextStyle(color: colors.textSecondary, fontSize: 14),
        prefixIconColor: colors.textSecondary,
        suffixIconColor: colors.textSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.brandPrimary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.error, width: 1.5),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor:      colors.surface,
        selectedItemColor:    colors.brandPrimary,
        unselectedItemColor:  colors.textSecondary,
        selectedLabelStyle:   const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
        type:                 BottomNavigationBarType.fixed,
        elevation:            10,
        showSelectedLabels:   true,
        showUnselectedLabels: true,
      ),

      chipTheme: ChipThemeData(
        backgroundColor:     colors.surfaceAlt,
        selectedColor:       colors.brandPrimary,
        disabledColor:       colors.borderSoft,
        side:                BorderSide(color: colors.border),
        labelStyle:          TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w500),
        secondaryLabelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        elevation:       10,
        shadowColor:     colors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        /// Deep charcoal with subtle red tint — on-brand for dark mode
        backgroundColor: const Color(0xFF2A1010),
        contentTextStyle: const TextStyle(
          color:      Colors.white,
          fontSize:   13,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: AppPalette.primaryLight,
        behavior:  SnackBarBehavior.floating,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),

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
        trackOutlineColor: WidgetStateProperty.resolveWith((_) {
          return Colors.transparent;
        }),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GlassPanel — unchanged, works with new colors
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
    this.blur        = 15.0,
    this.opacity     = 0.6,
    this.width,
    this.height,
    this.padding     = const EdgeInsets.all(16.0),
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
            border: Border.all(color: colors.borderSoft),
            boxShadow: [
              BoxShadow(
                color:      colors.shadow,
                blurRadius: 10,
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
