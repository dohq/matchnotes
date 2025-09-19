import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchnotes/domain/entities.dart';
import 'package:matchnotes/domain/usecases/export_daily_records_csv.dart';
import 'package:matchnotes/infrastructure/db/app_database.dart';
import 'package:matchnotes/infrastructure/repositories/daily_character_record_repository_drift.dart';

import 'fakes.dart';

void main() {
  group('ExportDailyRecordsCsvUsecase', () {
    test('writes csv with header and sorted rows', () async {
      final repo = FakeDailyCharacterRecordRepository();
      final usecase = ExportDailyRecordsCsvUsecase(repo);

      final d1 = DateTime(2025, 1, 2);
      final d2 = DateTime(2025, 1, 1);
      // Insert unsorted order intentionally
      await repo.upsert(
        DailyCharacterRecord(
          id: DailyCharacterRecordId(gameId: 'gB', characterId: 'c1', date: d1),
          wins: 1,
          losses: 0,
          memo: null,
        ),
      );
      await repo.upsert(
        DailyCharacterRecord(
          id: DailyCharacterRecordId(gameId: 'gA', characterId: 'c2', date: d2),
          wins: 2,
          losses: 3,
          memo: 'm',
        ),
      );

      final temp = await Directory.systemTemp.createTemp('export_csv_test');
      addTearDown(() async => temp.delete(recursive: true));

      final file = await usecase.execute(targetDir: temp);
      expect(await file.exists(), isTrue);
      final content = await file.readAsString();
      final lines = content.trim().split('\n');
      // header + 2 rows
      expect(lines.length, 3);
      expect(lines.first, 'game_id,character_id,yyyymmdd,wins,losses');
      // Sorted by gameId asc, then characterId asc, then date asc
      expect(lines[1], 'gA,c2,20250101,2,3');
      expect(lines[2], 'gB,c1,20250102,1,0');
    });

    test('writes extended csv with names when db is provided', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() async => db.close());
      final repo = DailyCharacterRecordRepositoryDrift(db);
      final usecase = ExportDailyRecordsCsvUsecase(repo, db);

      await db.upsertGame(
        GamesCompanion(id: const Value('g1'), name: const Value('Game A')),
      );
      await db.upsertCharacter(
        CharactersCompanion.insert(id: 'c1', gameId: 'g1', name: 'Char A'),
      );

      final d1 = DateTime(2024, 1, 1);
      final d2 = DateTime(2024, 1, 2);
      await repo.upsert(
        DailyCharacterRecord(
          id: DailyCharacterRecordId(gameId: 'g2', characterId: 'c9', date: d2),
          wins: 0,
          losses: 2,
          memo: '',
        ),
      );
      await repo.upsert(
        DailyCharacterRecord(
          id: DailyCharacterRecordId(gameId: 'g1', characterId: 'c1', date: d1),
          wins: 5,
          losses: 4,
          memo: null,
        ),
      );

      final temp = await Directory.systemTemp.createTemp(
        'export_csv_with_names',
      );
      addTearDown(() async => temp.delete(recursive: true));

      final file = await usecase.execute(targetDir: temp);
      final content = await file.readAsString();
      final lines = content.trim().split('\n');

      expect(
        lines.first,
        'game_id,character_id,game_name,character_name,yyyymmdd,wins,losses',
      );
      expect(lines[1], 'g1,c1,Game A,Char A,20240101,5,4');
      expect(lines[2], 'g2,c9,g2,c9,20240102,0,2');
    });
  });
}
