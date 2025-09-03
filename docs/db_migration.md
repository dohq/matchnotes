# Drift DB マイグレーション指針（v2 雛形）

本プロジェクトでは `lib/infrastructure/db/app_database.dart` の `schemaVersion` と `MigrationStrategy` でスキーマ管理を行います。

現在のバージョン: `schemaVersion = 2`

## 基本ルール
- 破壊的変更（カラム削除・型変更）は避け、追加やインデックスで対応する。
- 既存ユーザ用の `onUpgrade` と、新規インストール用の `onCreate` の両方に同等の最終スキーマが反映されるようにする。
- 変更後は `make lint test` と、実機/デスクトップでの `flutter run` で動作確認する。

## 実装箇所
- ファイル: `lib/infrastructure/db/app_database.dart`
  - `schemaVersion`: スキーマバージョンをインクリメント
  - `MigrationStrategy`:
    - `onCreate`: 全テーブル作成に加え、vN で必要となるインデックスや初期データ投入があれば追加
    - `onUpgrade`: 旧バージョンからの移行手順を `if (from < N)` で逐次適用

## v2 の雛形（例）
`schemaVersion = 2` に上げる際の典型例を以下に示します。

### 例1: インデックス追加
サマリ取得の高速化などの目的で `(gameId, yyyymmdd)` にインデックスを追加するケース。

```dart
// 1) schemaVersion を 2 に上げる
@override
int get schemaVersion => 2;

@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) async {
    await m.createAll();
    // v2: 新規インストールでも同じインデックスを作る
    // await m.createIndex(Index('idx_daily_game_day', [
    //   dailyCharacterRecords.gameId,
    //   dailyCharacterRecords.yyyymmdd,
    // ]));
  },
  onUpgrade: (m, from, to) async {
    if (from < 2) {
      // 既存ユーザ向けのインデックス作成
      // await m.createIndex(Index('idx_daily_game_day', [
      //   dailyCharacterRecords.gameId,
      //   dailyCharacterRecords.yyyymmdd,
      // ]));
    }
  },
);
```

注: drift の `Index` 作成は `m.createIndex(Index(...))` が利用できます。drift バージョンにより API が異なる場合は、`m.customStatement('CREATE INDEX IF NOT EXISTS ...')` を使用する方法もあります（公式ドキュメントを参照）。

### 例2: カラム追加
`memo` カラムを追加するような非破壊的変更。

```dart
if (from < 2) {
  await m.addColumn(
    dailyCharacterRecords,
    dailyCharacterRecords.memo,
  );
}
```

### 例3: 既存データの補正（任意）

```dart
if (from < 2) {
  // 例: 空文字メモを NULL に正規化する
  // await (customUpdate('UPDATE daily_character_records SET memo = NULL WHERE memo = ""'));
}
```

## 手順のまとめ
1. `schemaVersion` をインクリメント
2. `onUpgrade` に `if (from < 新バージョン)` ブロックを追加
3. `onCreate` にも同内容（最終スキーマ）を反映
4. `make lint test` を通す
5. 実行バイナリ/アプリで手動確認

## 参考
- Drift 公式: https://drift.simonbinder.eu/docs/advanced-features/migrations/
- path_provider: https://pub.dev/packages/path_provider
