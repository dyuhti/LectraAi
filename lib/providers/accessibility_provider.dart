import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AccessibilityProvider extends ChangeNotifier {
  bool _isEnabled = false;
  String _screenText = '';
  Object? _lastRouteToken;
  int _lastPriority = -1;

  bool get isEnabled => _isEnabled;
  String get screenText => _screenText;

  void toggle(bool value) {
    _isEnabled = value;
    if (!value) {
      _lastRouteToken = null;
      _lastPriority = -1;
    }
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

  void setScreenTextIfCurrent(
    BuildContext context,
    String value, {
    int priority = 0,
  }) {
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) {
      return;
    }

    final routeToken = route ?? context;
    if (!identical(_lastRouteToken, routeToken)) {
      _lastRouteToken = routeToken;
      _lastPriority = -1;
    }

    if (priority < _lastPriority) {
      return;
    }

    _lastPriority = priority;

    setScreenText(value);
  }
}