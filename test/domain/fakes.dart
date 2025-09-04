import 'package:matchnotes/domain/repositories.dart';
import 'package:matchnotes/domain/entities.dart';

class FakeDailyCharacterRecordRepository
    implements DailyCharacterRecordRepository {
  final Map<DailyCharacterRecordId, DailyCharacterRecord> _store = {};

  @override
  Future<DailyCharacterRecord?> findById(DailyCharacterRecordId id) async {
    return _store[id];
  }

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
    return _store.values
        .where((r) => r.id.gameId == gameId && _isSameDay(r.id.date, d))
        .toList();
  }

  @override
  Future<List<DailyCharacterRecord>> findByRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return _store.values
        .where(
          (r) =>
              r.id.date.isAfter(s.subtract(const Duration(days: 1))) &&
              r.id.date.isBefore(e.add(const Duration(days: 1))),
        )
        .toList();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<DailyCharacterRecord> dump() => _store.values.toList();
}
