import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:matchnotes/infrastructure/db/app_database.dart';
import 'package:matchnotes/infrastructure/db/open.dart';
import 'package:matchnotes/infrastructure/repositories/daily_character_record_repository_drift.dart';
import 'package:matchnotes/domain/repositories.dart';
import 'package:matchnotes/domain/usecases/add_win.dart';
import 'package:matchnotes/domain/usecases/add_loss.dart';
import 'package:matchnotes/domain/usecases/get_daily_game_summary.dart';
import 'package:matchnotes/domain/usecases/copy_memo_from_previous_day.dart';
import 'package:matchnotes/domain/usecases/get_monthly_win_rates_per_game.dart';
import 'package:matchnotes/domain/usecases/export_daily_records_csv.dart';
import 'package:matchnotes/domain/usecases/import_daily_records_csv.dart';

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

// Games stream provider for management UI
final watchAllGamesProvider = StreamProvider<List<GameRow>>((ref) async* {
  final db = await ref.watch(appDatabaseProvider.future);
  yield* db.watchAllGames();
});

// Single game fetch by id (for titles, etc.)
final fetchGameByIdProvider = FutureProvider.family<GameRow?, String>((
  ref,
  id,
) async {
  final db = await ref.watch(appDatabaseProvider.future);
  final q = db.select(db.games)
    ..where((t) => t.id.equals(id))
    ..limit(1);
  return q.getSingleOrNull();
});

// Characters provider
final fetchCharactersByGameProvider =
    FutureProvider.family<List<CharacterRow>, String>((ref, gameId) async {
      final db = await ref.watch(appDatabaseProvider.future);
      return db.fetchCharactersByGame(gameId);
    });

// Single character fetch by id (for titles, etc.)
final fetchCharacterByIdProvider = FutureProvider.family<CharacterRow?, String>(
  (ref, id) async {
    final db = await ref.watch(appDatabaseProvider.future);
    final q = db.select(db.characters)
      ..where((t) => t.id.equals(id))
      ..limit(1);
    return q.getSingleOrNull();
  },
);

final exportDailyRecordsCsvUsecaseProvider =
    FutureProvider<ExportDailyRecordsCsvUsecase>((ref) async {
      final repo = await ref.watch(
        dailyCharacterRecordRepositoryProvider.future,
      );
      return ExportDailyRecordsCsvUsecase(repo);
    });

final importDailyRecordsCsvUsecaseProvider =
    FutureProvider<ImportDailyRecordsCsvUsecase>((ref) async {
      final repo = await ref.watch(
        dailyCharacterRecordRepositoryProvider.future,
      );
      final db = await ref.watch(appDatabaseProvider.future);
      return ImportDailyRecordsCsvUsecase(repo, db);
    });

// Persistent Settings Keys
const _kPrefThemeMode = 'settings.themeMode'; // system|light|dark
const _kPrefKeepScreenOn = 'settings.keepScreenOn'; // bool
const _kPrefCutoffHour = 'settings.cutoffHour'; // int 0-23

String _themeModeToString(ThemeMode m) {
  switch (m) {
    case ThemeMode.light:
      return 'light';
    case ThemeMode.dark:
      return 'dark';
    case ThemeMode.system:
      return 'system';
  }
}

ThemeMode _themeModeFromString(String? s) {
  switch (s) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    case 'system':
    default:
      return ThemeMode.system;
  }
}

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPrefThemeMode);
    final loaded = _themeModeFromString(raw);
    if (loaded != state) state = loaded;
  }

  Future<void> setMode(ThemeMode m) async {
    state = m;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefThemeMode, _themeModeToString(m));
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeController, ThemeMode>(
  (ref) {
    return ThemeModeController();
  },
);

class KeepScreenOnController extends StateNotifier<bool> {
  KeepScreenOnController() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getBool(_kPrefKeepScreenOn) ?? false;
    if (v != state) state = v;
  }

  Future<void> setKeepOn(bool v) async {
    state = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPrefKeepScreenOn, v);
  }
}

final keepScreenOnProvider =
    StateNotifierProvider<KeepScreenOnController, bool>((ref) {
      return KeepScreenOnController();
    });

// Cutoff hour controller (0-23). Default 0.
class CutoffHourController extends StateNotifier<int> {
  CutoffHourController() : super(0) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getInt(_kPrefCutoffHour);
    if (v != null && v >= 0 && v <= 23 && v != state) state = v;
  }

  Future<void> setHour(int h) async {
    final clamped = h.clamp(0, 23);
    state = clamped;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kPrefCutoffHour, clamped);
  }
}

final cutoffHourProvider = StateNotifierProvider<CutoffHourController, int>((
  ref,
) {
  return CutoffHourController();
});
