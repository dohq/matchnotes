import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:matchnotes/infrastructure/db/app_database.dart';
import 'package:matchnotes/infrastructure/providers.dart';
import 'package:matchnotes/presentation/register_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock platform channels used in this page
  final wakelockChannel = const MethodChannel('wakelock_plus');

  setUp(() async {
    // Avoid MissingPluginException from Wakelock and Haptics
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(wakelockChannel, (_) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(wakelockChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('RegisterPage', () {
    testWidgets('初期表示と勝/負/Undoの更新、メモ表示/編集', (tester) async {
      // 画面サイズを広げてオーバーフロー/ヒットミスを回避
      await tester.binding.setSurfaceSize(const Size(900, 1400));
      addTearDown(() async => tester.binding.setSurfaceSize(null));
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() async => db.close());

      // Seed game/character and today record
      await db.upsertGame(GamesCompanion.insert(id: 'g1', name: 'G1'));
      await db.upsertCharacter(
        CharactersCompanion.insert(id: 'c1', gameId: 'g1', name: 'C1'),
      );
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      await db.upsertRecord(
        DailyCharacterRecordsCompanion.insert(
          gameId: 'g1',
          characterId: 'c1',
          yyyymmdd: AppDatabase.toYyyymmdd(today),
          wins: const Value(2),
          losses: const Value(3),
          memo: const Value('  Hello  '),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
          child: const MaterialApp(
            home: RegisterPage(gameId: 'g1', characterId: 'c1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Header info
      final dateText =
          '${today.year.toString().padLeft(4, '0')}-'
          '${today.month.toString().padLeft(2, '0')}-'
          '${today.day.toString().padLeft(2, '0')}';
      expect(find.text(dateText), findsOneWidget);
      expect(find.text('G1 / C1'), findsOneWidget);

      // Stats
      expect(find.text('合計'), findsOneWidget);
      expect(find.text('勝'), findsOneWidget);
      expect(find.text('負'), findsOneWidget);
      expect(find.text('5'), findsOneWidget); // total = 2+3
      expect(
        find.text('2'),
        findsWidgets,
      ); // wins appears in tile and elsewhere
      expect(find.text('3'), findsWidgets);

      // Memo shows trimmed content
      expect(find.text('Hello'), findsOneWidget);

      // +1 win
      await tester.tap(find.text('勝 +1'));
      await tester.pumpAndSettle();
      expect(find.text('6'), findsOneWidget); // total
      expect(find.text('3'), findsWidgets); // wins updated to 3

      // Undo
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(find.text('5'), findsOneWidget); // back to total 5
      expect(find.text('2'), findsWidgets); // wins back to 2

      // +1 loss
      await tester.tap(find.text('負 +1'));
      await tester.pumpAndSettle();
      expect(find.text('6'), findsOneWidget); // total 6
      // losses becomes 4; there may be other "4" in tree, so check tile context
      expect(find.text('4'), findsWidgets);

      // Edit memo via MemoPage and return
      await tester.tap(find.text('メモの編集'));
      await tester.pumpAndSettle();
      final tf = find.byType(TextField).first;
      await tester.enterText(tf, 'New memo');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(find.text('New memo'), findsOneWidget);

      // Unmount to clean up
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  });
}
