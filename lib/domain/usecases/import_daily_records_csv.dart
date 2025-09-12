import 'dart:io';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart' show Value;
import 'package:matchnotes/domain/repositories.dart';
import 'package:matchnotes/domain/entities.dart';
import 'package:matchnotes/infrastructure/db/app_database.dart';
import 'package:matchnotes/infrastructure/logging/logger.dart';

class ImportDailyRecordsCsvUsecase {
  final DailyCharacterRecordRepository repo;
  final AppDatabase db;
  ImportDailyRecordsCsvUsecase(this.repo, this.db);

  /// Imports records from a CSV file.
  /// Expected header (two variants):
  /// - legacy: game_id,character_id,yyyymmdd,wins,losses
  /// - extended: game_id,character_id,game_name,character_name,yyyymmdd,wins,losses
  /// Lines ending: LF assumed.
  /// Returns number of imported rows.
  Future<int> execute({required File file}) async {
    final r = await executeWithReport(file: file);
    return r.imported;
  }

  /// Detailed report version for UI: imported/skipped and errors with line numbers.
  Future<ImportResult> executeWithReport({required File file}) async {
    final content = await file.readAsString();
    logCsv.info('import CSV start path=${file.path} size=${content.length}');
    final rows = const CsvToListConverter(eol: '\n').convert(content);
    if (rows.isEmpty) {
      logCsv.warning('import CSV: empty file');
      return ImportResult(imported: 0, skipped: 0, errors: const []);
    }

    // Validate header
    final header = rows.first.map((e) => e.toString()).toList(growable: false);
    final isExtended =
        header.length >= 7 &&
        header[0] == 'game_id' &&
        header[1] == 'character_id' &&
        header[2] == 'game_name' &&
        header[3] == 'character_name' &&
        header[4] == 'yyyymmdd' &&
        header[5] == 'wins' &&
        header[6] == 'losses';
    final isLegacy =
        header.length >= 5 &&
        header[0] == 'game_id' &&
        header[1] == 'character_id' &&
        header[2] == 'yyyymmdd' &&
        header[3] == 'wins' &&
        header[4] == 'losses';
    if (!isExtended && !isLegacy) {
      logCsv.severe('import CSV: header mismatch');
      throw FormatException('CSV header mismatch');
    }

    // cache known gameIds
    final known = <String>{for (final g in await db.fetchAllGames()) g.id};

    var imported = 0;
    var skipped = 0;
    final errors = <String>[];
    for (var i = 1; i < rows.length; i++) {
      final r = rows[i];
      if ((!isExtended && r.length < 5) || (isExtended && r.length < 7)) {
        skipped++;
        errors.add('line ${i + 1}: 列数が不足しています');
        continue;
      }
      final gameId = r[0].toString().trim();
      final characterId = r[1].toString().trim();
      final gameNameCsv = isExtended ? r[2].toString().trim() : null;
      final charNameCsv = isExtended ? r[3].toString().trim() : null;
      final yyyymmdd = int.tryParse(r[isExtended ? 4 : 2].toString());
      final wins = int.tryParse(r[isExtended ? 5 : 3].toString());
      final losses = int.tryParse(r[isExtended ? 6 : 4].toString());

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

      // ensure game exists in master (use provided name when available)
      if (!known.contains(gameId)) {
        final gName = (gameNameCsv == null || gameNameCsv.isEmpty)
            ? gameId
            : gameNameCsv;
        await db.upsertGame(
          GamesCompanion(id: Value(gameId), name: Value(gName)),
        );
        known.add(gameId);
      }

      // ensure character master exists (use provided name when available)
      final existingChar = await (db.select(
        db.characters,
      )..where((t) => t.id.equals(characterId))).getSingleOrNull();
      if (existingChar == null) {
        final cName = (charNameCsv == null || charNameCsv.isEmpty)
            ? characterId
            : charNameCsv;
        await db.upsertCharacter(
          CharactersCompanion(
            id: Value(characterId),
            gameId: Value(gameId),
            name: Value(cName),
            colorArgb: const Value.absent(),
          ),
        );
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
    final result = ImportResult(
      imported: imported,
      skipped: skipped,
      errors: errors,
    );
    logCsv.info(
      'import CSV done imported=${result.imported} skipped=${result.skipped} errors=${result.errors.length}',
    );
    return result;
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
