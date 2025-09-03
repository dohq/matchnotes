import 'package:flutter_test/flutter_test.dart';
import 'package:matchnotes/domain/entities.dart';
import 'package:matchnotes/domain/repositories.dart';
import 'package:matchnotes/domain/usecases/copy_memo_from_previous_day.dart';

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
  group('CopyMemoFromPreviousDayUsecase', () {
    test(
      'copies previous day memo into today (create if today missing)',
      () async {
        final repo = InMemoryDailyCharacterRecordRepo();
        final usecase = CopyMemoFromPreviousDayUsecase(repo);
        final today = DateTime(2025, 9, 5, 9, 30);
        final prev = DateTime(2025, 9, 4);
        final prevId = DailyCharacterRecordId(
          gameId: 'g1',
          characterId: 'c1',
          date: prev,
        );
        await repo.upsert(
          DailyCharacterRecord(
            id: prevId,
            wins: 2,
            losses: 3,
            memo: 'keep-this',
          ),
        );

        await usecase.execute(gameId: 'g1', characterId: 'c1', date: today);

        final todayId = DailyCharacterRecordId(
          gameId: 'g1',
          characterId: 'c1',
          date: DateTime(2025, 9, 5),
        );
        final rec = await repo.findById(todayId);
        expect(rec, isNotNull);
        expect(rec!.memo, 'keep-this');
        // new record gets wins/losses default 0
        expect(rec.wins, 0);
        expect(rec.losses, 0);
      },
    );

    test('does not overwrite today memo if already exists', () async {
      final repo = InMemoryDailyCharacterRecordRepo();
      final usecase = CopyMemoFromPreviousDayUsecase(repo);
      final today = DateTime(2025, 9, 6);
      final prev = DateTime(2025, 9, 5);
      await repo.upsert(
        DailyCharacterRecord(
          id: DailyCharacterRecordId(
            gameId: 'g1',
            characterId: 'c1',
            date: prev,
          ),
          wins: 1,
          losses: 1,
          memo: 'yesterday',
        ),
      );
      final todayId = DailyCharacterRecordId(
        gameId: 'g1',
        characterId: 'c1',
        date: today,
      );
      await repo.upsert(
        DailyCharacterRecord(
          id: todayId,
          wins: 5,
          losses: 4,
          memo: 'today-note',
        ),
      );

      await usecase.execute(gameId: 'g1', characterId: 'c1', date: today);

      final rec = await repo.findById(todayId);
      expect(rec, isNotNull);
      // Memo should remain unchanged
      expect(rec!.memo, 'today-note');
      // Wins/Losses remain
      expect(rec.wins, 5);
      expect(rec.losses, 4);
    });

    test('no-op when previous day record missing or memo is null', () async {
      final repo = InMemoryDailyCharacterRecordRepo();
      final usecase = CopyMemoFromPreviousDayUsecase(repo);
      final today = DateTime(2025, 9, 7);
      // create prev with null memo
      final prevId = DailyCharacterRecordId(
        gameId: 'g1',
        characterId: 'c1',
        date: DateTime(2025, 9, 6),
      );
      await repo.upsert(
        DailyCharacterRecord(id: prevId, wins: 0, losses: 0, memo: null),
      );

      await usecase.execute(gameId: 'g1', characterId: 'c1', date: today);

      final todayId = DailyCharacterRecordId(
        gameId: 'g1',
        characterId: 'c1',
        date: DateTime(2025, 9, 7),
      );
      final rec = await repo.findById(todayId);
      // Should not create a new record since prev memo is null
      expect(rec, isNull);
    });
  });
}
