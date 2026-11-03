import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice_interface/widgets/service_icon_tile.dart';

void main() {
  group('ServiceIconTile widget tests', () {
    testWidgets('renders icon with specified color and custom size',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ServiceIconTile(
              icon: Icons.account_balance,
              color: Color(0xFFFF6B1A),
              size: 64,
              iconSize: 32,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.account_balance), findsOneWidget);

      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.account_balance));
      expect(iconWidget.color, equals(const Color(0xFFFF6B1A)));
      expect(iconWidget.size, equals(32.0));
    });
  });
}

