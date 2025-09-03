import '../entities.dart';
import '../repositories.dart';

class CopyMemoFromPreviousDayUsecase {
  final DailyCharacterRecordRepository repo;
  CopyMemoFromPreviousDayUsecase(this.repo);

  Future<void> execute({
    required String gameId,
    required String characterId,
    required DateTime date,
  }) async {
    final today = DateTime(date.year, date.month, date.day);
    final prev = today.subtract(const Duration(days: 1));

    final prevId = DailyCharacterRecordId(
      gameId: gameId,
      characterId: characterId,
      date: prev,
    );
    final todayId = DailyCharacterRecordId(
      gameId: gameId,
      characterId: characterId,
      date: today,
    );

    final prevRec = await repo.findById(prevId);
    if (prevRec == null || prevRec.memo == null) {
      return; // nothing to copy
    }

    final todayRec = await repo.findById(todayId);
    if (todayRec == null) {
      await repo.upsert(
        DailyCharacterRecord(
          id: todayId,
          wins: 0,
          losses: 0,
          memo: prevRec.memo,
        ),
      );
      return;
    }

    // Only set memo if not already present
    if (todayRec.memo == null) {
      await repo.upsert(
        DailyCharacterRecord(
          id: todayRec.id,
          wins: todayRec.wins,
          losses: todayRec.losses,
          memo: prevRec.memo,
        ),
      );
    }
  }
}
