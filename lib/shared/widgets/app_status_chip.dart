import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/core/theme/build_context_theme_x.dart';

enum AppStatusChipTone {
  primary,
  success,
  warning,
  error,
  info,
  neutral,
}

class AppStatusChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final AppStatusChipTone tone;
  final EdgeInsetsGeometry padding;

  const AppStatusChip({
    super.key,
    required this.label,
    this.icon,
    this.tone = AppStatusChipTone.neutral,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
  });

  Color _bg(BuildContext context) {
    final colors = context.appColors;

    switch (tone) {
      case AppStatusChipTone.primary:
        return colors.brandPrimary.withOpacity(0.14);
      case AppStatusChipTone.success:
        return colors.success.withOpacity(0.14);
      case AppStatusChipTone.warning:
        return colors.warning.withOpacity(0.14);
      case AppStatusChipTone.error:
        return colors.error.withOpacity(0.14);
      case AppStatusChipTone.info:
        return colors.info.withOpacity(0.14);
      case AppStatusChipTone.neutral:
        return colors.surfaceAlt;
    }
  }

  Color _fg(BuildContext context) {
    final colors = context.appColors;

    switch (tone) {
      case AppStatusChipTone.primary:
        return colors.brandPrimary;
      case AppStatusChipTone.success:
        return colors.success;
      case AppStatusChipTone.warning:
        return colors.warning;
      case AppStatusChipTone.error:
        return colors.error;
      case AppStatusChipTone.info:
        return colors.info;
      case AppStatusChipTone.neutral:
        return colors.textPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fg = _fg(context);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _bg(context),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: GoogleFonts.poppins(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
