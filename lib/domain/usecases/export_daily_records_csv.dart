import 'dart:io';

import 'package:csv/csv.dart';
import 'package:matchnotes/domain/repositories.dart';

class ExportDailyRecordsCsvUsecase {
  final DailyCharacterRecordRepository repo;
  ExportDailyRecordsCsvUsecase(this.repo);

  /// Exports records in [start..end] (inclusive) to CSV.
  /// Columns: game_id,character_id,yyyymmdd,wins,losses (LF, no memo)
  /// Returns the written file.
  Future<File> execute({
    DateTime? start,
    DateTime? end,
    required Directory targetDir,
  }) async {
    final s = start ?? DateTime(1970, 1, 1);
    final e = end ?? DateTime(2100, 12, 31);
    final rows = await repo.findByRange(start: s, end: e);

    // Sort for stable output
    rows.sort((a, b) {
      final c1 = a.id.gameId.compareTo(b.id.gameId);
      if (c1 != 0) return c1;
      final c2 = a.id.characterId.compareTo(b.id.characterId);
      if (c2 != 0) return c2;
      return a.id.date.compareTo(b.id.date);
    });

    final output = <List<dynamic>>[];
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

    final csv = const ListToCsvConverter(eol: '\n').convert(output);
    final fileName = 'matchnotes_export_${_yyyymmddOf(DateTime.now())}.csv';
    final file = File('${targetDir.path}/$fileName');
    await file.writeAsString(csv);
    return file;
  }

  int _yyyymmddOf(DateTime d) => d.year * 10000 + d.month * 100 + d.day;
}
