import 'package:flutter_test/flutter_test.dart';
import 'package:matchnotes/domain/entities.dart';

void main() {
  group('DailyCharacterRecord.copyWith', () {
    final id = DailyCharacterRecordId(
      gameId: 'g1',
      characterId: 'c1',
      date: DateTime(2024, 5, 20),
    );

    test('retains existing values when fields are not provided', () {
      final record = DailyCharacterRecord(
        id: id,
        wins: 3,
        losses: 1,
        memo: 'note',
      );

      final updated = record.copyWith();

      expect(updated.wins, 3);
      expect(updated.losses, 1);
      expect(updated.memo, 'note');
    });

    test('allows clearing memo by passing null explicitly', () {
      final record = DailyCharacterRecord(
        id: id,
        wins: 3,
        losses: 1,
        memo: 'note',
      );

      final cleared = record.copyWith(memo: null);

      expect(cleared.memo, isNull);
    });
  });
}
