import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:civic_voice_interface/providers/accessibility_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AccessibilityProvider tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('initializes with accessibility defaults', () {
      final provider = AccessibilityProvider();
      expect(provider.isHighContrast, isFalse);
      expect(provider.textScaleFactor, equals(1.0));
      expect(provider.colorBlindMode, equals(ColorBlindMode.none));
      expect(provider.colorFilter, isNull);
    });

    test('toggleHighContrast updates value and persists preference', () async {
      final provider = AccessibilityProvider();
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.toggleHighContrast(true);

      expect(provider.isHighContrast, isTrue);
      expect(notifyCount, greaterThan(0));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('acc_high_contrast'), isTrue);
    });

    test('setTextScale adjusts scale factor', () async {
      final provider = AccessibilityProvider();
      await provider.setTextScale(1.3);

      expect(provider.textScaleFactor, equals(1.3));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('acc_text_scale'), equals(1.3));
    });

    test('setColorBlindMode provides active matrix filter when enabled', () async {
      final provider = AccessibilityProvider();

      await provider.setColorBlindMode(ColorBlindMode.protanopia);
      expect(provider.colorBlindMode, equals(ColorBlindMode.protanopia));
      expect(provider.colorFilter, isNotNull);

      await provider.setColorBlindMode(ColorBlindMode.none);
      expect(provider.colorBlindMode, equals(ColorBlindMode.none));
      expect(provider.colorFilter, isNull);
    });
  });
}

