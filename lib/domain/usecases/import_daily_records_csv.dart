import 'dart:io';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart' show Value;
import 'package:matchnotes/domain/repositories.dart';
import 'package:matchnotes/domain/entities.dart';
import 'package:matchnotes/infrastructure/db/app_database.dart';

class ImportDailyRecordsCsvUsecase {
  final DailyCharacterRecordRepository repo;
  final AppDatabase db;
  ImportDailyRecordsCsvUsecase(this.repo, this.db);

  /// Imports records from a CSV file.
  /// Expected header: game_id,character_id,yyyymmdd,wins,losses
  /// Lines ending: LF assumed.
  /// Returns number of imported rows.
  Future<int> execute({required File file}) async {
    final r = await executeWithReport(file: file);
    return r.imported;
  }

  /// Detailed report version for UI: imported/skipped and errors with line numbers.
  Future<ImportResult> executeWithReport({required File file}) async {
    final content = await file.readAsString();
    final rows = const CsvToListConverter(eol: '\n').convert(content);
    if (rows.isEmpty) {
      return ImportResult(imported: 0, skipped: 0, errors: const []);
    }

    // Validate header
    final header = rows.first.map((e) => e.toString()).toList(growable: false);
    if (header.length < 5 ||
        header[0] != 'game_id' ||
        header[1] != 'character_id' ||
        header[2] != 'yyyymmdd' ||
        header[3] != 'wins' ||
        header[4] != 'losses') {
      throw FormatException('CSV header mismatch');
    }

    // cache known gameIds
    final known = <String>{for (final g in await db.fetchAllGames()) g.id};

    var imported = 0;
    var skipped = 0;
    final errors = <String>[];
    for (var i = 1; i < rows.length; i++) {
      final r = rows[i];
      if (r.length < 5) {
        skipped++;
        errors.add('line ${i + 1}: 列数が不足しています');
        continue;
      }
      final gameId = r[0].toString().trim();
      final characterId = r[1].toString().trim();
      final yyyymmdd = int.tryParse(r[2].toString());
      final wins = int.tryParse(r[3].toString());
      final losses = int.tryParse(r[4].toString());

      if (gameId.isEmpty || characterId.isEmpty) {
        skipped++;
        errors.add('line ${i + 1}: game_id または character_id が空です');
        continue;
      }
      if (yyyymmdd == null || wins == null || losses == null) {
        skipped++;
        errors.add('line ${i + 1}: 数値項目の形式が不正です');
        continue;
      }
      if (wins < 0 || losses < 0) {
        skipped++;
        errors.add('line ${i + 1}: wins または losses が負の値です');
        continue;
      }
      final date = _safeDateFromYyyymmdd(yyyymmdd);
      if (date == null) {
        skipped++;
        errors.add('line ${i + 1}: yyyymmdd が不正な日付です');
        continue;
      }

      // ensure game exists in master
      if (!known.contains(gameId)) {
        await db.upsertGame(
          GamesCompanion(id: Value(gameId), name: Value(gameId)),
        );
        known.add(gameId);
      }

      final record = DailyCharacterRecord(
        id: DailyCharacterRecordId(
          gameId: gameId,
          characterId: characterId,
          date: date,
        ),
        wins: wins,
        losses: losses,
        memo: '', // CSVには含めない
      );
      await repo.upsert(record);
      imported++;
    }
    return ImportResult(imported: imported, skipped: skipped, errors: errors);
  }

  DateTime? _safeDateFromYyyymmdd(int v) {
    final y = v ~/ 10000;
    final m = (v % 10000) ~/ 100;
    final d = v % 100;
    try {
      final dt = DateTime(y, m, d);
      if (dt.year == y && dt.month == m && dt.day == d) {
        return dt;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

class ImportResult {
  final int imported;
  final int skipped;
  final List<String> errors;
  ImportResult({
    required this.imported,
    required this.skipped,
    required this.errors,
  });
}
