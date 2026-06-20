import 'package:flutter/material.dart';

class AppShimmerLoader extends StatelessWidget {
  final double height;
  final double width;
  final BorderRadius borderRadius;

  const AppShimmerLoader({
    super.key,
    this.height = 16,
    this.width = double.infinity,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.25, end: 0.9),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            color: Colors.grey.withOpacity(value * 0.25),
          ),
        );
      },
      onEnd: () {},
    );
  }
}
