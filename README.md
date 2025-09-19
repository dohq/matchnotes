# MatchNotes

[![Coverage](docs/coverage.svg)](https://github.com/dohq/matchnotes/actions/workflows/flutter-ci.yml)
[![Code to Test Ratio](docs/code_to_test_ratio.svg)](https://github.com/dohq/matchnotes/actions/workflows/flutter-ci.yml)
[![Test Execution Time](docs/test_execution_time.svg)](https://github.com/dohq/matchnotes/actions/workflows/flutter-ci.yml)

 Android向け・ローカルSQLiteベースの「勝敗記録アプリ」。

## 開発手順

前提: Flutter SDK, Android SDK, AVD （`Pixel_8a_API_34`）

### 依存取得

```bash
flutter pub get
```

### コード生成（drift）

初回およびスキーマ変更時に drift のコード生成を実行します。

```bash
make build
```

### Make ターゲット

- `make format` … Dart/Flutter フォーマット
- `make lint` … Flutter Analyze
- `make test` … ユニット/ウィジェットテスト
- `make build` … drift 等のコード生成（build_runner）
- `make coverage` … lcov.info 生成（`coverage/lcov.info`）
- `make coverage-html` … HTMLレポート生成（`coverage/html/`）
- `make emulator-start` … Android Emulator 起動（AVD: `Pixel_8a_API_34`）
- `make emulator-stop` … Emulator 停止
- `make install-hooks` … Git pre-commit フック導入（format+lintを強制）
- `make android-run` … 接続中の端末/エミュレータで起動（必要なら自動で Emulator 起動）

ヒント: `EMULATOR_AVD` 環境変数で AVD を上書き可能

```bash
make emulator-start EMULATOR_AVD=YourAvdName
```

### カバレッジHTMLの前提

システムに `lcov` と `genhtml` が必要です。例（Debian/Ubuntu）:

```bash
sudo apt-get update && sudo apt-get install -y lcov
```

## アーキテクチャ概要（drift/DI）

- ドメイン層: `lib/domain/` にエンティティ・ユースケース・リポジトリIFを定義。
- インフラ層（drift）:
  - スキーマ/DAO: `lib/infrastructure/db/app_database.dart`
    - テーブル: `DailyCharacterRecords`（主キー: `gameId`,`characterId`,`yyyymmdd`）/ `Games` / `Characters`
    - DataClass: `DailyCharacterRecordRow` ほか
    - DAOヘルパ: `fetchRecord` / `fetchByGameAndDay` / `upsertRecord` など
  - DBオープン: `lib/infrastructure/db/open.dart`（`openAppDatabase()`）
  - リポジトリ実装: `lib/infrastructure/repositories/daily_character_record_repository_drift.dart`
    - ドメインIF `DailyCharacterRecordRepository` の drift 実装
    - `DateTime` ⇄ `yyyymmdd(int)` の相互変換
- DI（Riverpod）: `lib/infrastructure/providers.dart`
  - `appDatabaseProvider`（Async）/ `dailyCharacterRecordRepositoryProvider`（Async）
  - ユースケース用: `AddWin` / `AddLoss` / `GetDailyGameSummary` / `CopyMemoFromPreviousDay` / `GetMonthlyWinRatesPerGame` / `ExportDailyRecordsCsv` / `ImportDailyRecordsCsv`
  - 設定: `themeModeProvider` / `keepScreenOnProvider` / `cutoffMinutesProvider`
- UI: `lib/presentation/`
  - `top_page.dart` … トップ（今日のサマリ・直近7日・月次勝率チャート）
  - `game_select_page.dart` … ゲーム管理/選択
  - `character_select_page.dart` … キャラ管理/選択
  - `register_page.dart` … 勝/負の登録、Undo、メモ起動
  - `memo_page.dart` … メモ編集（前日からのコピー可）
  - `settings_page.dart` … テーマ/画面常時ON/日付切替時刻
  - 軸ラベル補助: `x_axis_labels.dart`

## テスト

- ドメイン/ユースケースの単体テスト: `test/domain/`
- E2E（drift × ユースケース）: `test/e2e/drift_repository_e2e_test.dart`
  - `NativeDatabase.memory()` を使って実DB動作を確認
- ウィジェットテスト: `test/widget_test.dart`（デモ画面の最低限の存在確認）

実行:

```bash
make test
```

## 参考

- Flutter: https://docs.flutter.dev/
- Riverpod: https://pub.dev/packages/flutter_riverpod
- drift: https://drift.simonbinder.eu/
- Syncfusion Charts: https://pub.dev/packages/syncfusion_flutter_charts
- CSV: https://pub.dev/packages/csv
- file_picker: https://pub.dev/packages/file_picker
- media_store_plus (Android): https://pub.dev/packages/media_store_plus
- wakelock_plus: https://pub.dev/packages/wakelock_plus
- shared_preferences: https://pub.dev/packages/shared_preferences

### DBマイグレーションドキュメント

- `docs/db_migration.md`

## 注意

- pre-commit フックで format / analyze が通らない場合、コミットは中断されます。

## データインポート/エクスポート仕様

### CSVインポート（アプリ設定 > データのインポート）

- 受け付けるヘッダ（1行目）
  - レガシー: `game_id,character_id,yyyymmdd,wins,losses`
  - 拡張: `game_id,character_id,game_name,character_name,yyyymmdd,wins,losses`
- 改行コード: LF 推奨
- メモ欄は対象外（CSVには含めない）
- 未登録IDの扱い:
  - 未登録の `game_id` は `Games` に自動登録（拡張CSVの `game_name` があればそれを名称に利用、なければ `game_id`）。
  - 未登録の `character_id` も `Characters` に自動登録（拡張CSVの `character_name` があれば利用、なければ `character_id`）。

検証ルール:

- 列数不足行はスキップ
- `game_id` / `character_id` の空文字列はスキップ
- `yyyymmdd` / `wins` / `losses` は数値必須
- `wins` / `losses` の負値は禁止
- `yyyymmdd` は実在日付である必要あり（例: 20230230 は不正）

インポート結果:

- 取り込み件数（imported）、スキップ件数（skipped）、エラー詳細（先頭数件）がダイアログで表示されます。

### CSVエクスポート（アプリ設定 > データのエクスポート）

- 共有の公開 `Downloads` フォルダ（または各OSの相当箇所）に CSV を保存します。
  - Desktop（Windows/macOS/Linux）: `Downloads/MatchNotes/matchnotes_backup.csv`
  - Android: `Downloads/MatchNotes/matchnotes_backup.csv`（MediaStore 経由・Android 10+）
  - iOS: アプリ専用 `Documents/MatchNotes/matchnotes_backup.csv`

## アプリ設定

設定は `設定` 画面から変更できます。変更内容はアプリ再起動後も保持されます（`shared_preferences` に保存）。

- テーマモード
  - 選択肢: `システムに合わせる` / `ライト（OFF）` / `ダーク（ON）`
  - UI: `SegmentedButton<ThemeMode>`
  - プロバイダ: `themeModeProvider`（`StateNotifierProvider`）
  - 保存キー: `settings.themeMode`（`system|light|dark`）

- 勝敗登録ページで画面ロック防止（常時点灯）
  - スイッチONで、勝敗登録ページ表示中のスリープを防止します。
  - 変更はページ表示中でも即時反映されます（`ref.listen` で監視）。
  - ページ離脱時は自動的に解除されます。
  - 実装: `wakelock_plus` を使用（`WakelockPlus.enable/disable`）
  - プロバイダ: `keepScreenOnProvider`（`StateNotifierProvider`）
  - 保存キー: `settings.keepScreenOn`（`bool`）

- 日付の切り替わり時刻（カットオフ）
  - 指定時刻までは前日扱いにします（例: 01:30 なら 01:29 まで前日）。
  - プロバイダ: `cutoffMinutesProvider`（分で保持 0–1439）。
  - 旧キー `settings.cutoffHour` は自動移行されます。

## ゲーム/キャラクター管理

- ゲーム管理は `ゲーム選択` 画面で行います。
  - 一覧はDBと連動（リアルタイム反映）。
  - 追加: 画面右下の `+` FAB でダイアログを表示し、`表示名` のみ入力。
    - `id` は内部で自動生成されます（`prefix-<epoch>-<base36>` 形式）。
  - 編集/削除: 各行のメニュー（︙）から名称変更・削除が可能。
    - 削除時は確認ダイアログ後、関連する日次記録も含めて一括削除（カスケード）。

- キャラクター管理は `キャラクター選択` 画面で行います。
  - 追加: `表示名` のみ入力。`id` は内部生成、色は `id` から決定的に割り当て。
  - 編集/削除: 各行のメニュー（︙）から実行可能。削除は当該ゲーム・キャラの全日次記録も同時削除。
