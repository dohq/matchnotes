import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matchnotes/infrastructure/db/app_database.dart';
import 'package:matchnotes/infrastructure/db/open.dart';
import 'package:matchnotes/infrastructure/repositories/daily_character_record_repository_drift.dart';
import 'package:matchnotes/domain/repositories.dart';
import 'package:matchnotes/domain/usecases/add_win.dart';
import 'package:matchnotes/domain/usecases/add_loss.dart';
import 'package:matchnotes/domain/usecases/get_daily_game_summary.dart';
import 'package:matchnotes/domain/usecases/copy_memo_from_previous_day.dart';
import 'package:matchnotes/domain/usecases/get_monthly_win_rates_per_game.dart';

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

// Usecase providers
final addWinUsecaseProvider = FutureProvider<AddWinUsecase>((ref) async {
  final repo = await ref.watch(dailyCharacterRecordRepositoryProvider.future);
  return AddWinUsecase(repo);
});

final addLossUsecaseProvider = FutureProvider<AddLossUsecase>((ref) async {
  final repo = await ref.watch(dailyCharacterRecordRepositoryProvider.future);
  return AddLossUsecase(repo);
});

final getDailyGameSummaryUsecaseProvider =
    FutureProvider<GetDailyGameSummaryUsecase>((ref) async {
      final repo = await ref.watch(
        dailyCharacterRecordRepositoryProvider.future,
      );
      return GetDailyGameSummaryUsecase(repo);
    });

final copyMemoFromPreviousDayUsecaseProvider =
    FutureProvider<CopyMemoFromPreviousDayUsecase>((ref) async {
      final repo = await ref.watch(
        dailyCharacterRecordRepositoryProvider.future,
      );
      return CopyMemoFromPreviousDayUsecase(repo);
    });

final getMonthlyWinRatesPerGameUsecaseProvider =
    FutureProvider<GetMonthlyWinRatesPerGameUsecase>((ref) async {
      final repo = await ref.watch(
        dailyCharacterRecordRepositoryProvider.future,
      );
      final db = await ref.watch(appDatabaseProvider.future);
      return GetMonthlyWinRatesPerGameUsecase(repo, db);
    });
