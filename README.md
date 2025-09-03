# matchnotes

 Android向け・ローカルSQLiteベースの「勝敗記録アプリ」。

## 開発手順

前提: Flutter SDK, Android SDK, AVD （`Pixel_8a_API_34`）

### 依存取得

```bash
flutter pub get
```

### Make ターゲット

- `make format` … Dart/Flutter フォーマット
- `make lint` … Flutter Analyze
- `make test` … ユニット/ウィジェットテスト
- `make coverage` … lcov.info 生成（`coverage/lcov.info`）
- `make coverage-html` … HTMLレポート生成（`coverage/html/`）
- `make emulator-start` … Android Emulator 起動（AVD: `Pixel_8a_API_34`）
- `make emulator-stop` … Emulator 停止
- `make install-hooks` … Git pre-commit フック導入（format+lintを強制）

ヒント: `EMULATOR_AVD` 環境変数で AVD を上書き可能

```bash
make emulator-start EMULATOR_AVD=YourAvdName
```

### カバレッジHTMLの前提

システムに `lcov` と `genhtml` が必要です。例（Debian/Ubuntu）:

```bash
sudo apt-get update && sudo apt-get install -y lcov
```

## 参考

 - Flutter: https://docs.flutter.dev/
 - go_router: https://pub.dev/packages/go_router
 - riverpod: https://pub.dev/packages/flutter_riverpod
 - drift: https://drift.simonbinder.eu/
 - table_calendar: https://pub.dev/packages/table_calendar

## 注意

- pre-commit フックで format / analyze が通らない場合、コミットは中断されます。
