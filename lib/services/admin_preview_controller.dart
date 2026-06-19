import 'package:flutter/foundation.dart';

class AdminPreviewController extends ChangeNotifier {
  bool _isPreviewMode = false;

  bool get isPreviewMode => _isPreviewMode;

  void enterPreviewMode() {
    if (_isPreviewMode) return;
    _isPreviewMode = true;
    notifyListeners();
  }

  void exitPreviewMode() {
    if (!_isPreviewMode) return;
    _isPreviewMode = false;
    notifyListeners();
  }

  void toggle() {
    _isPreviewMode = !_isPreviewMode;
    notifyListeners();
  }

  void reset() {
    if (!_isPreviewMode) return;
    _isPreviewMode = false;
    notifyListeners();
  }
}
