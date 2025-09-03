import 'package:drift/drift.dart';

part 'app_database.g.dart';

@DataClassName('GameRow')
class Games extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {id};
}

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

@DriftDatabase(tables: [DailyCharacterRecords, Games])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      // Create all tables for version 1
      await m.createAll();
      // v2: If you add new indexes/columns later, also apply them here so
      // fresh installs at schemaVersion=2 have the same schema as upgraded ones.
      // v3: Games table added. createAll() already covers it for fresh installs.
    },
    onUpgrade: (m, from, to) async {
      // v2 placeholder: No structural changes yet.
      // Example for future changes:
      // if (from < 2) {
      //   await m.addColumn(dailyCharacterRecords, dailyCharacterRecords.memo);
      //   await m.createIndex(Index('idx_daily_game_day', [...]));
      // }
      if (from < 3) {
        // Create Games table for existing users upgrading to v3
        await m.createTable(games);
      }
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

  // Games DAO helpers
  Future<List<GameRow>> fetchAllGames() async {
    final q = select(games)..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return q.get();
  }

  Future<void> upsertGame(Insertable<GameRow> row) async {
    await into(games).insertOnConflictUpdate(row);
  }

  Stream<List<GameRow>> watchAllGames() {
    final q = select(games)..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return q.watch();
  }

  Future<void> renameGame({required String id, required String name}) async {
    await (update(games)..where((t) => t.id.equals(id))).write(GamesCompanion(
      name: Value(name),
    ));
  }

  Future<void> deleteGameAndRecords(String id) async {
    await transaction(() async {
      await (delete(dailyCharacterRecords)
            ..where((t) => t.gameId.equals(id)))
          .go();
      await (delete(games)..where((t) => t.id.equals(id))).go();
    });
  }

  // Range query for monthly aggregations
  Future<List<DailyCharacterRecordRow>> fetchByRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final s = toYyyymmdd(start);
    final e = toYyyymmdd(end);
    final q = select(dailyCharacterRecords)
      ..where((t) => t.yyyymmdd.isBetweenValues(s, e));
    return q.get();
  }
}
