import '../entities.dart';
import '../repositories.dart';
import 'package:matchnotes/infrastructure/logging/logger.dart';

class AddLossUsecase {
  final DailyCharacterRecordRepository repo;
  AddLossUsecase(this.repo);

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
        wins: 0,
        losses: 1,
        memo: null,
      );
      await repo.upsert(created);
      logUsecase.info('addLoss new game=$gameId char=$characterId day=${day.toIso8601String()}');
    } else {
      final updated = existing.copyWith(losses: existing.losses + 1);
      await repo.upsert(updated);
      logUsecase.info('addLoss update game=$gameId char=$characterId day=${day.toIso8601String()} losses=${updated.losses}');
    }
  }
}
