import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice_interface/core/constants/app_language.dart';

void main() {
  group('AppLanguage tests', () {
    test('fromCode returns correct enum for supported codes', () {
      expect(AppLanguage.fromCode('en'), equals(AppLanguage.english));
      expect(AppLanguage.fromCode('hi'), equals(AppLanguage.hindi));
      expect(AppLanguage.fromCode('mr'), equals(AppLanguage.marathi));
      expect(AppLanguage.fromCode('ta'), equals(AppLanguage.tamil));
    });

    test('fromCode defaults to English for unknown code', () {
      expect(AppLanguage.fromCode('unknown'), equals(AppLanguage.english));
      expect(AppLanguage.fromCode(''), equals(AppLanguage.english));
      expect(AppLanguage.fromCode('fr'), equals(AppLanguage.english));
    });

    test('code and label properties match expected values', () {
      expect(AppLanguage.english.code, equals('en'));
      expect(AppLanguage.english.label, equals('English'));

      expect(AppLanguage.hindi.code, equals('hi'));
      expect(AppLanguage.hindi.label, equals('हिन्दी'));

      expect(AppLanguage.marathi.code, equals('mr'));
      expect(AppLanguage.marathi.label, equals('मराठी'));

      expect(AppLanguage.tamil.code, equals('ta'));
      expect(AppLanguage.tamil.label, equals('தமிழ்'));
    });

    test('toString returns the native label', () {
      expect(AppLanguage.english.toString(), equals('English'));
      expect(AppLanguage.hindi.toString(), equals('हिन्दी'));
      expect(AppLanguage.marathi.toString(), equals('मराठी'));
      expect(AppLanguage.tamil.toString(), equals('தமிழ்'));
    });
  });
}

