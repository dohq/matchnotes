# MatchNotes

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

- **ドメイン層**: `lib/domain/` にエンティティ・ユースケース・リポジトリIFを定義。
- **インフラ層（drift）**:
  - スキーマ/DAO: `lib/infrastructure/db/app_database.dart`
    - テーブル: `DailyCharacterRecords`（主キー: `gameId`,`characterId`,`yyyymmdd`）
    - DataClass: `DailyCharacterRecordRow`（ドメインと衝突回避）
    - DAOヘルパ: `fetchRecord` / `fetchByGameAndDay` / `upsertRecord`
  - DBオープン: `lib/infrastructure/db/open.dart`（`openAppDatabase()`）
  - リポジトリ実装: `lib/infrastructure/repositories/daily_character_record_repository_drift.dart`
    - ドメインIF `DailyCharacterRecordRepository` の drift 実装
    - `DateTime` ⇄ `yyyymmdd(int)` を相互変換
- **DI（Riverpod）**: `lib/infrastructure/providers.dart`
  - `appDatabaseProvider`（Async）
  - `dailyCharacterRecordRepositoryProvider`（Async）
  - ユースケース用プロバイダ（`AddWin`/`AddLoss`/`GetDailyGameSummary`/`CopyMemoFromPreviousDay`）
- **UI（DailyPage）**: `lib/presentation/daily_page.dart`（`main.dart` から起動）
  - ゲーム/キャラ/日付の指定、勝敗加算、メモ編集、前日メモコピー、日次サマリ表示

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
 - go_router: https://pub.dev/packages/go_router
 - riverpod: https://pub.dev/packages/flutter_riverpod
 - drift: https://drift.simonbinder.eu/
 - table_calendar: https://pub.dev/packages/table_calendar

### DBマイグレーションドキュメント

- `docs/db_migration.md`

## 注意

- pre-commit フックで format / analyze が通らない場合、コミットは中断されます。

## データインポート/エクスポート仕様

### CSVインポート（アプリ設定 > データのインポート）

- 期待ヘッダ（1行目・固定）: `game_id,character_id,yyyymmdd,wins,losses`
- 改行コード: LF 推奨
- メモ欄は対象外（CSVには含めない）
- CSV内に存在しない `game_id` は自動的に `Games` マスタへ登録されます（`name` は `game_id` と同一で初期化）

検証ルール:

- 列数不足行はスキップ
- `game_id` / `character_id` の空文字列はスキップ
- `yyyymmdd` / `wins` / `losses` は数値必須
- `wins` / `losses` の負値は禁止
- `yyyymmdd` は実在日付である必要あり（例: 20230230 は不正）

インポート結果:

- 取り込み件数（imported）、スキップ件数（skipped）、エラー詳細（先頭数件）がダイアログで表示されます。

### CSVエクスポート（アプリ設定 > データのエクスポート）

- アプリのドキュメントディレクトリ配下にCSVを出力します。

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
