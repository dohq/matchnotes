import 'package:flutter_test/flutter_test.dart';
import 'package:matchnotes/domain/date_utils.dart';

void main() {
  group('truncateWithCutoff (hour)', () {
    test('cutoff=4: 03:59は前日扱い、04:00は当日', () {
      final d1 = DateTime(2024, 5, 10, 3, 59);
      final d2 = DateTime(2024, 5, 10, 4, 0);

      final t1 = truncateWithCutoff(d1, 4);
      final t2 = truncateWithCutoff(d2, 4);

      expect(t1, DateTime(2024, 5, 9));
      expect(t2, DateTime(2024, 5, 10));
      // 時刻は 00:00:00 に丸められる
      expect(t1.hour, 0);
      expect(t1.minute, 0);
      expect(t2.hour, 0);
      expect(t2.minute, 0);
    });

    test('cutoff=0: その日の0時跨ぎで丸め', () {
      final d1 = DateTime(2024, 1, 1, 0, 0);
      final d2 = DateTime(2024, 1, 1, 23, 59);
      expect(truncateWithCutoff(d1, 0), DateTime(2024, 1, 1));
      expect(truncateWithCutoff(d2, 0), DateTime(2024, 1, 1));
    });
  });

  group('truncateWithCutoffMinutes (minutes)', () {
    test('cutoff=90: 01:29は前日、01:30は当日', () {
      final d1 = DateTime(2024, 5, 10, 1, 29);
      final d2 = DateTime(2024, 5, 10, 1, 30);

      final t1 = truncateWithCutoffMinutes(d1, 90);
      final t2 = truncateWithCutoffMinutes(d2, 90);

      expect(t1, DateTime(2024, 5, 9));
      expect(t2, DateTime(2024, 5, 10));
    });

    test('cutoffのクランプ: 負値/大きすぎる値も正常化', () {
      final d = DateTime(2024, 5, 10, 12, 0);
      // 負値は0扱い（当日）
      expect(truncateWithCutoffMinutes(d, -10), DateTime(2024, 5, 10));
      // 1440以上は1439分にクランプ（前日扱い）
      expect(
        truncateWithCutoffMinutes(DateTime(2024, 5, 10, 0, 0), 2000),
        DateTime(2024, 5, 9),
      );
    });
  });
}
