import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matchnotes/infrastructure/db/app_database.dart';
import 'package:matchnotes/infrastructure/db/open.dart';
import 'package:matchnotes/infrastructure/repositories/daily_character_record_repository_drift.dart';
import 'package:matchnotes/domain/repositories.dart';

// Async DB provider
final appDatabaseProvider = FutureProvider<AppDatabase>((ref) async {
  final db = await openAppDatabase();
  ref.onDispose(() async {
    await db.close();
  });
  return db;
});

// Repository provider depending on DB
final dailyCharacterRecordRepositoryProvider =
    FutureProvider<DailyCharacterRecordRepository>((ref) async {
      final db = await ref.watch(appDatabaseProvider.future);
      return DailyCharacterRecordRepositoryDrift(db);
    });
