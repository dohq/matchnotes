import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:matchnotes/infrastructure/db/app_database.dart';
import 'package:matchnotes/infrastructure/repositories/daily_character_record_repository_drift.dart';
import 'package:matchnotes/domain/entities.dart' as domain;
import 'package:matchnotes/domain/usecases/add_win.dart';
import 'package:matchnotes/domain/usecases/add_loss.dart';
import 'package:matchnotes/domain/usecases/get_daily_game_summary.dart';
import 'package:matchnotes/domain/usecases/copy_memo_from_previous_day.dart';

void main() {
  group('E2E: drift repository with usecases', () {
    late AppDatabase db;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'AddWin/AddLoss + GetDailyGameSummary + CopyMemoFromPreviousDay',
      () async {
        final repo = DailyCharacterRecordRepositoryDrift(db);

        final addWin = AddWinUsecase(repo);
        final addLoss = AddLossUsecase(repo);
        final summary = GetDailyGameSummaryUsecase(repo);
        final copyMemo = CopyMemoFromPreviousDayUsecase(repo);

        final gameId = 'g1';
        final c1 = 'c1';
        final c2 = 'c2';

        final day = DateTime(2025, 9, 10, 12);

        await addWin.execute(gameId: gameId, characterId: c1, date: day);
        await addWin.execute(gameId: gameId, characterId: c1, date: day);
        await addLoss.execute(gameId: gameId, characterId: c1, date: day);

        await addWin.execute(gameId: gameId, characterId: c2, date: day);
        await addLoss.execute(gameId: gameId, characterId: c2, date: day);
        await addLoss.execute(gameId: gameId, characterId: c2, date: day);

        final s = await summary.execute(gameId: gameId, date: day);
        expect(s.wins, 3); // c1:2 + c2:1
        expect(s.losses, 3); // c1:1 + c2:2
        expect(s.winRate, 0.5);

        final prev = DateTime(2025, 9, 9);
        // manually insert previous day record with a memo
        final prevId = domain.DailyCharacterRecordId(
          gameId: gameId,
          characterId: c1,
          date: prev,
        );
        await repo.upsert(
          domain.DailyCharacterRecord(
            id: prevId,
            wins: 0,
            losses: 0,
            memo: 'memo-prev',
          ),
        );

        await copyMemo.execute(gameId: gameId, characterId: c1, date: day);

        final todayId = domain.DailyCharacterRecordId(
          gameId: gameId,
          characterId: c1,
          date: DateTime(2025, 9, 10),
        );
        final todayRec = await repo.findById(todayId);
        expect(todayRec, isNotNull);
        expect(todayRec!.memo, 'memo-prev');
      },
    );
  });
}
