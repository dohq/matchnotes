import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

      final container1 = ProviderContainer();
      final c1 = container1.read(themeModeProvider.notifier);
      await c1.setMode(ThemeMode.dark);

      // 再生成時に保存値をロードできること
      final container2 = ProviderContainer();
      await _pumpUntil(
        () => container2.read(themeModeProvider) == ThemeMode.dark,
      );
      expect(container2.read(themeModeProvider), ThemeMode.dark);
    });
  });

  group('KeepScreenOnController', () {
    test('setKeepOn 永続化/再読込', () async {
      SharedPreferences.setMockInitialValues({});

      final container1 = ProviderContainer();
      final c1 = container1.read(keepScreenOnProvider.notifier);
      await c1.setKeepOn(true);

      final container2 = ProviderContainer();
      await _pumpUntil(() => container2.read(keepScreenOnProvider) == true);
      expect(container2.read(keepScreenOnProvider), isTrue);
    });
  });

  group('CutoffTimeController', () {
    test('分指定の設定/クランプ', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      final c = container.read(cutoffMinutesProvider.notifier);
      await c.setMinutes(1500); // 1439にクランプ
      expect(container.read(cutoffMinutesProvider), 1439);

      await c.setHourMinute(hour: 4, minute: 30);
      expect(container.read(cutoffMinutesProvider), 4 * 60 + 30);

      // マイナスや上限超過のクランプ
      await c.setHourMinute(hour: -1, minute: -5);
      expect(container.read(cutoffMinutesProvider), 0);
      await c.setHourMinute(hour: 99, minute: 99);
      expect(container.read(cutoffMinutesProvider), 23 * 60 + 59);
    });

    test('レガシーhourキーからの移行', () async {
      // 旧キーのみ与える
      SharedPreferences.setMockInitialValues({'settings.cutoffHour': 4});
      final container = ProviderContainer();
      await _pumpUntil(() => container.read(cutoffMinutesProvider) == 240);
      expect(container.read(cutoffMinutesProvider), 240);

      // minutesキーへ移行済みになっていること
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('settings.cutoffMinutes'), 240);
    });
  });
}
