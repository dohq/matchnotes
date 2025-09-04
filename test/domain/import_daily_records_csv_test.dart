import 'dart:io';

import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:matchnotes/domain/usecases/import_daily_records_csv.dart';
import 'package:matchnotes/infrastructure/db/app_database.dart';

import 'fakes.dart';

void main() {
  group('ImportDailyRecordsCsvUsecase', () {
    test('imports valid CSV, creates unknown game, returns counts', () async {
      final repo = FakeDailyCharacterRecordRepository();
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() async => db.close());

      // Pre-register one known game to ensure mix of known/unknown
      await db.upsertGame(
        GamesCompanion(id: const Value('g1'), name: const Value('Known Game')),
      );

      final usecase = ImportDailyRecordsCsvUsecase(repo, db);

      final csv = [
        'game_id,character_id,yyyymmdd,wins,losses',
        'g1,c1,20250101,2,1',
        'g2,c2,20250102,0,3', // g2 is unknown -> should be auto-created with name=g2
      ].join('\n');

      final dir = await Directory.systemTemp.createTemp('import_csv_test');
      addTearDown(() async => dir.delete(recursive: true));
      final file = File('${dir.path}/in.csv');
      await file.writeAsString(csv);

      final report = await usecase.executeWithReport(file: file);
      expect(report.imported, 2);
      expect(report.skipped, 0);
      expect(report.errors, isEmpty);

      // verify games table contains g1 (Known Game) and g2 (auto)
      final games = await db.fetchAllGames();
      expect(games.map((g) => g.id).toSet(), containsAll(['g1', 'g2']));
      expect(games.firstWhere((g) => g.id == 'g2').name, 'g2');

      // verify records stored in repo
      final stored = repo.dump();
      expect(stored.length, 2);
      expect(
        stored.any((r) => r.id.gameId == 'g1' && r.wins == 2 && r.losses == 1),
        isTrue,
      );
      expect(
        stored.any((r) => r.id.gameId == 'g2' && r.wins == 0 && r.losses == 3),
        isTrue,
      );
    });
  });
}
