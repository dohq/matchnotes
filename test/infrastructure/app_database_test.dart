import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchnotes/infrastructure/db/app_database.dart';

void main() {
  group('AppDatabase helpers', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('renameGame updates name', () async {
      // arrange
      await db.upsertGame(GamesCompanion.insert(id: 'g1', name: 'Old'));
      // act
      await db.renameGame(id: 'g1', name: 'New');
      // assert
      final games = await db.fetchAllGames();
      expect(games.singleWhere((g) => g.id == 'g1').name, 'New');
    });

    test('deleteGameAndRecords removes game and its daily records', () async {
      // arrange
      await db.upsertGame(GamesCompanion.insert(id: 'g1', name: 'G'));
      await db.upsertCharacter(
        CharactersCompanion.insert(id: 'c1', gameId: 'g1', name: 'C1'),
      );
      final today = DateTime.now();
      await db.upsertRecord(
        DailyCharacterRecordsCompanion.insert(
          gameId: 'g1',
          characterId: 'c1',
          yyyymmdd: AppDatabase.toYyyymmdd(today),
          wins: const Value(1),
          losses: const Value(0),
          memo: const Value.absent(),
        ),
      );
      // precheck
      expect((await db.fetchAllGames()).length, 1);
      expect((await db.fetchByGameAndDay(gameId: 'g1', day: today)).length, 1);
      // act
      await db.deleteGameAndRecords('g1');
      // assert
      expect(await db.fetchAllGames(), isEmpty);
      expect(await db.fetchByGameAndDay(gameId: 'g1', day: today), isEmpty);
    });

    test('renameCharacter updates name', () async {
      // arrange
      await db.upsertGame(GamesCompanion.insert(id: 'g1', name: 'G'));
      await db.upsertCharacter(
        CharactersCompanion.insert(id: 'c1', gameId: 'g1', name: 'Old C1'),
      );
      // act
      await db.renameCharacter(id: 'c1', name: 'New C1');
      // assert
      final list = await db.fetchCharactersByGame('g1');
      expect(list.singleWhere((c) => c.id == 'c1').name, 'New C1');
    });

    test(
      'deleteCharacterAndRecords removes character and its daily records',
      () async {
        // arrange
        await db.upsertGame(GamesCompanion.insert(id: 'g1', name: 'G'));
        await db.upsertCharacter(
          CharactersCompanion.insert(id: 'c1', gameId: 'g1', name: 'C1'),
        );
        final today = DateTime.now();
        await db.upsertRecord(
          DailyCharacterRecordsCompanion.insert(
            gameId: 'g1',
            characterId: 'c1',
            yyyymmdd: AppDatabase.toYyyymmdd(today),
            wins: const Value(2),
            losses: const Value(3),
            memo: const Value.absent(),
          ),
        );
        // precheck
        expect((await db.fetchCharactersByGame('g1')).length, 1);
        expect(
          (await db.fetchByGameAndDay(gameId: 'g1', day: today)).length,
          1,
        );
        // act
        await db.deleteCharacterAndRecords(gameId: 'g1', characterId: 'c1');
        // assert
        expect(await db.fetchCharactersByGame('g1'), isEmpty);
        expect(await db.fetchByGameAndDay(gameId: 'g1', day: today), isEmpty);
      },
    );
  });
}
