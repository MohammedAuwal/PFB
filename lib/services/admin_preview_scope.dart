import 'package:flutter/widgets.dart';
import 'package:pfb/services/admin_preview_controller.dart';

class AdminPreviewScope extends InheritedNotifier<AdminPreviewController> {
  const AdminPreviewScope({
    super.key,
    required AdminPreviewController controller,
    required Widget child,
  }) : super(notifier: controller, child: child);

  static AdminPreviewController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AdminPreviewScope>();
    assert(scope != null, 'No AdminPreviewScope found in context');
    return scope!.notifier!;
  }
}
