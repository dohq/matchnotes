import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Crashlytics 初期化とハンドラ登録の薄いラッパ。
/// - Web/デスクトップでは Crashlytics をスキップ
/// - 例外時もアプリ起動を妨げない
class CrashReporter {
  CrashReporter(this._enabled);

  final bool _enabled;
  bool _initialized = false;

  bool get isEnabled => _enabled && _initialized;

  Future<void> init() async {
    if (!_enabled) return;
    // Web は未対応、Android/iOS/macOS のみ対象
    if (kIsWeb) return;
    try {
      // Firebase 初期化（既に初期化済みでも安全）
      await Firebase.initializeApp();
      // Debug/テストでは送信オフ（冗長送信を避ける）
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        !kDebugMode,
      );

      // Flutter の同期エラー
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        // fatal 扱い
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      };

      // ゾーン外の非同期エラー（Engine レベル）
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(
          error,
          stack,
          fatal: true,
          printDetails: true,
        );
        return true; // 既定のクラッシュを抑止
      };

      _initialized = true;
    } catch (e, st) {
      // 初期化失敗時はコンソールに残して継続
      debugPrint('Crashlytics init failed: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  void recordNonFatal(Object error, StackTrace? stack) {
    if (!isEnabled) return;
    FirebaseCrashlytics.instance.recordError(
      error,
      stack,
      fatal: false,
      printDetails: kDebugMode,
    );
  }
}

/// `runApp` をクラッシュレポート付きでラップ実行するヘルパ。
Future<void> runWithCrashReporting({
  required Widget app,
  required bool enableCrashlytics,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  final reporter = CrashReporter(enableCrashlytics);
  await reporter.init();

  // ゾーンの最終ガード（Flutter 外例外）
  await runZonedGuarded(
    () async {
      runApp(app);
    },
    (error, stack) {
      reporter.recordNonFatal(error, stack);
    },
  );
}
