// Basic smoke test for GS Doc.
//
// Verifies the app boots without throwing: it shows the loading indicator
// while the docs manifest asset loads, then settles without errors.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gsdoc/main.dart';

void main() {
  testWidgets('GsDoc launches without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(const GsDoc());

    // The manifest loads asynchronously, so the first frame shows a spinner.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
