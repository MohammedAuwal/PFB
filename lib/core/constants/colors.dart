import 'package:flutter/material.dart';
import 'package:pfb/core/theme/app_theme.dart';

class AppColors {
  AppColors._();

  // ── Brand Core ─────────────────────────────────────────────────
  static const Color primary        = AppPalette.primary;
  static const Color primaryDark    = AppPalette.primaryDark;
  static const Color primaryLight   = AppPalette.primaryLight;
  static const Color premiumGold    = AppPalette.premiumGold;
  static const Color champagne      = AppPalette.champagne;
  static const Color secondary      = AppPalette.secondary;
  static const Color accent         = AppPalette.accent;

  // ── Semantic ───────────────────────────────────────────────────
  static const Color success  = AppPalette.success;
  static const Color warning  = AppPalette.warning;
  static const Color error    = AppPalette.error;
  static const Color info     = AppPalette.info;

  // ── Tonal ──────────────────────────────────────────────────────
  static const Color ivory      = AppPalette.ivory;
  static const Color warmBeige  = AppPalette.warmBeige;
  static const Color brown      = AppPalette.brown;
  static const Color darkBrown  = AppPalette.darkBrown;
  static const Color purple     = AppPalette.purple;

  // ── Pale tones ─────────────────────────────────────────────────
  static const Color paleGold   = AppPalette.paleGold;
  static const Color palePurple = AppPalette.palePurple;
  static const Color paleBlue   = AppPalette.paleBlue;
  static const Color paleGreen  = AppPalette.paleGreen;
  static const Color paleOrange = AppPalette.paleOrange;
  static const Color paleRed    = AppPalette.paleRed;

  // ── Context accessor ───────────────────────────────────────────
  static AppThemeColors of(BuildContext context) => AppTheme.colorsOf(context);
}