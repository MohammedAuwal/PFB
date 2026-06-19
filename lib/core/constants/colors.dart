import 'package:flutter/material.dart';
import 'package:pfb/core/theme/app_theme.dart';

class AppColors {
  AppColors._();

  static const Color primary = AppPalette.primary;
  static const Color secondary = AppPalette.secondary;
  static const Color success = AppPalette.success;
  static const Color warning = AppPalette.warning;
  static const Color error = AppPalette.error;
  static const Color info = AppPalette.info;

  static const Color cream = AppPalette.cream;
  static const Color brown = AppPalette.brown;
  static const Color darkBrown = AppPalette.darkBrown;
  static const Color orange = AppPalette.orange;
  static const Color palePurple = AppPalette.palePurple;
  static const Color paleBlue = AppPalette.paleBlue;
  static const Color paleGreen = AppPalette.paleGreen;
  static const Color paleOrange = AppPalette.paleOrange;
  static const Color paleRed = AppPalette.paleRed;

  static AppThemeColors of(BuildContext context) => AppTheme.colorsOf(context);
}
