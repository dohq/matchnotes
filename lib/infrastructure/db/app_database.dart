import 'package:drift/drift.dart';

part 'app_database.g.dart';

@DataClassName('DailyCharacterRecordRow')
class DailyCharacterRecords extends Table {
  TextColumn get gameId => text()();
  TextColumn get characterId => text()();
  // Store date at day precision as YYYYMMDD integer for simple comparisons
  IntColumn get yyyymmdd => integer()();
  IntColumn get wins => integer().withDefault(const Constant(0))();
  IntColumn get losses => integer().withDefault(const Constant(0))();
  TextColumn get memo => text().nullable()();

  @override
  Set<Column> get primaryKey => {gameId, characterId, yyyymmdd};
}

@DriftDatabase(tables: [DailyCharacterRecords])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      // Create all tables for version 1
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      // No-op for now since current schemaVersion is 1
      // Add incremental migrations here when bumping schemaVersion > 1
    },
    beforeOpen: (details) async {
      // Place for PRAGMA or seeding if needed
    },
  );

  // Helpers to convert DateTime <-> yyyymmdd
  static int toYyyymmdd(DateTime date) =>
      date.year * 10000 + date.month * 100 + date.day;

  // DAO helpers
  Future<DailyCharacterRecordRow?> fetchRecord({
    required String gameId,
    required String characterId,
    required DateTime day,
  }) async {
    final key = toYyyymmdd(day);
    final q = select(dailyCharacterRecords)
      ..where(
        (t) =>
            t.gameId.equals(gameId) &
            t.characterId.equals(characterId) &
            t.yyyymmdd.equals(key),
      )
      ..limit(1);
    final row = await q.getSingleOrNull();
    return row;
  }

  Future<List<DailyCharacterRecordRow>> fetchByGameAndDay({
    required String gameId,
    required DateTime day,
  }) async {
    final key = toYyyymmdd(day);
    final q = select(dailyCharacterRecords)
      ..where((t) => t.gameId.equals(gameId) & t.yyyymmdd.equals(key));
    return q.get();
  }

  Future<void> upsertRecord(Insertable<DailyCharacterRecordRow> row) async {
    await into(dailyCharacterRecords).insertOnConflictUpdate(row);
  }
}
