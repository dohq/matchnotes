import 'entities.dart';

abstract class DailyCharacterRecordRepository {
  Future<DailyCharacterRecord?> findById(DailyCharacterRecordId id);
  Future<void> upsert(DailyCharacterRecord record);
  Future<List<DailyCharacterRecord>> findByGameAndDay({
    required String gameId,
    required DateTime day,
  });
  Future<List<DailyCharacterRecord>> findByRange({
    required DateTime start,
    required DateTime end,
  });
}
