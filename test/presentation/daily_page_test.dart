import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:matchnotes/infrastructure/db/app_database.dart';
import 'package:matchnotes/infrastructure/providers.dart';
import 'package:matchnotes/presentation/daily_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DailyPage', () {
    testWidgets('サマリ/レコードの表示、勝敗追加、メモ保存/コピー', (tester) async {
      // 画面を少し広く
      await tester.binding.setSurfaceSize(const Size(900, 1400));
      addTearDown(() async => tester.binding.setSurfaceSize(null));

      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() async => db.close());

      // デフォルトのIDに合わせて投入
      await db.upsertGame(GamesCompanion.insert(id: 'demo-game', name: 'Demo'));
      await db.upsertCharacter(
        CharactersCompanion.insert(
          id: 'char-1',
          gameId: 'demo-game',
          name: 'C1',
        ),
      );
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final prev = today.subtract(const Duration(days: 1));
      await db.upsertRecord(
        DailyCharacterRecordsCompanion.insert(
          gameId: 'demo-game',
          characterId: 'char-1',
          yyyymmdd: AppDatabase.toYyyymmdd(today),
          wins: const Value(1),
          losses: const Value(2),
          memo: const Value.absent(),
        ),
      );
      await db.upsertRecord(
        DailyCharacterRecordsCompanion.insert(
          gameId: 'demo-game',
          characterId: 'char-1',
          yyyymmdd: AppDatabase.toYyyymmdd(prev),
          wins: const Value(0),
          losses: const Value(0),
          memo: const Value('PrevMemo'),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
          child: const MaterialApp(home: DailyPage()),
        ),
      );

      await tester.pumpAndSettle();

      // Summary 表示（1勝2敗 -> 0.33）
      expect(find.textContaining('Summary: wins=1, losses=2'), findsOneWidget);

      // Record 行
      final dateText =
          '${today.year.toString().padLeft(4, '0')}-'
          '${today.month.toString().padLeft(2, '0')}-'
          '${today.day.toString().padLeft(2, '0')}';
      expect(
        find.text('Record (demo-game/char-1 @ $dateText): wins=1, losses=2'),
        findsOneWidget,
      );

      // まず前日コピー（初期は null のためコピーされる）
      await tester.tap(find.text('Copy Memo from Previous Day'));
      await tester.pumpAndSettle();
      var tf = tester.widget<TextField>(find.byType(TextField).last);
      expect(tf.controller?.text, 'PrevMemo');

      // メモ入力 -> 保存
      await tester.enterText(find.byType(TextField).last, 'Hello');
      await tester.tap(find.text('Save Memo'));
      await tester.pumpAndSettle();
      // DB反映確認
      final recToday = await db.fetchRecord(
        gameId: 'demo-game',
        characterId: 'char-1',
        day: today,
      );
      expect(recToday?.memo, 'Hello');

      // 勝ちを追加
      await tester.tap(find.text('Add Win'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Summary: wins=2, losses=2'), findsOneWidget);

      // 保存後のテキスト確認
      tf = tester.widget<TextField>(find.byType(TextField).last);
      expect(tf.controller?.text, 'Hello');
    });
  });
}
