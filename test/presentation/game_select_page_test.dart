import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:matchnotes/infrastructure/db/app_database.dart';
import 'package:matchnotes/infrastructure/providers.dart';
import 'package:matchnotes/presentation/game_select_page.dart';

void main() {
  group('GameSelectPage', () {
    testWidgets('shows empty hint when no games', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            watchAllGamesProvider.overrideWith((ref) async* {
              yield <GameRow>[];
            }),
          ],
          child: const MaterialApp(home: GameSelectPage()),
        ),
      );
      await tester.pump();
      expect(find.text('ゲームがありません。右下の + から追加'), findsOneWidget);
      // Unmount to ensure providers/streams are disposed cleanly
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pumpAndSettle();
    });

    testWidgets('can add a new game via FAB and dialog', (tester) async {
      // Prepare in-memory DB and override appDatabaseProvider so other providers use it
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() async => db.close());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWith((ref) async => db),
            // watchAllGamesProvider は appDatabase を参照する実装をそのまま使用
          ],
          child: const MaterialApp(home: GameSelectPage()),
        ),
      );

      // Initially no games
      await tester.pump();
      expect(find.text('ゲームがありません。右下の + から追加'), findsOneWidget);

      // Tap FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Enter name in dialog and confirm
      await tester.enterText(find.byType(TextField).first, 'My Game');
      await tester.tap(find.text('追加'));
      await tester.pumpAndSettle();

      // SnackBar shows
      expect(find.text('追加しました'), findsOneWidget);

      // List should now contain the new game name
      await tester.pump();
      expect(find.text('My Game'), findsOneWidget);

      // Unmount to ensure providers/streams are disposed cleanly
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pumpAndSettle();
    });
  });
}
