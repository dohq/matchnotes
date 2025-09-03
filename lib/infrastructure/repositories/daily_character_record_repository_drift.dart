import 'package:drift/drift.dart' as d;
import 'package:matchnotes/domain/entities.dart' as domain;
import 'package:matchnotes/domain/repositories.dart';

import '../db/app_database.dart';

class DailyCharacterRecordRepositoryDrift
    implements DailyCharacterRecordRepository {
  final AppDatabase db;
  DailyCharacterRecordRepositoryDrift(this.db);

  static int _toYyyymmdd(DateTime d) =>
      AppDatabase.toYyyymmdd(DateTime(d.year, d.month, d.day));
  static DateTime _fromYyyymmdd(int v) =>
      DateTime(v ~/ 10000, (v % 10000) ~/ 100, v % 100);

  domain.DailyCharacterRecord _mapRow(DailyCharacterRecordRow row) {
    return domain.DailyCharacterRecord(
      id: domain.DailyCharacterRecordId(
        gameId: row.gameId,
        characterId: row.characterId,
        date: _fromYyyymmdd(row.yyyymmdd),
      ),
      wins: row.wins,
      losses: row.losses,
      memo: row.memo,
    );
  }

  DailyCharacterRecordsCompanion _toCompanion(
    domain.DailyCharacterRecord record,
  ) {
    return DailyCharacterRecordsCompanion(
      gameId: d.Value(record.id.gameId),
      characterId: d.Value(record.id.characterId),
      yyyymmdd: d.Value(_toYyyymmdd(record.id.date)),
      wins: d.Value(record.wins),
      losses: d.Value(record.losses),
      memo: d.Value(record.memo),
    );
  }

  @override
  Future<domain.DailyCharacterRecord?> findById(
    domain.DailyCharacterRecordId id,
  ) async {
    final row = await db.fetchRecord(
      gameId: id.gameId,
      characterId: id.characterId,
      day: id.date,
    );
    return row == null ? null : _mapRow(row);
  }

  @override
  Future<void> upsert(domain.DailyCharacterRecord record) async {
    await db.upsertRecord(_toCompanion(record));
  }

  @override
  Future<List<domain.DailyCharacterRecord>> findByGameAndDay({
    required String gameId,
    required DateTime day,
  }) async {
    final rows = await db.fetchByGameAndDay(gameId: gameId, day: day);
    return rows.map(_mapRow).toList(growable: false);
  }

  @override
  Future<List<domain.DailyCharacterRecord>> findByRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final rows = await db.fetchByRange(start: start, end: end);
    return rows.map(_mapRow).toList(growable: false);
  }
}
