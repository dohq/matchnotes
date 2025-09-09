# Drift DB マイグレーション指針（現行: v5）

本プロジェクトでは `lib/infrastructure/db/app_database.dart` の `schemaVersion` と `MigrationStrategy` でスキーマ管理を行います。

現在のバージョン: `schemaVersion = 5`

対象テーブル:
- `DailyCharacterRecords`（主キー: `game_id`,`character_id`,`yyyymmdd`）
- `Games`（`id` 主キー）
- `Characters`（`id` 主キー, `game_id` 外部参照）

## 実装方針（抜粋）
- `onCreate`: `m.createAll()` で全テーブルを作成。
- `onUpgrade`:
  - `if (from < 3) m.createTable(games);`（v3で `Games` 追加）
  - `if (from < 4) m.createTable(characters);`（v4で `Characters` 追加）
- `beforeOpen`:
  - v5で追加したインデックスを `customStatement` で作成（新規/既存どちらも同一最終形へ）。
    - `idx_dcr_yyyymmdd`（`daily_character_records(yyyymmdd)`）
    - `idx_dcr_game_day`（`daily_character_records(game_id, yyyymmdd)`）

サンプル（要点のみ）:
```dart
@override
int get schemaVersion => 5;

@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) async {
    await m.createAll();
  },
  onUpgrade: (m, from, to) async {
    if (from < 3) await m.createTable(games);
    if (from < 4) await m.createTable(characters);
  },
  beforeOpen: (details) async {
    if (details.wasCreated || (details.versionBefore ?? 0) < 5) {
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_dcr_yyyymmdd ON daily_character_records (yyyymmdd)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_dcr_game_day ON daily_character_records (game_id, yyyymmdd)',
      );
    }
  },
);
```

## 変更を入れるときの手順
1. `schemaVersion` をインクリメント。
2. 既存ユーザ向けの移行を `onUpgrade` に `if (from < N)` で追加。
3. 新規インストールでも最終形になるよう `onCreate` / `beforeOpen` にも反映。
4. `make lint test` を実行（E2E/ウィジェット/ユニット含む）。
5. 実機/デスクトップで動作確認。

## Tips
- 破壊的変更（削除/型変更）は避け、追加やインデックスで吸収する。
- 大きなデータ補正が必要な場合は `customStatement` / `customUpdate` を利用し、必ず冪等にする。

## 参考
- Drift 公式: https://drift.simonbinder.eu/docs/advanced-features/migrations/
- path_provider: https://pub.dev/packages/path_provider
