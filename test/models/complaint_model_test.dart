import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice_interface/models/complaint_model.dart';

void main() {
  group('ComplaintModel tests', () {
    test('serializes and deserializes JSON successfully', () {
      final now = DateTime.now();
      final complaint = ComplaintModel(
        id: 'comp_101',
        userId: 'citizen_99',
        category: 'Infrastructure',
        description: 'Pothole on Main Road near Community Health Center',
        location: 'Sector 4, Rohini, Delhi',
        latitude: 28.7041,
        longitude: 77.1025,
        authorityEmail: 'pwd@delhi.gov.in',
        base64Image: 'sample_base64_payload',
        status: 'In Progress',
        submittedAt: now,
      );

      final json = complaint.toJson();
      final restored = ComplaintModel.fromJson(json);

      expect(restored.id, equals(complaint.id));
      expect(restored.userId, equals(complaint.userId));
      expect(restored.category, equals(complaint.category));
      expect(restored.description, equals(complaint.description));
      expect(restored.location, equals(complaint.location));
      expect(restored.latitude, equals(complaint.latitude));
      expect(restored.longitude, equals(complaint.longitude));
      expect(restored.authorityEmail, equals(complaint.authorityEmail));
      expect(restored.status, equals(complaint.status));
      expect(restored.submittedAt.millisecondsSinceEpoch,
          equals(complaint.submittedAt.millisecondsSinceEpoch));
    });

    test('handles missing optional fields with expected defaults', () {
      final minimalJson = {
        'id': 'comp_102',
        'user_id': 'citizen_100',
        'description': 'Water leak',
      };

      final complaint = ComplaintModel.fromJson(minimalJson);

      expect(complaint.id, equals('comp_102'));
      expect(complaint.userId, equals('citizen_100'));
      expect(complaint.category, equals('Other'));
      expect(complaint.location, equals('Unknown'));
      expect(complaint.status, equals('Pending'));
      expect(complaint.authorityEmail, isNull);
      expect(complaint.latitude, isNull);
      expect(complaint.longitude, isNull);
    });
  });
}

