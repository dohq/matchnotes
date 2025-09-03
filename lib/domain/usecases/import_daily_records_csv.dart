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
    final content = await file.readAsString();
    final rows = const CsvToListConverter(eol: '\n').convert(content);
    if (rows.isEmpty) return 0;

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
    final known = <String>{
      for (final g in await db.fetchAllGames()) g.id,
    };

    var count = 0;
    for (var i = 1; i < rows.length; i++) {
      final r = rows[i];
      if (r.length < 5) continue; // skip short lines
      final gameId = r[0].toString();
      final characterId = r[1].toString();
      final yyyymmdd = int.parse(r[2].toString());
      final wins = int.parse(r[3].toString());
      final losses = int.parse(r[4].toString());

      if (wins < 0 || losses < 0) {
        continue; // skip invalid
      }
      final date = _dateFromYyyymmdd(yyyymmdd);

      // ensure game exists in master
      if (!known.contains(gameId)) {
        await db.upsertGame(GamesCompanion(
          id: Value(gameId),
          name: Value(gameId),
        ));
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
      count++;
    }
    return count;
  }

  DateTime _dateFromYyyymmdd(int v) {
    final y = v ~/ 10000;
    final m = (v % 10000) ~/ 100;
    final d = v % 100;
    return DateTime(y, m, d);
  }
}
