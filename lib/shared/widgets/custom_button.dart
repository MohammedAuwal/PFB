import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/core/theme/build_context_theme_x.dart';
import 'package:pfb/core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CustomButton — Phlakes Fabrics luxury button system
//
//  Variants:
//   • primary   → Gold background  + Black text  (main CTA)
//   • secondary → Black background + Gold text   (secondary CTA)
//   • outlined  → Gold border      + Gold text   (tertiary)
//   • ghost     → Transparent      + Gold text   (subtle)
//   • danger    → Error red        + White text  (destructive)
// ─────────────────────────────────────────────────────────────────────────────

enum ButtonVariant { primary, secondary, outlined, ghost, danger }

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isLoading;
  final bool fullWidth;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final double? width;
  final double height;
  final double borderRadius;
  final double fontSize;
  final EdgeInsetsGeometry? padding;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant      = ButtonVariant.primary,
    this.isLoading    = false,
    this.fullWidth    = true,
    this.prefixIcon,
    this.suffixIcon,
    this.width,
    this.height       = 56,
    this.borderRadius = 14,
    this.fontSize     = 15,
    this.padding,
  });

  // ── Convenience constructors ─────────────────────────────────────

  const CustomButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading    = false,
    this.fullWidth    = true,
    this.prefixIcon,
    this.suffixIcon,
    this.width,
    this.height       = 56,
    this.borderRadius = 14,
    this.fontSize     = 15,
    this.padding,
  }) : variant = ButtonVariant.primary;

  const CustomButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading    = false,
    this.fullWidth    = true,
    this.prefixIcon,
    this.suffixIcon,
    this.width,
    this.height       = 56,
    this.borderRadius = 14,
    this.fontSize     = 15,
    this.padding,
  }) : variant = ButtonVariant.secondary;

  const CustomButton.outlined({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading    = false,
    this.fullWidth    = true,
    this.prefixIcon,
    this.suffixIcon,
    this.width,
    this.height       = 56,
    this.borderRadius = 14,
    this.fontSize     = 15,
    this.padding,
  }) : variant = ButtonVariant.outlined;

  const CustomButton.ghost({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading    = false,
    this.fullWidth    = true,
    this.prefixIcon,
    this.suffixIcon,
    this.width,
    this.height       = 56,
    this.borderRadius = 14,
    this.fontSize     = 15,
    this.padding,
  }) : variant = ButtonVariant.ghost;

  const CustomButton.danger({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading    = false,
    this.fullWidth    = true,
    this.prefixIcon,
    this.suffixIcon,
    this.width,
    this.height       = 56,
    this.borderRadius = 14,
    this.fontSize     = 15,
    this.padding,
  }) : variant = ButtonVariant.danger;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    // ── Resolve colors per variant ───────────────────────────────
    final _ButtonStyle style = _resolveStyle(colors);

    final Widget child = isLoading
        ? SizedBox(
            width:  22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color:       style.foreground,
            ),
          )
        : Row(
            mainAxisSize:     MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (prefixIcon != null) ...[
                Icon(prefixIcon, color: style.foreground, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: GoogleFonts.poppins(
                  color:       style.foreground,
                  fontSize:    fontSize,
                  fontWeight:  FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              if (suffixIcon != null) ...[
                const SizedBox(width: 8),
                Icon(suffixIcon, color: style.foreground, size: 20),
              ],
            ],
          );

    final buttonChild = SizedBox(
      width:  fullWidth ? double.infinity : width,
      height: height,
      child: _buildButton(style, child, context),
    );

    return buttonChild;
  }

  Widget _buildButton(
    _ButtonStyle style,
    Widget child,
    BuildContext context,
  ) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      side: style.border ?? BorderSide.none,
    );

    final effectivePadding = padding ??
        const EdgeInsets.symmetric(horizontal: 24, vertical: 14);

    switch (variant) {
      case ButtonVariant.outlined:
      case ButtonVariant.ghost:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: style.background,
            foregroundColor: style.foreground,
            side:            style.border,
            shape:           RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding:  effectivePadding,
            elevation: 0,
          ),
          child: child,
        );

      default:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: style.background,
            foregroundColor: style.foreground,
            elevation:       style.elevation,
            shadowColor:     style.shadow,
            shape:           RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: effectivePadding,
          ),
          child: child,
        );
    }
  }

  _ButtonStyle _resolveStyle(AppThemeColors colors) {
    switch (variant) {
      // ── Gold bg + Black text — main luxury CTA ─────────────────
      case ButtonVariant.primary:
        return _ButtonStyle(
          background: colors.brandPrimary,
          foreground: AppPalette.secondary,     // black on gold
          elevation:  0,
          shadow:     colors.brandPrimary.withOpacity(0.30),
        );

      // ── Black bg + Gold text — strong secondary ─────────────────
      case ButtonVariant.secondary:
        return _ButtonStyle(
          background: AppPalette.secondary,
          foreground: colors.brandPrimary,      // gold on black
          elevation:  0,
          shadow:     Colors.black.withOpacity(0.30),
        );

      // ── Transparent + Gold border + Gold text ───────────────────
      case ButtonVariant.outlined:
        return _ButtonStyle(
          background: Colors.transparent,
          foreground: colors.brandPrimary,
          elevation:  0,
          border:     BorderSide(
            color: colors.brandPrimary,
            width: 1.5,
          ),
        );

      // ── Transparent + Gold text (no border) ─────────────────────
      case ButtonVariant.ghost:
        return _ButtonStyle(
          background: Colors.transparent,
          foreground: colors.brandPrimary,
          elevation:  0,
          border:     BorderSide.none,
        );

      // ── Error red + White text (destructive) ────────────────────
      case ButtonVariant.danger:
        return _ButtonStyle(
          background: colors.error,
          foreground: Colors.white,
          elevation:  0,
          shadow:     colors.error.withOpacity(0.30),
        );
    }
  }
}

// ── Internal style model ─────────────────────────────────────────────────────

class _ButtonStyle {
  final Color background;
  final Color foreground;
  final double elevation;
  final Color? shadow;
  final BorderSide? border;

  const _ButtonStyle({
    required this.background,
    required this.foreground,
    required this.elevation,
    this.shadow,
    this.border,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// GoldDivider — luxury horizontal divider with centered label
// ─────────────────────────────────────────────────────────────────────────────

class GoldDivider extends StatelessWidget {
  final String label;

  const GoldDivider({super.key, this.label = 'or'});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  colors.border,
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color:      colors.textSecondary,
              fontSize:   13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.border,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GoldIconButton — circular icon button with gold accent
// ─────────────────────────────────────────────────────────────────────────────

class GoldIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final bool filled;

  const GoldIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size   = 44,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width:  size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled
              ? colors.brandPrimary
              : colors.brandPrimary.withOpacity(0.10),
          border: Border.all(
            color: colors.brandPrimary.withOpacity(filled ? 0 : 0.30),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: filled ? AppPalette.secondary : colors.brandPrimary,
          size:  size * 0.45,
        ),
      ),
    );
  }
}
