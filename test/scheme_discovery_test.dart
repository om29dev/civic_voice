import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice_interface/core/services/dynamodb_scheme_discovery_service.dart';
import 'package:civic_voice_interface/providers/scheme_discovery_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('DynamoDbSchemeDiscoveryService loads schemes from DynamoDB service',
      () async {
    final schemes = await DynamoDbSchemeDiscoveryService.loadSchemes();
    expect(schemes.isNotEmpty, isTrue);

    final first = schemes.first;
    expect(first.title.isNotEmpty, isTrue);
    expect(first.category.isNotEmpty, isTrue);
    expect(first.description.isNotEmpty, isTrue);
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

    // Test search
    provider.filterByCategory('All');
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
