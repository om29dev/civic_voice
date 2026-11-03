import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice_interface/widgets/loading_overlay.dart';

void main() {
  group('LoadingOverlay widget tests', () {
    testWidgets('renders custom loading message and progress indicator',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingOverlay(
              text: 'Authenticating citizen credentials...',
            ),
          ),
        ),
      );

      // Advance one animation tick
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Authenticating citizen credentials...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}

