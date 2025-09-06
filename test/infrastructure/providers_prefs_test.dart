import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchnotes/infrastructure/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpUntil(
  bool Function() predicate, {
  Duration step = const Duration(milliseconds: 5),
  Duration timeout = const Duration(seconds: 1),
}) async {
  final sw = Stopwatch()..start();
  while (!predicate()) {
    if (sw.elapsed > timeout) break;
    await Future<void>.delayed(step);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeModeController', () {
    test('setMode 永続化/再読込', () async {
      SharedPreferences.setMockInitialValues({});

      final c1 = ThemeModeController();
      await c1.setMode(ThemeMode.dark);

      // 再生成時に保存値をロードできること
      final c2 = ThemeModeController();
      await _pumpUntil(() => c2.state == ThemeMode.dark);
      expect(c2.state, ThemeMode.dark);
    });
  });

  group('KeepScreenOnController', () {
    test('setKeepOn 永続化/再読込', () async {
      SharedPreferences.setMockInitialValues({});

      final c1 = KeepScreenOnController();
      await c1.setKeepOn(true);

      final c2 = KeepScreenOnController();
      await _pumpUntil(() => c2.state == true);
      expect(c2.state, isTrue);
    });
  });

  group('CutoffTimeController', () {
    test('分指定の設定/クランプ', () async {
      SharedPreferences.setMockInitialValues({});
      final c = CutoffTimeController();
      await c.setMinutes(1500); // 1439にクランプ
      expect(c.state, 1439);

      await c.setHourMinute(hour: 4, minute: 30);
      expect(c.state, 4 * 60 + 30);

      // マイナスや上限超過のクランプ
      await c.setHourMinute(hour: -1, minute: -5);
      expect(c.state, 0);
      await c.setHourMinute(hour: 99, minute: 99);
      expect(c.state, 23 * 60 + 59);
    });

    test('レガシーhourキーからの移行', () async {
      // 旧キーのみ与える
      SharedPreferences.setMockInitialValues({'settings.cutoffHour': 4});
      final c = CutoffTimeController();
      await _pumpUntil(() => c.state == 240);
      expect(c.state, 240);

      // minutesキーへ移行済みになっていること
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('settings.cutoffMinutes'), 240);
    });
  });
}
