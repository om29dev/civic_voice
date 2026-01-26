import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ColorBlindMode { none, protanopia, deuteranopia, tritanopia }

class AccessibilityProvider with ChangeNotifier {
  static const String _highContrastKey = 'acc_high_contrast';
  static const String _textScaleKey = 'acc_text_scale';
  static const String _colorBlindKey = 'acc_color_blind';

  bool _isHighContrast = false;
  double _textScaleFactor = 1.0;
  ColorBlindMode _colorBlindMode = ColorBlindMode.none;

  bool get isHighContrast => _isHighContrast;
  double get textScaleFactor => _textScaleFactor;
  ColorBlindMode get colorBlindMode => _colorBlindMode;

  AccessibilityProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isHighContrast = prefs.getBool(_highContrastKey) ?? false;
    _textScaleFactor = prefs.getDouble(_textScaleKey) ?? 1.0;
    _colorBlindMode = ColorBlindMode.values[prefs.getInt(_colorBlindKey) ?? 0];
    notifyListeners();
  }

  Future<void> toggleHighContrast(bool value) async {
    _isHighContrast = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_highContrastKey, value);
    notifyListeners();
  }

  Future<void> setTextScale(double value) async {
    _textScaleFactor = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_textScaleKey, value);
    notifyListeners();
  }

  Future<void> setColorBlindMode(ColorBlindMode mode) async {
    _colorBlindMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_colorBlindKey, mode.index);
    notifyListeners();
  }

  // Returns a ColorFilter based on the selected mode
  ColorFilter? get colorFilter {
    switch (_colorBlindMode) {
      case ColorBlindMode.protanopia:
        return const ColorFilter.matrix([
          0.567, 0.433, 0.0, 0.0, 0.0,
          0.558, 0.442, 0.0, 0.0, 0.0,
          0.0, 0.242, 0.758, 0.0, 0.0,
          0.0, 0.0, 0.0, 1.0, 0.0,
        ]);
      case ColorBlindMode.deuteranopia:
        return const ColorFilter.matrix([
          0.625, 0.375, 0.0, 0.0, 0.0,
          0.7, 0.3, 0.0, 0.0, 0.0,
          0.0, 0.3, 0.7, 0.0, 0.0,
          0.0, 0.0, 0.0, 1.0, 0.0,
        ]);
      case ColorBlindMode.tritanopia:
        return const ColorFilter.matrix([
          0.95, 0.05, 0.0, 0.0, 0.0,
          0.0, 0.433, 0.567, 0.0, 0.0,
          0.0, 0.475, 0.525, 0.0, 0.0,
          0.0, 0.0, 0.0, 1.0, 0.0,
        ]);
      default:
        return null;
    }
  }
}
