import 'dart:io';

import 'package:csv/csv.dart';
import 'package:matchnotes/domain/repositories.dart';
import 'package:matchnotes/infrastructure/db/app_database.dart';
import 'package:matchnotes/infrastructure/logging/logger.dart';

class ExportDailyRecordsCsvUsecase {
  final DailyCharacterRecordRepository repo;
  final AppDatabase? db; // optional: if null, export legacy 5-column CSV
  ExportDailyRecordsCsvUsecase(this.repo, [this.db]);

  /// Exports records in [start..end] (inclusive) to CSV.
  /// Columns:
  /// - when db != null: game_id,character_id,game_name,character_name,yyyymmdd,wins,losses
  /// - when db == null: game_id,character_id,yyyymmdd,wins,losses (legacy)
  /// Returns the written file.
  Future<File> execute({
    DateTime? start,
    DateTime? end,
    required Directory targetDir,
  }) async {
    final s = start ?? DateTime(1970, 1, 1);
    final e = end ?? DateTime(2100, 12, 31);
    final rows = await repo.findByRange(start: s, end: e);
    logCsv.info(
      'export CSV start range=${_yyyymmddOf(s)}..${_yyyymmddOf(e)} rows=${rows.length}',
    );
    Map<String, String> gameName = const {};
    Map<String, String> charName = const {};
    if (db != null) {
      final games = await db!.fetchAllGames();
      gameName = {for (final g in games) g.id: g.name};
      final chars = await db!.fetchAllCharacters();
      charName = {for (final c in chars) c.id: c.name};
    }

    // Sort for stable output
    rows.sort((a, b) {
      final c1 = a.id.gameId.compareTo(b.id.gameId);
      if (c1 != 0) return c1;
      final c2 = a.id.characterId.compareTo(b.id.characterId);
      if (c2 != 0) return c2;
      return a.id.date.compareTo(b.id.date);
    });

    final output = <List<dynamic>>[];
    final useNames = db != null;
    if (useNames) {
      output.add([
        'game_id',
        'character_id',
        'game_name',
        'character_name',
        'yyyymmdd',
        'wins',
        'losses',
      ]);
      for (final r in rows) {
        output.add([
          r.id.gameId,
          r.id.characterId,
          gameName[r.id.gameId] ?? r.id.gameId,
          charName[r.id.characterId] ?? r.id.characterId,
          _yyyymmddOf(r.id.date),
          r.wins,
          r.losses,
        ]);
      }
    } else {
      output.add(['game_id', 'character_id', 'yyyymmdd', 'wins', 'losses']);
      for (final r in rows) {
        output.add([
          r.id.gameId,
          r.id.characterId,
          _yyyymmddOf(r.id.date),
          r.wins,
          r.losses,
        ]);
      }
    }

    final csv = const ListToCsvConverter(eol: '\n').convert(output);
    final fileName = 'matchnotes_export_${_yyyymmddOf(DateTime.now())}.csv';
    final file = File('${targetDir.path}/$fileName');
    await file.writeAsString(csv);
    logCsv.info('export CSV done path=${file.path} bytes=${csv.length}');
    return file;
  }

  int _yyyymmddOf(DateTime d) => d.year * 10000 + d.month * 100 + d.day;
}
