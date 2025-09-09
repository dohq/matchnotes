# Crashlytics 最小統合ガイド

本ブランチでは Firebase Crashlytics を最小構成で導入しています。実運用前に以下のセットアップを完了してください。

## 1) Firebase プロジェクト準備
- Firebase Console で新規/既存プロジェクトを用意
- Android アプリ（Application ID: `dev.dohq.matchnotes`）と iOS アプリ（Bundle ID 同一）を登録
- 設定ファイルを取得して配置
  - Android: `android/app/google-services.json`
  - iOS: `ios/Runner/GoogleService-Info.plist`

## 2) 依存とビルド設定
- 依存（済）: `pubspec.yaml` に `firebase_core` / `firebase_crashlytics`
- Android ルート: `android/build.gradle.kts` に Google Services / Crashlytics Gradle Plugin の classpath を追加（本ブランチで済）
- Android アプリ: `android/app/build.gradle.kts` でプラグイン適用（`com.google.gms.google-services`, `com.google.firebase.crashlytics`）。Release で `minifyEnabled true` / `shrinkResources true` を有効化（本ブランチで済）
- iOS: 依存解決（CocoaPods）

```
flutter pub get
(cd ios && pod install)
```

## 3) 送信可否（ビルドフラグ）
- `ENABLE_CRASH`（bool, 既定: true）。送信は「Release かつ ENABLE_CRASH=true」でのみ有効。
- 実行例:

```
flutter run --release --dart-define=ENABLE_CRASH=true
```

### スモークテスト（任意）
- 起動直後に非致命イベントを1件送信して配線確認ができます。
- フラグ: `CRASHLYTICS_SMOKE_TEST=true`

```
flutter run --release \
  --dart-define=ENABLE_CRASH=true \
  --dart-define=CRASHLYTICS_SMOKE_TEST=true
```

## 4) 初期化とハンドラ
- 初期化コード: `lib/infrastructure/crash/crashlytics.dart`
- エラーハンドラ:
  - `FlutterError.onError`（Flutter 同期例外）
  - `PlatformDispatcher.instance.onError`（非同期・フレーム外）
  - `runZonedGuarded`（最終ガード）
- エントリ: `lib/main.dart` で `runWithCrashReporting` を呼び出し

## 5) 動作確認
- Release 実行後、Crashlytics ダッシュボードの Real-time / Issues を確認
- 任意でコードに `throw StateError('test');` を一時的に仕込み、到達を確認（開発が終わったら削除）

## 6) dSYM/mapping（推奨）
- Android: Release で minify/shrink 有効。Crashlytics Gradle Plugin が mapping を自動アップロード
- iOS: Xcode/CI で dSYM アップロード（`firebase_crashlytics` のスクリプトが追加されます）

## 7) プライバシー
- ユーザ入力（メモ等）はレポートに含めない方針
- 送信可否を設定画面で切替する場合は、アプリ内設定を実装し、`SharedPreferences` と連動

## 8) 既知の注意点
- 設定ファイル（`google-services.json` / `GoogleService-Info.plist`）が無い場合、初期化は失敗しますがアプリは継続実行（コンソールに警告）
- Web ビルドでは Crashlytics を初期化しません

