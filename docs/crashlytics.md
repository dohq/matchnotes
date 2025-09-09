# Crashlytics 最小統合ガイド

本ブランチでは Firebase Crashlytics を最小構成で導入しています。実運用前に以下のセットアップを完了してください。

## 1) Firebase プロジェクト準備
- Firebase Console で新規/既存プロジェクトを用意
- Android アプリ（: ）と iOS アプリ（Bundle ID 同一）を登録
- それぞれの設定ファイルを取得して配置
  - Android: 
  - iOS: 

## 2) 依存とビルド設定
- 依存:  に  / 
- Android:  に Google Services / Crashlytics のクラスパスを追加
- Android:  でプラグイン適用（, ）
- iOS: （ ディレクトリで）



## 3) 送信可否（ビルドフラグ）
- （bool, 既定: true）。Release ビルド時のみ有効化され、Debug/Profile では送信しません。
- 例:


### スモークテスト（任意）
- 起動直後に非致命イベントを1件送信して配線確認ができます。
- フラグ: 


## 4) 初期化とハンドラ
- 初期化コード: 
- エラーハンドラ:
  - （Flutter 同期例外）
  - （非同期・フレーム外）
  - （最終ガード）
- エントリ:  で  を呼び出し

## 5) 動作確認
- リリースビルド実行後、手動で例外を起こしてレポート到達を確認（例：一時的なテストボタン、または  を適切な箇所で実行）。
- ダッシュボードの Real-time / Issues で確認。

## 6) dSYM/mapping（推奨）
- Android Release は ・ を有効化済み。Crashlytics Gradle Plugin が mapping を自動アップロードします。
- iOS は Xcode / CI で dSYM のアップロードが必要です（ の Pod がスクリプトを追加）。

## 7) プライバシー
- 本アプリではユーザ入力（メモ等）をクラッシュレポートに含めません。
- 送信可否を設定画面で切替可能にする場合は、 を SharedPreferences と連動させる実装を別途追加してください。

## 8) 既知の注意点
-  /  が無い状態で Release 実行すると初期化が失敗し、コンソールに警告が出ます（アプリ動作は継続）。
- Web ビルドでは Crashlytics を初期化しません。
