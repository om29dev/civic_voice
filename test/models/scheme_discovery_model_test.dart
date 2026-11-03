import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice_interface/models/scheme_discovery_model.dart';

void main() {
  group('SchemeDiscoveryModel tests', () {
    test('parses full scheme JSON correctly', () {
      final json = {
        'id': 'scheme_ayushman_bharat',
        'title': 'Ayushman Bharat PM-JAY',
        'description': 'Health insurance coverage up to 5 lakh rupees per family per year.',
        'category': 'Health & Wellness',
        'eligibility_criteria': ['Vulnerable rural families', 'Deprivation categories'],
        'application_process': 'Visit nearest empaneled hospital with Aadhaar.',
        'short_title': 'PM-JAY',
        'level': 'Central',
        'scheme_for': 'Economically weaker citizens',
        'beneficiary_state': 'All India',
        'nodal_ministry': 'Ministry of Health and Family Welfare',
        'tags': ['health', 'insurance', 'hospital', 'cashless'],
      };

      final scheme = SchemeDiscoveryModel.fromJson(json);

      expect(scheme.id, equals('scheme_ayushman_bharat'));
      expect(scheme.title, equals('Ayushman Bharat PM-JAY'));
      expect(scheme.category, equals('Health & Wellness'));
      expect(scheme.eligibilityCriteria.length, equals(2));
      expect(scheme.shortTitle, equals('PM-JAY'));
      expect(scheme.level, equals('Central'));
      expect(scheme.tags, contains('cashless'));
    });

    test('handles missing optional fields with sensible fallbacks', () {
      final minimalJson = {
        'id': 'scheme_basic',
        'title': 'Basic Citizen Service',
        'description': 'Description text',
      };

      final scheme = SchemeDiscoveryModel.fromJson(minimalJson);

      expect(scheme.id, equals('scheme_basic'));
      expect(scheme.title, equals('Basic Citizen Service'));
      expect(scheme.category, equals('General'));
      expect(scheme.eligibilityCriteria, isEmpty);
      expect(scheme.applicationProcess, isEmpty);
      expect(scheme.tags, isEmpty);
    });

    test('toJson produces expected map structure', () {
      final scheme = SchemeDiscoveryModel(
        id: 'scheme_kisan',
        title: 'PM Kisan Samman Nidhi',
        description: 'Direct income support of 6000 per year',
        category: 'Agriculture',
        eligibilityCriteria: ['Small and marginal farmers'],
        applicationProcess: 'Apply online through pmkisan.gov.in',
        tags: ['farmer', 'income'],
      );

      final json = scheme.toJson();

      expect(json['id'], equals('scheme_kisan'));
      expect(json['title'], equals('PM Kisan Samman Nidhi'));
      expect(json['category'], equals('Agriculture'));
      expect(json['eligibility_criteria'], contains('Small and marginal farmers'));
      expect(json['tags'], contains('farmer'));
    });
  });
}

