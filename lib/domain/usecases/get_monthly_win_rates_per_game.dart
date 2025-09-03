import 'package:collection/collection.dart';
import 'package:matchnotes/infrastructure/db/app_database.dart';
import 'package:matchnotes/domain/repositories.dart';

class DailyWinRatePoint {
  final DateTime day;
  final double winRate; // 0.0..1.0
  const DailyWinRatePoint(this.day, this.winRate);
}

class GameMonthlySeries {
  final String gameId;
  final String gameName; // fallback to gameId when unknown
  final List<DailyWinRatePoint> points; // missing days are omitted
  const GameMonthlySeries({
    required this.gameId,
    required this.gameName,
    required this.points,
  });
}

class GetMonthlyWinRatesPerGameUsecase {
  final DailyCharacterRecordRepository repo;
  final AppDatabase db; // used to resolve game names
  GetMonthlyWinRatesPerGameUsecase(this.repo, this.db);

  Future<List<GameMonthlySeries>> execute(DateTime anyDayInMonth) async {
    final start = DateTime(anyDayInMonth.year, anyDayInMonth.month, 1);
    final end = DateTime(anyDayInMonth.year, anyDayInMonth.month + 1, 0);

    final rows = await repo.findByRange(start: start, end: end);

    // group by (gameId, day)
    final byGame = groupBy(rows, (r) => r.id.gameId);

    // Resolve game names
    final gameNameMap = <String, String>{};
    final games = await db.fetchAllGames();
    for (final g in games) {
      gameNameMap[g.id] = g.name;
    }

    final result = <GameMonthlySeries>[];
    byGame.forEach((gameId, records) {
      final byDay = groupBy(records, (r) => _yyyymmddOf(r.id.date));
      final points = <DailyWinRatePoint>[];
      byDay.forEach((yyyymmdd, list) {
        final wins = list.fold<int>(0, (a, b) => a + b.wins);
        final losses = list.fold<int>(0, (a, b) => a + b.losses);
        final total = wins + losses;
        if (total <= 0) {
          return; // omit days without matches
        }
        final rate = wins / total;
        points.add(
          DailyWinRatePoint(
            DateTime(
              yyyymmdd ~/ 10000,
              (yyyymmdd % 10000) ~/ 100,
              yyyymmdd % 100,
            ),
            rate,
          ),
        );
      });
      points.sort((a, b) => a.day.compareTo(b.day));
      if (points.isNotEmpty) {
        result.add(
          GameMonthlySeries(
            gameId: gameId,
            gameName: gameNameMap[gameId] ?? gameId,
            points: points,
          ),
        );
      }
    });

    // Sort series by gameName asc for stable legend
    result.sort((a, b) => a.gameName.compareTo(b.gameName));
    return result;
  }

  int _yyyymmddOf(DateTime d) => d.year * 10000 + d.month * 100 + d.day;
}
