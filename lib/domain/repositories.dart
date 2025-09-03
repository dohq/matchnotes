import 'entities.dart';

abstract class DailyCharacterRecordRepository {
  Future<DailyCharacterRecord?> findById(DailyCharacterRecordId id);
  Future<void> upsert(DailyCharacterRecord record);
}
