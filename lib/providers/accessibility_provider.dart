import 'package:flutter/foundation.dart';

class AccessibilityProvider extends ChangeNotifier {
  bool _isEnabled = false;
  String _screenText = '';

  bool get isEnabled => _isEnabled;
  String get screenText => _screenText;

  void toggle(bool value) {
    _isEnabled = value;
    notifyListeners();
  }

  void setScreenText(String value) {
    final normalized = value.trim();
    if (_screenText == normalized) {
      return;
    }

    _screenText = normalized;
    notifyListeners();
  }
}