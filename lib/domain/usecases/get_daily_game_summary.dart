import '../repositories.dart';

class DailyGameSummary {
  final int wins;
  final int losses;
  const DailyGameSummary({required this.wins, required this.losses});
  double? get winRate => (wins + losses) == 0 ? null : wins / (wins + losses);
}

class GetDailyGameSummaryUsecase {
  final DailyCharacterRecordRepository repo;
  GetDailyGameSummaryUsecase(this.repo);

  Future<DailyGameSummary> execute({
    required String gameId,
    required DateTime date,
  }) async {
    final day = DateTime(date.year, date.month, date.day);
    final records = await repo.findByGameAndDay(gameId: gameId, day: day);
    var w = 0;
    var l = 0;
    for (final r in records) {
      w += r.wins;
      l += r.losses;
    }
    return DailyGameSummary(wins: w, losses: l);
  }
}
