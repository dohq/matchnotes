import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:matchnotes/domain/entities.dart';
import 'package:matchnotes/domain/usecases/export_daily_records_csv.dart';

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
  });
}
