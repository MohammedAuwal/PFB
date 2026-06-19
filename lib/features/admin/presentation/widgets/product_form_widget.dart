import 'package:flutter/material.dart';
import 'package:pfb/shared/widgets/app_surface_card.dart';

class ProductFormWidget extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const ProductFormWidget({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: padding,
      borderRadius: BorderRadius.circular(22),
      child: child,
    );
  }
}
