import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:civic_voice_interface/widgets/cvi_button.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('CviButton widget tests', () {
    testWidgets('renders button text and triggers onPressed when tapped',
        (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CviButton(
              text: 'Apply for Scheme',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Apply for Scheme'), findsOneWidget);

      await tester.tap(find.text('Apply for Scheme'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('displays loading spinner and disables tap when loading is true',
        (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CviButton(
              text: 'Submit Application',
              loading: true,
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submit Application'), findsNothing);

      await tester.tap(find.byType(CircularProgressIndicator));
      await tester.pump();

      expect(tapped, isFalse);
    });

    testWidgets('renders icon when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CviButton(
              text: 'Verify Identity',
              icon: Icons.fingerprint,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.fingerprint), findsOneWidget);
      expect(find.text('Verify Identity'), findsOneWidget);
    });
  });
}
