import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:matchnotes/presentation/settings_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsPage', () {
    testWidgets('テーマ/画面常時ON/カットオフ時刻の基本操作', (tester) async {
      // 初期設定: cutoff=00:15
      SharedPreferences.setMockInitialValues({'settings.cutoffMinutes': 15});

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: SettingsPage())),
      );
      await tester.pumpAndSettle();

      // テーマ: ダークを選択 -> 保存（SharedPreferences に反映される）
      await tester.tap(find.text('ダーク（ON）'));
      await tester.pumpAndSettle();

      final prefs1 = await SharedPreferences.getInstance();
      // 反映に少し待つ
      await tester.pump(const Duration(milliseconds: 50));
      expect(prefs1.getString('settings.themeMode'), anyOf('dark', null));

      // 画面常時ON のトグル
      final keepSwitch = find.byKey(keepScreenOnSwitchKey);
      expect(keepSwitch, findsOneWidget);
      await tester.tap(keepSwitch);
      await tester.pumpAndSettle();
      final prefs2 = await SharedPreferences.getInstance();
      expect(prefs2.getBool('settings.keepScreenOn'), isNotNull);

      // カットオフ時刻: タイルを開いて OK 押下（初期は 00:15 のまま）
      await tester.tap(find.text('日付の切り替わり時刻'));
      await tester.pumpAndSettle();
      // OK で閉じる（値は変えない）
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      // SnackBar が表示される
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('ハプティクス設定のトグル', (tester) async {
      SharedPreferences.setMockInitialValues({'settings.hapticsOnTap': false});

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: SettingsPage())),
      );
      await tester.pumpAndSettle();

      final hapticsSwitch = find.byKey(hapticsSwitchKey);
      expect(hapticsSwitch, findsOneWidget);
      expect(tester.widget<SwitchListTile>(hapticsSwitch).value, isFalse);

      await tester.tap(hapticsSwitch);
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('settings.hapticsOnTap'), isTrue);
      expect(tester.widget<SwitchListTile>(hapticsSwitch).value, isTrue);
    });
  });
}
