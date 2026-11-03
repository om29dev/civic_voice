import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice_interface/core/services/emergency_service.dart';

void main() {
  group('EmergencyService disaster guides tests', () {
    final service = EmergencyService();

    test('provides disaster guides for common emergencies', () {
      expect(service.guides.isNotEmpty, isTrue);

      final titles = service.guides.map((g) => g.title).toList();
      expect(titles, contains('Earthquake'));
      expect(titles, contains('Flood'));
      expect(titles, contains('Fire'));
    });

    test('each disaster guide includes actionable do and dont steps', () {
      for (final guide in service.guides) {
        expect(guide.title.isNotEmpty, isTrue);
        expect(guide.doSteps.isNotEmpty, isTrue);
        expect(guide.dontSteps.isNotEmpty, isTrue);
        expect(guide.iconAsset.isNotEmpty, isTrue);
      }
    });

    test('Earthquake guide contains safety drop and hold instructions', () {
      final earthquakeGuide = service.guides.firstWhere((g) => g.title == 'Earthquake');
      expect(earthquakeGuide.doSteps.any((s) => s.contains('Drop, Cover, and Hold')), isTrue);
      expect(earthquakeGuide.dontSteps.any((s) => s.contains('elevators')), isTrue);
    });
  });
}

