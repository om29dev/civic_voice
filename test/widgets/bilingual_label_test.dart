import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:civic_voice_interface/providers/language_provider.dart';
import 'package:civic_voice_interface/widgets/bilingual_label.dart';

class TestableLanguageProvider extends LanguageProvider {
  String _code = 'en';

  @override
  String get languageCode => _code;

  void setTestCode(String code) {
    _code = code;
    notifyListeners();
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('BilingualLabel widget tests', () {
    testWidgets('displays English text when language is English', (WidgetTester tester) async {
      final languageProvider = TestableLanguageProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<LanguageProvider>.value(
              value: languageProvider,
              child: const BilingualLabel(
                englishText: 'Welcome Citizen',
                hindiText: 'नागरिक का स्वागत है',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Welcome Citizen'), findsOneWidget);
      expect(find.text('नागरिक का स्वागत है'), findsNothing);
    });

    testWidgets('displays Hindi text when language is Hindi', (WidgetTester tester) async {
      final languageProvider = TestableLanguageProvider()..setTestCode('hi');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<LanguageProvider>.value(
              value: languageProvider,
              child: const BilingualLabel(
                englishText: 'Welcome Citizen',
                hindiText: 'नागरिक का स्वागत है',
              ),
            ),
          ),
        ),
      );

      expect(find.text('नागरिक का स्वागत है'), findsOneWidget);
      expect(find.text('Welcome Citizen'), findsNothing);
    });
  });
}

