import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice_interface/core/services/reasoning_engine.dart';

void main() {
  group('SmartIntentParser reasoning engine tests', () {
    test('detects pension scheme and process intent from English prompt', () {
      final result = SmartIntentParser.parse('how to apply for old age pension', 'en');
      expect(result.schemeId, equals('pension'));
      expect(result.intent, equals(Intent.process));
      expect(result.confidence, greaterThan(0.0));
    });

    test('detects pm-kisan scheme and documents intent from English query', () {
      final result = SmartIntentParser.parse('what are the required documents for kisan scheme', 'en');
      expect(result.schemeId, equals('pm-kisan'));
      expect(result.intent, equals(Intent.documents));
    });

    test('detects eligibility intent for ayushman health insurance', () {
      final result = SmartIntentParser.parse('am i eligible for ayushman health insurance', 'en');
      expect(result.schemeId, equals('ayushman'));
      expect(result.intent, equals(Intent.eligibility));
    });

    test('detects Hindi keywords for ration documents', () {
      final result = SmartIntentParser.parse('राशन कार्ड के लिए जरूरी दस्तावेज', 'hi');
      expect(result.schemeId, equals('ration'));
      expect(result.intent, equals(Intent.documents));
    });

    test('falls back to discovery intent for unmapped queries', () {
      final result = SmartIntentParser.parse('show me any citizen services', 'en');
      expect(result.intent, equals(Intent.discovery));
      expect(result.schemeId, isNull);
    });
  });
}

