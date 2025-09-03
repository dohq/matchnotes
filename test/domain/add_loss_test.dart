import 'package:flutter_test/flutter_test.dart';
import 'package:matchnotes/domain/entities.dart';
import 'package:matchnotes/domain/repositories.dart';
import 'package:matchnotes/domain/usecases/add_loss.dart';

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
}

void main() {
  group('AddLossUsecase', () {
    test(
      'creates new record with losses=1 when none exists for that day/character',
      () async {
        final repo = InMemoryDailyCharacterRecordRepo();
        final usecase = AddLossUsecase(repo);
        final date = DateTime(2025, 9, 1, 12, 34);

        await usecase.execute(gameId: 'g1', characterId: 'c1', date: date);

        final id = DailyCharacterRecordId(
          gameId: 'g1',
          characterId: 'c1',
          date: DateTime(2025, 9, 1),
        );
        final rec = await repo.findById(id);
        expect(rec, isNotNull);
        expect(rec!.wins, 0);
        expect(rec.losses, 1);
        expect(rec.memo, isNull);
      },
    );

    test('increments losses when record exists', () async {
      final repo = InMemoryDailyCharacterRecordRepo();
      final usecase = AddLossUsecase(repo);
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
      expect(rec!.wins, 2);
      expect(rec.losses, 2);
      expect(rec.memo, 'note');
    });
  });
}
