import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:civic_voice_interface/core/services/dynamodb_scheme_discovery_service.dart';
import 'package:civic_voice_interface/providers/scheme_discovery_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('DynamoDbSchemeDiscoveryService loads schemes from DynamoDB service',
      () async {
    final schemes = await DynamoDbSchemeDiscoveryService.loadSchemes();
    expect(schemes.isNotEmpty, isTrue);

    final first = schemes.first;
    expect(first.title.isNotEmpty, isTrue);
    expect(first.category.isNotEmpty, isTrue);
    expect(first.description.isNotEmpty, isTrue);
  });

  test('DynamoDbSchemeDiscoveryService.enrichDynamoItem infers demographic rules',
      () {
    final rawDynamoItem = {
      'id': 'scheme-00001',
      'title': 'Post Matric Scholarship for SC Students in Maharashtra',
      'shortTitle': 'PMS-SC-MH',
      'description':
          'Financial scholarship for Scheduled Caste college students from BPL / low income families aged 16 to 30 years.',
      'category': 'Education & Learning',
      'level': 'State',
      'schemeFor': 'Individual',
      'beneficiaryState': 'Maharashtra',
      'nodalMinistry': 'Social Justice Department',
      'tags': ['Scholarship', 'SC', 'Education'],
    };

    final enriched =
        DynamoDbSchemeDiscoveryService.enrichDynamoItem(rawDynamoItem);
    expect(enriched, isNotNull);
    expect(enriched!.beneficiaryState, equals('Maharashtra'));
    expect(enriched.targetCastes, contains('SC'));
    expect(enriched.targetOccupations, contains('Student'));
    expect(
      enriched.matchesDemographics(
        state: 'Maharashtra',
        casteCategory: 'SC',
        occupation: 'Student',
        age: 20,
        income: 100000,
      ),
      isTrue,
    );
    expect(
      enriched.matchesDemographics(
        state: 'Karnataka',
        casteCategory: 'SC',
        occupation: 'Student',
      ),
      isFalse,
    );
  });

  test('SchemeDiscoveryProvider filters and searches DynamoDB schemes correctly',
      () async {
    final provider = SchemeDiscoveryProvider();
    await provider.loadSchemes();

    expect(provider.allSchemes.isNotEmpty, isTrue);
    expect(provider.filteredSchemes.isNotEmpty, isTrue);
    expect(provider.categories.contains('All'), isTrue);

    // Test category filter
    provider.filterByCategory('Education & Learning');
    for (final s in provider.filteredSchemes) {
      expect(
        s.category.toLowerCase().contains('education') ||
            s.category.toLowerCase().contains('learning'),
        isTrue,
      );
    }

    // Test demographic state filter (includes Maharashtra + All India Central schemes)
    provider.clearAllFilters();
    provider.updateFilters(state: 'Maharashtra');
    expect(provider.filteredSchemes.isNotEmpty, isTrue);
    for (final s in provider.filteredSchemes) {
      expect(s.matchesState('Maharashtra'), isTrue);
    }

    // Test search
    provider.clearAllFilters();
    provider.searchSchemes('Kisan');
    expect(provider.filteredSchemes.isNotEmpty, isTrue);
    for (final s in provider.filteredSchemes) {
      final matches = s.title.toLowerCase().contains('kisan') ||
          s.description.toLowerCase().contains('kisan') ||
          s.tags.any((t) => t.toLowerCase().contains('kisan'));
      expect(matches, isTrue);
    }
  });
}
