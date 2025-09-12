import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:drift/native.dart';
import 'package:drift_sqflite/drift_sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_database.dart';
import '../logging/logger.dart';

Future<AppDatabase> openAppDatabase({bool? logStatements}) async {
  final dbPath = await _resolveDbPath();
  // DBのSQLログはRelease既定オフ。--dart-define=DB_LOG_SQL=true で有効化可能。
  final sqlLogFlag =
      logStatements ??
      const bool.fromEnvironment('DB_LOG_SQL', defaultValue: false);
  final enableSqlLog = !kReleaseMode && sqlLogFlag; // Releaseでは常に無効

  // Mobile: use sqflite executor
  if (Platform.isAndroid || Platform.isIOS) {
    final executor = SqfliteQueryExecutor(
      path: dbPath,
      logStatements: enableSqlLog,
    );
    logDb.info('open AppDatabase(sqflite): path=$dbPath, logSQL=$enableSqlLog');
    return AppDatabase(executor);
  }

  // Desktop: use NativeDatabase (drift/native)
  final dbFile = File(dbPath);
  logDb.info('open AppDatabase(native): path=$dbPath');
  return AppDatabase(NativeDatabase.createInBackground(dbFile));
}

Future<String> _resolveDbPath() async {
  Directory baseDir;
  try {
    // Prefer application support directory when available
    baseDir = await getApplicationSupportDirectory();
  } catch (_) {
    // Fallbacks per platform
    if (Platform.isLinux) {
      final home = Platform.environment['HOME'] ?? '.';
      baseDir = Directory(p.join(home, '.local', 'share', 'matchnotes'));
    } else if (Platform.isMacOS) {
      final home = Platform.environment['HOME'] ?? '.';
      baseDir = Directory(
        p.join(home, 'Library', 'Application Support', 'matchnotes'),
      );
    } else if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'] ?? '.';
      baseDir = Directory(p.join(appData, 'matchnotes'));
    } else {
      // As a last resort, use current directory
      baseDir = Directory('matchnotes_data');
    }
  }

  if (!await baseDir.exists()) {
    await baseDir.create(recursive: true);
  }
  return p.join(baseDir.path, 'matchnotes.db');
}
