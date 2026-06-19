import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/core/theme/build_context_theme_x.dart';

class AppPageScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool safeArea;
  final bool centerTitle;
  final PreferredSizeWidget? customAppBar;
  final Color? backgroundColor;
  final Widget? drawer;

  const AppPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.safeArea = false,
    this.centerTitle = false,
    this.customAppBar,
    this.backgroundColor,
    this.drawer,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: backgroundColor ?? colors.scaffold,
      drawer: drawer,
      appBar: customAppBar ??
          AppBar(
            centerTitle: centerTitle,
            title: Text(
              title,
              style: GoogleFonts.poppins(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: actions,
          ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: safeArea ? SafeArea(child: body) : body,
    );
  }
}
