// Smoke test for the SwaralipiApp root widget.
//
// Verifies that the app renders without throwing and that the placeholder
// home screen is visible. This test will be replaced once the real
// navigation shell is implemented.

import 'package:flutter_test/flutter_test.dart';

import 'package:swaralipi/main.dart';

void main() {
  testWidgets('SwaralipiApp renders placeholder home', (tester) async {
    await tester.pumpWidget(const SwaralipiApp());
    await tester.pump();

    expect(find.text('Swaralipi'), findsOneWidget);
    expect(find.text('App under construction'), findsOneWidget);
  });
}
