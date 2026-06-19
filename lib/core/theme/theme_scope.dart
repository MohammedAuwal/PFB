import 'package:flutter/widgets.dart';
import 'package:pfb/core/theme/app_theme.dart';
import 'theme_controller.dart';

class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({
    super.key,
    required ThemeController controller,
    required Widget child,
  }) : super(notifier: controller, child: child);

  static ThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, 'ThemeScope not found in widget tree');
    return scope!.notifier!;
  }

  static AppThemeColors colorsOf(BuildContext context) {
    return AppTheme.colorsOf(context);
  }
}
