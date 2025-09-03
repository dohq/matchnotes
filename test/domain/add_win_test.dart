import 'package:flutter_test/flutter_test.dart';
import 'package:matchnotes/domain/entities.dart';
import 'package:matchnotes/domain/repositories.dart';
import 'package:matchnotes/domain/usecases/add_win.dart';

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
  group('AddWinUsecase', () {
    test(
      'creates new record with wins=1 when none exists for that day/character',
      () async {
        final repo = InMemoryDailyCharacterRecordRepo();
        final usecase = AddWinUsecase(repo);
        final date = DateTime(
          2025,
          9,
          1,
          12,
          34,
        ); // time portion should be ignored

        await usecase.execute(gameId: 'g1', characterId: 'c1', date: date);

        final id = DailyCharacterRecordId(
          gameId: 'g1',
          characterId: 'c1',
          date: DateTime(2025, 9, 1),
        );
        final rec = await repo.findById(id);
        expect(rec, isNotNull);
        expect(rec!.wins, 1);
        expect(rec.losses, 0);
        expect(rec.memo, isNull);
      },
    );

    test('increments wins when record exists', () async {
      final repo = InMemoryDailyCharacterRecordRepo();
      final usecase = AddWinUsecase(repo);
      final date = DateTime(2025, 9, 2, 8, 0);
      final id = DailyCharacterRecordId(
        gameId: 'g1',
        characterId: 'c1',
        date: DateTime(2025, 9, 2),
      );
      await repo.upsert(
        DailyCharacterRecord(id: id, wins: 2, losses: 1, memo: 'note'),
      );

      await usecase.execute(gameId: 'g1', characterId: 'c1', date: date);

      final rec = await repo.findById(id);
      expect(rec, isNotNull);
      expect(rec!.wins, 3);
      expect(rec.losses, 1);
      expect(rec.memo, 'note'); // memo preserved
    });
  });
}
