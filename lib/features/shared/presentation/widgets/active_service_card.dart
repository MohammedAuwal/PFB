import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/shared/widgets/app_status_chip.dart';
import 'package:pfb/shared/widgets/app_surface_card.dart';
import 'package:pfb/core/theme/build_context_theme_x.dart';

class ActiveServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? status;
  final String? eta;
  final String? trailingText;
  final VoidCallback? onTap;

  const ActiveServiceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.status,
    this.eta,
    this.trailingText,
    this.onTap,
  });

  AppStatusChipTone _statusTone(String? value) {
    final status = (value ?? '').toLowerCase();

    if (status.contains('completed') || status.contains('delivered')) {
      return AppStatusChipTone.success;
    }
    if (status.contains('cancelled')) {
      return AppStatusChipTone.error;
    }
    if (status.contains('progress')) {
      return AppStatusChipTone.info;
    }
    if (status.contains('way') || status.contains('searching')) {
      return AppStatusChipTone.warning;
    }
    return AppStatusChipTone.primary;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GestureDetector(
      onTap: onTap,
      child: AppSurfaceCard(
        padding: const EdgeInsets.all(14),
        borderRadius: BorderRadius.circular(18),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: colors.brandPrimary,
              child: Icon(
                icon,
                color: colors.iconOnDarkTint,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: colors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  if (status != null) ...[
                    const SizedBox(height: 6),
                    AppStatusChip(
                      label: status!,
                      tone: _statusTone(status),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (eta != null)
                  Text(
                    eta!,
                    style: GoogleFonts.poppins(
                      color: colors.brandPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (trailingText != null)
                  Text(
                    trailingText!,
                    style: GoogleFonts.poppins(
                      color: colors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
