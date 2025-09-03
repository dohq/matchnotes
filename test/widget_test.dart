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
  testWidgets('Demo screen smoke test', (WidgetTester tester) async {
    // Build app
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    // App bar title
    expect(find.text('Matchnotes Demo'), findsOneWidget);

    // Buttons exist
    expect(find.text('Add Win (c1)'), findsOneWidget);
    expect(find.text('Add Loss (c2)'), findsOneWidget);
    expect(find.text('Refresh Summary'), findsOneWidget);

    // Initial summary text exists
    expect(find.textContaining('Summary:'), findsOneWidget);
  });
}
