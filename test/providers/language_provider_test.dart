import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:civic_voice_interface/providers/language_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LanguageProvider tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({'cvi_language': 'en'});
    });

    test('initializes with default English language configuration', () {
      final provider = LanguageProvider();
      expect(provider.currentLanguage, equals('en'));
      expect(provider.languageCode, equals('en'));
      expect(provider.currentLocale, equals(const Locale('en', 'IN')));
      expect(provider.currentLanguageName, equals('English'));
      expect(provider.fullLocaleId, equals('en-IN'));
    });

    test('supportedLanguages contains 4 core regional languages', () {
      expect(LanguageProvider.supportedLanguages.length, equals(4));

      final codes = LanguageProvider.supportedLanguages.map((l) => l['code']).toList();
      expect(codes, contains('en'));
      expect(codes, contains('hi'));
      expect(codes, contains('mr'));
      expect(codes, contains('ta'));
    });

    test('translateSync returns original text for English immediately', () {
      final provider = LanguageProvider();
      expect(provider.translateSync('Home'), equals('Home'));
      expect(provider.translateSync(''), equals(''));
    });
  });
}

