# matchnotes

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
- **UI（デモ）**: `lib/main.dart` の `DemoPage`
  - ボタンでユースケースを実行し、日次集計・メモコピーを確認可能

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

## 注意

- pre-commit フックで format / analyze が通らない場合、コミットは中断されます。
