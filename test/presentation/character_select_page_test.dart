import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:matchnotes/infrastructure/db/app_database.dart';
import 'package:matchnotes/infrastructure/providers.dart';
import 'package:matchnotes/presentation/character_select_page.dart';

void main() {
  group('CharacterSelectPage', () {
    testWidgets('shows empty hint and can add/edit/delete character', (
      tester,
    ) async {
      // Prepare in-memory DB and seed a game
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() async => db.close());
      await db.upsertGame(GamesCompanion.insert(id: 'g1', name: 'Game1'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
          child: const MaterialApp(home: CharacterSelectPage(gameId: 'g1')),
        ),
      );

      // Empty state (wait until async settles)
      await tester.pumpAndSettle();
      expect(find.text('キャラが未登録です'), findsOneWidget);
      expect(find.text('右下の + から追加してください'), findsOneWidget);

      // Add character via FAB and dialog
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Ryu');
      await tester.tap(find.text('追加'));
      await tester.pumpAndSettle();

      // List updated
      expect(find.text('Ryu'), findsOneWidget);

      // Rename via popup menu -> 名称変更 (locate menu inside the Ryu tile)
      final ryuTile = find.widgetWithText(ListTile, 'Ryu');
      final ryuMenu = find.descendant(
        of: ryuTile,
        matching: find.byType(PopupMenuButton),
      );
      expect(ryuMenu, findsOneWidget);
      await tester.tap(ryuMenu);
      await tester.pumpAndSettle();
      await tester.tap(find.text('名称変更'));
      await tester.pumpAndSettle();
      // Change name to Ryu2 and save
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, 'Ryu2');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      // Snackbar and updated item
      expect(find.text('更新しました'), findsOneWidget);
      expect(find.text('Ryu2'), findsOneWidget);

      // Delete via popup menu -> 削除 -> confirm (menu inside the Ryu2 tile)
      final ryu2Tile = find.widgetWithText(ListTile, 'Ryu2');
      final ryu2Menu = find.descendant(
        of: ryu2Tile,
        matching: find.byType(PopupMenuButton),
      );
      expect(ryu2Menu, findsOneWidget);
      await tester.tap(ryu2Menu);
      await tester.pumpAndSettle();
      await tester.tap(find.text('削除'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('削除'));
      await tester.pumpAndSettle();
      // Snackbar and item removed
      expect(find.text('削除しました'), findsOneWidget);
      expect(find.text('Ryu2'), findsNothing);

      // Unmount to cleanly dispose providers/streams
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pumpAndSettle();
    });
  });
}
