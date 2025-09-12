import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

final logApp = Logger('app');
final logDb = Logger('db');
final logCsv = Logger('csv');
final logUsecase = Logger('usecase');

void configureLogging({Level? level, bool? enable}) {
  // Releaseでは常に無効。envや引数での強制有効化は不可。
  final enabledFlag =
      enable ??
      const bool.fromEnvironment('ENABLE_LOG', defaultValue: !kReleaseMode);
  final enabled = !kReleaseMode && enabledFlag;
  if (!enabled) {
    Logger.root.level = Level.OFF;
    Logger.root.onRecord.listen((_) {});
    return;
  }

  final envLevel = _levelFromEnv();
  Logger.root.level = level ?? envLevel;
  Logger.root.onRecord.listen((rec) {
    final buf = StringBuffer()
      ..write(rec.time.toIso8601String())
      ..write(' [')
      ..write(rec.level.name)
      ..write('] ')
      ..write(rec.loggerName)
      ..write(': ')
      ..write(rec.message);
    if (rec.error != null) {
      buf.write(' err=${rec.error}');
    }
    debugPrint(buf.toString());
    if (rec.stackTrace != null && !kReleaseMode) {
      debugPrint(rec.stackTrace.toString());
    }
  });
}

Level _levelFromEnv() {
  const raw = String.fromEnvironment('LOG_LEVEL', defaultValue: 'INFO');
  switch (raw.toUpperCase()) {
    case 'ALL':
      return Level.ALL;
    case 'FINEST':
      return Level.FINEST;
    case 'FINE':
      return Level.FINE;
    case 'CONFIG':
      return Level.CONFIG;
    case 'INFO':
      return Level.INFO;
    case 'WARNING':
      return Level.WARNING;
    case 'SEVERE':
      return Level.SEVERE;
    case 'OFF':
      return Level.OFF;
    default:
      return Level.INFO;
  }
}
