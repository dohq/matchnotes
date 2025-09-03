import 'package:flutter_test/flutter_test.dart';
import 'package:matchnotes/domain/entities.dart';
import 'package:matchnotes/domain/repositories.dart';
import 'package:matchnotes/domain/usecases/get_daily_game_summary.dart';

class InMemoryDailyCharacterRecordRepo
    implements DailyCharacterRecordRepository {
  final Map<DailyCharacterRecordId, DailyCharacterRecord> _store = {};

  @override
  Future<DailyCharacterRecord?> findById(DailyCharacterRecordId id) async =>
      _store[id];

  @override
  Future<void> upsert(DailyCharacterRecord record) async {
    _store[record.id] = record;
  }

  @override
  Future<List<DailyCharacterRecord>> findByGameAndDay({
    required String gameId,
    required DateTime day,
  }) async {
    final d = DateTime(day.year, day.month, day.day);
    return _store.entries
        .where(
          (e) =>
              e.key.gameId == gameId &&
              e.key.date.year == d.year &&
              e.key.date.month == d.month &&
              e.key.date.day == d.day,
        )
        .map((e) => e.value)
        .toList(growable: false);
  }

  @override
  Future<List<DailyCharacterRecord>> findByRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return _store.entries
        .where((entry) {
          final d = entry.key.date;
          final dd = DateTime(d.year, d.month, d.day);
          return (dd.isAfter(s) || dd.isAtSameMomentAs(s)) &&
              (dd.isBefore(e) || dd.isAtSameMomentAs(e));
        })
        .map((e) => e.value)
        .toList(growable: false);
  }
}

void main() {
  group('GetDailyGameSummaryUsecase', () {
    test('returns 0/0 (null rate) when no records for the day', () async {
      final repo = InMemoryDailyCharacterRecordRepo();
      final usecase = GetDailyGameSummaryUsecase(repo);
      final sum = await usecase.execute(
        gameId: 'g1',
        date: DateTime(2025, 9, 3, 10),
      );
      expect(sum.wins, 0);
      expect(sum.losses, 0);
      expect(sum.winRate, isNull);
    });

    test('sums wins/losses across characters for game/day', () async {
      final repo = InMemoryDailyCharacterRecordRepo();
      final usecase = GetDailyGameSummaryUsecase(repo);
      final day = DateTime(2025, 9, 3);
      await repo.upsert(
        DailyCharacterRecord(
          id: DailyCharacterRecordId(
            gameId: 'g1',
            characterId: 'c1',
            date: day,
          ),
          wins: 2,
          losses: 1,
          memo: 'a',
        ),
      );
      await repo.upsert(
        DailyCharacterRecord(
          id: DailyCharacterRecordId(
            gameId: 'g1',
            characterId: 'c2',
            date: day,
          ),
          wins: 1,
          losses: 2,
          memo: 'b',
        ),
      );
      // Different day or different game should not count
      await repo.upsert(
        DailyCharacterRecord(
          id: DailyCharacterRecordId(
            gameId: 'g2',
            characterId: 'cX',
            date: day,
          ),
          wins: 5,
          losses: 5,
          memo: null,
        ),
      );
      await repo.upsert(
        DailyCharacterRecord(
          id: DailyCharacterRecordId(
            gameId: 'g1',
            characterId: 'c3',
            date: DateTime(2025, 9, 4),
          ),
          wins: 9,
          losses: 9,
          memo: null,
        ),
      );

      final sum = await usecase.execute(
        gameId: 'g1',
        date: DateTime(2025, 9, 3, 23, 59),
      );
      expect(sum.wins, 3);
      expect(sum.losses, 3);
      expect(sum.winRate, 0.5);
    });
  });
}
