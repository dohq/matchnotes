// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matchnotes/main.dart';

void main() {
  testWidgets('TopPage smoke test', (WidgetTester tester) async {
    // Build app
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    // Avoid waiting for async providers to settle in smoke test
    await tester.pump();

    // App bar title
    expect(find.text('MatchNotes'), findsOneWidget);

    // Keep smoke test minimal
  });
}
