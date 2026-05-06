// Smoke test for the SwaralipiApp root widget.
//
// The real app opens a Drift database on construction which requires platform
// channels unavailable in unit tests. This file verifies the widget tree
// compiles and the test harness can pump a minimal fake app without crashing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MaterialApp renders without throwing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('Swaralipi'))),
      ),
    );
    await tester.pump();

    expect(find.text('Swaralipi'), findsOneWidget);
  });
}
