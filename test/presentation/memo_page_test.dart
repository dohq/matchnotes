import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:matchnotes/infrastructure/db/app_database.dart';
import 'package:matchnotes/infrastructure/providers.dart';
import 'package:matchnotes/presentation/memo_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MemoPage', () {
    testWidgets('前日のメモをコピーして読み込む', (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() async => db.close());

      // Seed game/character and previous-day memo
      await db.upsertGame(GamesCompanion.insert(id: 'g1', name: 'G1'));
      await db.upsertCharacter(
        CharactersCompanion.insert(id: 'c1', gameId: 'g1', name: 'C1'),
      );
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final prev = today.subtract(const Duration(days: 1));
      await db.upsertRecord(
        DailyCharacterRecordsCompanion.insert(
          gameId: 'g1',
          characterId: 'c1',
          yyyymmdd: AppDatabase.toYyyymmdd(prev),
          wins: const Value(1),
          losses: const Value(0),
          memo: const Value('Prev'),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
          child: MaterialApp(
            home: MemoPage(gameId: 'g1', characterId: 'c1', date: today),
          ),
        ),
      );

      // Wait for initial load
      await tester.pumpAndSettle();
      // Initially empty since today has no memo
      final tf = find.byType(TextField).first;
      expect(tf, findsOneWidget);
      expect(find.text('Prev'), findsNothing);

      // Copy from previous day
      await tester.tap(find.text('前日のメモをコピー'));
      await tester.pumpAndSettle();

      // TextField now shows previous memo and snackbar appears
      expect(find.text('Prev'), findsOneWidget);
      expect(find.text('Copied from previous day.'), findsOneWidget);

      // DB has today record with memo
      final todayRows = await db.fetchByGameAndDay(gameId: 'g1', day: today);
      expect(todayRows.length, 1);
      expect(todayRows.single.memo, 'Prev');

      // Unmount
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  });
}
