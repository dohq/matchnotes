import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:matchnotes/domain/entities.dart';
import 'package:matchnotes/domain/usecases/get_monthly_win_rates_per_game.dart';
import 'package:matchnotes/infrastructure/db/app_database.dart';

import 'fakes.dart';

void main() {
  group('GetMonthlyWinRatesPerGameUsecase', () {
    test('aggregates by game/day and per character with names', () async {
      final repo = FakeDailyCharacterRecordRepository();
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() async => db.close());

      // games and characters
      await db.upsertGame(
        GamesCompanion(id: const Value('g1'), name: const Value('Game One')),
      );
      await db.upsertGame(
        GamesCompanion(id: const Value('g2'), name: const Value('Game Two')),
      );

      await db.upsertCharacter(
        CharactersCompanion.insert(id: 'c1', gameId: 'g1', name: 'Ryu'),
      );
      await db.upsertCharacter(
        CharactersCompanion.insert(id: 'c2', gameId: 'g1', name: 'Ken'),
      );

      // month data (Jan 2025)
      final d1 = DateTime(2025, 1, 1);
      final d2 = DateTime(2025, 1, 2);
      // g1, day1: c1 1-0, c2 0-2 => total 1/3 => 0.3333
      await repo.upsert(
        DailyCharacterRecord(
          id: DailyCharacterRecordId(gameId: 'g1', characterId: 'c1', date: d1),
          wins: 1,
          losses: 0,
          memo: null,
        ),
      );
      await repo.upsert(
        DailyCharacterRecord(
          id: DailyCharacterRecordId(gameId: 'g1', characterId: 'c2', date: d1),
          wins: 0,
          losses: 2,
          memo: null,
        ),
      );
      // g1, day2: c1 2-2 => total 2/4 => 0.5
      await repo.upsert(
        DailyCharacterRecord(
          id: DailyCharacterRecordId(gameId: 'g1', characterId: 'c1', date: d2),
          wins: 2,
          losses: 2,
          memo: null,
        ),
      );
      // g2, day2 only: 3-1 => 0.75
      await repo.upsert(
        DailyCharacterRecord(
          id: DailyCharacterRecordId(gameId: 'g2', characterId: 'cx', date: d2),
          wins: 3,
          losses: 1,
          memo: null,
        ),
      );

      final usecase = GetMonthlyWinRatesPerGameUsecase(repo, db);
      final series = await usecase.execute(DateTime(2025, 1, 15));

      // Should have both games, sorted by gameName asc: Game One then Game Two
      expect(series.length, 2);
      expect(series[0].gameId, 'g1');
      expect(series[0].gameName, 'Game One');
      expect(series[1].gameId, 'g2');
      expect(series[1].gameName, 'Game Two');

      // g1 points for 2 days
      final g1 = series[0];
      expect(g1.points.length, 2);
      expect(g1.points[0].day, d1);
      expect(g1.points[0].wins, 1);
      expect(g1.points[0].losses, 2);
      expect((g1.points[0].winRate - (1 / 3)).abs() < 1e-9, isTrue);
      // by character names resolved
      expect(g1.points[0].byCharacter['Ryu']?.wins, 1);
      expect(g1.points[0].byCharacter['Ken']?.losses, 2);

      expect(g1.points[1].day, d2);
      expect(g1.points[1].wins, 2);
      expect(g1.points[1].losses, 2);
      expect((g1.points[1].winRate - 0.5).abs() < 1e-9, isTrue);

      // g2 has only one day point
      final g2 = series[1];
      expect(g2.points.length, 1);
      expect(g2.points[0].day, d2);
      expect(g2.points[0].wins, 3);
      expect(g2.points[0].losses, 1);
      expect((g2.points[0].winRate - 0.75).abs() < 1e-9, isTrue);
    });
  });
}
