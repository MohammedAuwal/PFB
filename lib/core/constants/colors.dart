import 'package:flutter/material.dart';
import 'package:pfb/core/theme/app_theme.dart';

class AppColors {
  AppColors._();

  // ── Brand Core ──────────────────────────────────────────────────
  static const Color primary      = AppPalette.primary;       // Metallic Gold #D4AF37
  static const Color secondary    = AppPalette.secondary;     // Deep Charcoal #1A1A1A
  static const Color premiumGold  = AppPalette.premiumGold;   // Pure Gold     #FFD700
  static const Color accent       = AppPalette.accent;        // Antique Gold  #B8860B

  // ── Semantic ────────────────────────────────────────────────────
  static const Color success = AppPalette.success;
  static const Color warning = AppPalette.warning;
  static const Color error   = AppPalette.error;
  static const Color info    = AppPalette.info;

  // ── Tonal ───────────────────────────────────────────────────────
  static const Color cream      = AppPalette.cream;
  static const Color champagne  = AppPalette.champagne;
  static const Color ivory      = AppPalette.ivory;
  static const Color brown      = AppPalette.brown;
  static const Color darkBrown  = AppPalette.darkBrown;
  static const Color purple     = AppPalette.purple;
  static const Color palePurple = AppPalette.palePurple;
  static const Color paleBlue   = AppPalette.paleBlue;
  static const Color paleGreen  = AppPalette.paleGreen;
  static const Color paleOrange = AppPalette.paleOrange;
  static const Color paleRed    = AppPalette.paleRed;
  static const Color paleGold   = AppPalette.paleGold;

  static AppThemeColors of(BuildContext context) => AppTheme.colorsOf(context);
}
