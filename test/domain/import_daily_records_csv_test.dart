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

    test(
      'imports extended CSV, populates master data, and stores records',
      () async {
        final repo = FakeDailyCharacterRecordRepository();
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(() async => db.close());

        final usecase = ImportDailyRecordsCsvUsecase(repo, db);

        final csv = [
          'game_id,character_id,game_name,character_name,yyyymmdd,wins,losses,memo_b64',
          'g1,c1,Game Alpha,Char One,20240201,3,1,TGluZSwgd2l0aCAicXVvdGUi',
          'g3,c3,Game Gamma,Char Three,20240202,0,0,',
        ].join('\n');

        final dir = await Directory.systemTemp.createTemp(
          'import_csv_extended',
        );
        addTearDown(() async => dir.delete(recursive: true));
        final file = File('${dir.path}/in.csv');
        await file.writeAsString(csv);

        final report = await usecase.executeWithReport(file: file);
        expect(report.imported, 2);
        expect(report.skipped, 0);
        expect(report.errors, isEmpty);

        final games = await db.fetchAllGames();
        expect(games.map((g) => g.id), containsAll(['g1', 'g3']));

        final charactersG1 = await db.fetchCharactersByGame('g1');
        expect(charactersG1.map((c) => c.id), contains('c1'));
        expect(charactersG1.firstWhere((c) => c.id == 'c1').name, 'Char One');

        final charactersG3 = await db.fetchCharactersByGame('g3');
        expect(charactersG3.map((c) => c.id), contains('c3'));

        final stored = repo.dump();
        expect(stored.length, 2);
        final recG1 = stored.firstWhere(
          (r) => r.id.gameId == 'g1' && r.id.characterId == 'c1',
        );
        expect(recG1.wins, 3);
        expect(recG1.memo, 'Line, with "quote"');
      },
    );

    test('skips invalid rows and reports details', () async {
      final repo = FakeDailyCharacterRecordRepository();
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() async => db.close());
      final usecase = ImportDailyRecordsCsvUsecase(repo, db);

      final csv = [
        'game_id,character_id,yyyymmdd,wins,losses',
        ',c0,20250101,1,0',
        'g1,c1,zzz,0,1',
        'g1,c2,20250132,1,0',
        'g1,c3,20250103,-1,0',
        'g1,c4,20250104,1',
      ].join('\n');

      final dir = await Directory.systemTemp.createTemp('import_csv_errors');
      addTearDown(() async => dir.delete(recursive: true));
      final file = File('${dir.path}/bad.csv');
      await file.writeAsString(csv);

      final report = await usecase.executeWithReport(file: file);
      expect(report.imported, 0);
      expect(report.skipped, 5);
      expect(report.errors.length, 5);
      expect(report.errors, contains('line 2: game_id または character_id が空です'));
      expect(report.errors, contains('line 3: 数値項目の形式が不正です'));
      expect(report.errors, contains('line 4: yyyymmdd が不正な日付です'));
      expect(report.errors, contains('line 5: wins または losses が負の値です'));
      expect(report.errors, contains('line 6: 列数が不足しています'));
      expect(repo.dump(), isEmpty);
    });

    test('invalid memo base64 is reported and skipped', () async {
      final repo = FakeDailyCharacterRecordRepository();
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() async => db.close());
      final usecase = ImportDailyRecordsCsvUsecase(repo, db);

      final csv = [
        'game_id,character_id,yyyymmdd,wins,losses,memo_b64',
        'g1,c1,20250105,1,0,@@@',
      ].join('\n');

      final dir = await Directory.systemTemp.createTemp('import_csv_bad_memo');
      addTearDown(() async => dir.delete(recursive: true));
      final file = File('${dir.path}/bad.csv');
      await file.writeAsString(csv);

      final report = await usecase.executeWithReport(file: file);
      expect(report.imported, 0);
      expect(report.skipped, 1);
      expect(report.errors, contains('line 2: memo_b64 のデコードに失敗しました'));
      expect(repo.dump(), isEmpty);
    });
  });
}
