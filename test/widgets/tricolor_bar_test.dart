import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice_interface/widgets/decorative/tricolor_bar.dart';

void main() {
  group('TricolorBar and TricolorDivider widget tests', () {
    testWidgets('renders TricolorBar with custom height and width',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TricolorBar(
              height: 4,
              width: 150,
            ),
          ),
        ),
      );

      final barFinder = find.byType(TricolorBar);
      expect(barFinder, findsOneWidget);

      final container = tester.widget<Container>(
        find.descendant(of: barFinder, matching: find.byType(Container)),
      );
      expect(container.constraints?.maxHeight, equals(4.0));
      expect(container.decoration, isNotNull);
      expect((container.decoration as BoxDecoration).gradient, isNotNull);
    });

    testWidgets('renders TricolorDivider with three dot indicators',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TricolorDivider(
              dotSize: 6,
              spacing: 8,
            ),
          ),
        ),
      );

      expect(find.byType(TricolorDivider), findsOneWidget);
      // TricolorDivider renders a Row with 3 decorated dot containers
      expect(find.byType(Container), findsNWidgets(3));
    });
  });
}
