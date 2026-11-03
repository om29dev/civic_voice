import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:civic_voice_interface/providers/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeProvider tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('initializes with default system theme', () {
      final provider = ThemeProvider();
      expect(provider.themeMode, equals(ThemeMode.system));
      expect(provider.isDarkMode, isFalse);
    });

    test('setThemeMode updates themeMode and triggers notification', () async {
      final provider = ThemeProvider();
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.setThemeMode(ThemeMode.dark);

      expect(provider.themeMode, equals(ThemeMode.dark));
      expect(provider.isDarkMode, isTrue);
      expect(notifyCount, greaterThan(0));

      // Check SharedPreferences persistence
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), equals('dark'));
    });

    test('toggleTheme alternates between light and dark modes', () async {
      final provider = ThemeProvider();
      await provider.setThemeMode(ThemeMode.light);
      expect(provider.isDarkMode, isFalse);

      provider.toggleTheme();
      expect(provider.isDarkMode, isTrue);

      provider.toggleTheme();
      expect(provider.isDarkMode, isFalse);
    });
  });
}

