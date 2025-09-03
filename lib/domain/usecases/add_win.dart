import '../entities.dart';
import '../repositories.dart';

class AddWinUsecase {
  final DailyCharacterRecordRepository repo;
  AddWinUsecase(this.repo);

  Future<void> execute({
    required String gameId,
    required String characterId,
    required DateTime date,
  }) async {
    final day = DateTime(date.year, date.month, date.day);
    final id = DailyCharacterRecordId(
      gameId: gameId,
      characterId: characterId,
      date: day,
    );
    final existing = await repo.findById(id);
    if (existing == null) {
      final created = DailyCharacterRecord(
        id: id,
        wins: 1,
        losses: 0,
        memo: null,
      );
      await repo.upsert(created);
    } else {
      final updated = existing.copyWith(wins: existing.wins + 1);
      await repo.upsert(updated);
    }
  }
}
