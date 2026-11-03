import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice_interface/core/services/offline_mode_service.dart';

void main() {
  group('OfflineModeService tests', () {
    final service = OfflineModeService();

    test('processQuery matches helpline for pension scheme', () {
      final response = service.processQuery('what is the helpline number for pension?');
      expect(response, contains('Old Age Pension'));
      expect(response, contains('1800-180-1551'));
    });

    test('processQuery returns general emergency when helpline not found', () {
      final response = service.processQuery('contact number for space rocket');
      expect(response, contains('112'));
    });

    test('processQuery provides steps for known scheme', () {
      final response = service.processQuery('how to apply for pension step by step');
      expect(response, contains('Old Age Pension'));
      expect(response, contains('Document Preparation'));
    });

    test('processQuery provides documents required for pension', () {
      final response = service.processQuery('documents required for pension');
      expect(response, contains('Old Age Pension'));
      expect(response, contains('Aadhaar Card'));
    });

    test('processQuery falls back to offline guidance on general queries', () {
      final response = service.processQuery('tell me about cricket scores');
      expect(response, contains('Offline Mode'));
    });
  });
}

