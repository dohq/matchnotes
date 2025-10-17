# Repository Guidelines

本書は MatchNotes のコントリビュータ向けガイドです。Flutter/Dart、drift、Riverpod を使用します。

## Project Structure & Module Organization
- `lib/domain/`: エンティティ・ユースケース・リポジトリIF。
- `lib/infrastructure/`: DB（drift）とDI実装。`db/app_database.dart`・`db/open.dart`・`repositories/`・`providers.dart`。
- `lib/presentation/`: UI。エントリは `lib/main.dart`。
- `test/`: `domain/`・`e2e/`・`widget_test.dart`。
- `scripts/`: `emulator_start.sh`・`pre-commit` など。`docs/`: `db_migration.md`。

## Build, Test, and Development Commands
```bash
flutter pub get                 # 依存取得
make build                      # build_runner によるコード生成（drift等）
make format && make lint        # フォーマット / 静的解析
make test                       # ユニット/ウィジェット/E2E テスト
make coverage coverage-html     # lcov/html レポート作成（要 lcov, genhtml）
make emulator-start EMULATOR_AVD=Pixel_8a_API_34
make install-hooks              # pre-commit 導入（format+analyze を強制）
```

## Coding Style & Naming Conventions
- フォーマッタ: `dart format`（2スペース）。Lints: `flutter_lints`（`analysis_options.yaml`）。
- 命名: ファイルは `snake_case.dart`、クラスは UpperCamelCase、関数/変数は lowerCamelCase。
- 生成物 `*.g.dart` は手動編集しない。スキーマ変更時は `make build` を実行。

## Testing Guidelines
- フレームワーク: `flutter_test`。配置: `test/domain/`・`test/e2e/`・`test/widget_test.dart`。
- 命名: `*_test.dart`。実行: `make test`。カバレッジ: `make coverage`。
- drift のE2Eは `NativeDatabase.memory()` を利用し実DB相当の動作を検証。

## Commit & Pull Request Guidelines
- 作業開始前に、機能追加や修正ごとに必ず新しいブランチを作成し、そのブランチ上で変更を行ってください。
- コミット規約（必須）: コミットメッセージは必ず「Conventional Commits」フォーマットに準拠してください。
  - 形式: `<type>(<scope>): <subject>`（`scope` は任意）
  - 主な `type`: `feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`
  - 例: `feat(presentation): 試合一覧にフィルタを追加` / `fix(db): 移行スクリプトのnull処理を修正`
  - Breaking変更は本文またはフッターに `BREAKING CHANGE:` を付記
  - 1行目は簡潔（~50文字目安）、末尾の句読点は不要。必要に応じ本文/フッターで詳細・Issue連携（`Closes #123` など）
  - コミットは原則 GPG 署名付き（`git commit -S`）。
- PR: 目的・背景・変更点を簡潔に。関連Issueをリンク。UI変更はスクリーンショット添付。テスト/ドキュメントの更新を含める。
- Git hooks: `make install-hooks` で pre-commit を導入（format/analyze が通らない場合はコミット中断）。
- DB変更時は `docs/db_migration.md` を更新。

## Security & Configuration Tips
- 秘匿情報は扱わずローカルSQLiteを使用。生成・マイグレーションはソース管理下のコードで再現可能。
- Androidエミュレータの AVD 名は `EMULATOR_AVD` で上書き可能。
- 新規に生成されたファーストパーティコードには、常にSnyk Codeスキャンツールを実行する。
- 新規の依存関係や依存関係の更新には、常にSnyk SCAスキャンツールを実行する。
- 新規導入または変更されたコードや依存関係に基づいてセキュリティ上の問題が検出された場合、Snykの結果コンテキストを使用して問題の修正を試みてください。
- 問題を修正した後、コードを再スキャンし、問題が修正されたことと新たな問題が導入されていないことを確認してください。
- 問題が検出されなくなるまで、このプロセスを繰り返してください。
