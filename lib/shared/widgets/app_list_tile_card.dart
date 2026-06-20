import 'package:flutter/material.dart';
import 'package:pfb/shared/widgets/app_surface_card.dart';

class AppListTileCard extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry contentPadding;
  final EdgeInsetsGeometry? margin;

  const AppListTileCard({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.contentPadding = const EdgeInsets.all(12),
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      margin: margin,
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: ListTile(
        contentPadding: contentPadding,
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
      ),
    );
  }
}
