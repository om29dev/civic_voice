import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice_interface/models/cvi_document_model.dart';

void main() {
  group('DocumentType extension tests', () {
    test('provides English labels for Indian civic documents', () {
      expect(DocumentType.aadhaar.label, equals('Aadhaar Card'));
      expect(DocumentType.pan.label, equals('PAN Card'));
      expect(DocumentType.voterID.label, equals('Voter ID'));
      expect(DocumentType.rationCard.label, equals('Ration Card'));
      expect(DocumentType.drivingLicense.label, equals('Driving License'));
      expect(DocumentType.incomeCertificate.label, equals('Income Certificate'));
    });

    test('provides Hindi labels for localization', () {
      expect(DocumentType.aadhaar.labelHindi, equals('आधार कार्ड'));
      expect(DocumentType.pan.labelHindi, equals('पैन कार्ड'));
      expect(DocumentType.rationCard.labelHindi, equals('राशन कार्ड'));
      expect(DocumentType.birthCertificate.labelHindi, equals('जन्म प्रमाणपत्र'));
    });
  });
}

