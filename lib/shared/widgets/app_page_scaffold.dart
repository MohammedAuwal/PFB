import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/core/theme/app_theme.dart';
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
    this.safeArea    = false,
    this.centerTitle = false,
    this.customAppBar,
    this.backgroundColor,
    this.drawer,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark  = context.isDarkMode;

    return Scaffold(
      backgroundColor: backgroundColor ?? colors.scaffold,
      drawer:          drawer,
      appBar: customAppBar ??
          PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: Container(
              decoration: BoxDecoration(
                color: colors.scaffold,
                border: Border(
                  bottom: BorderSide(
                    color: AppPalette.primary.withOpacity(
                      isDark ? 0.20 : 0.10,
                    ),
                    width: 1,
                  ),
                ),
              ),
              child: AppBar(
                centerTitle: centerTitle,
                backgroundColor: Colors.transparent,
                elevation:       0,
                scrolledUnderElevation: 0,
                title: Text(
                  title,
                  style: GoogleFonts.poppins(
                    color:      colors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize:   18,
                  ),
                ),
                iconTheme: IconThemeData(color: colors.iconPrimary),
                actions:   actions,
              ),
            ),
          ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar:  bottomNavigationBar,
      body: safeArea ? SafeArea(child: body) : body,
    );
  }
}