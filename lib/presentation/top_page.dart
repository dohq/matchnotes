import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matchnotes/domain/usecases/get_monthly_win_rates_per_game.dart';
import 'package:matchnotes/infrastructure/providers.dart';
import 'package:matchnotes/presentation/x_axis_labels.dart';
import 'package:matchnotes/infrastructure/db/app_database.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'game_select_page.dart';
import 'settings_page.dart';

class TopPage extends ConsumerStatefulWidget {
  const TopPage({super.key});

  @override
  ConsumerState<TopPage> createState() => _TopPageState();
}

class _PlottedPoint {
  final int day; // 1..31
  final double pct; // 0..100
  final GameMonthlySeries series; // owning series
  final DailyWinRatePoint source; // original aggregated point
  const _PlottedPoint({
    required this.day,
    required this.pct,
    required this.series,
    required this.source,
  });
}

class _TopPageState extends ConsumerState<TopPage> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);

  bool get _isNextDisabled {
    final now = DateTime(DateTime.now().year, DateTime.now().month, 1);
    return _month.year == now.year && _month.month == now.month;
  }

  void _prevMonth() {
    setState(() => _month = DateTime(_month.year, _month.month - 1, 1));
  }

  void _nextMonth() {
    final now = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final candidate = DateTime(_month.year, _month.month + 1, 1);
    if (candidate.isAfter(now)) return; // 当月以降には進まない
    setState(() => _month = candidate);
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    return Scaffold(
      appBar: AppBar(
        title: const Text('MatchNotes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsPage())),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // 今日のサマリ
            Text('今日のサマリ', style: titleStyle),
            const SizedBox(height: 8),
            _TodaySummaryCard(date: DateTime.now()),
            const SizedBox(height: 16),
            // 直近7日のトレンド
            Text('直近7日のトレンド', style: titleStyle),
            const SizedBox(height: 8),
            const _SevenDayTrendCard(),
            const SizedBox(height: 16),
            // 月のトレンド（切替可能）
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('月のトレンド', style: titleStyle),
                Row(
                  children: [
                    IconButton(
                      onPressed: _prevMonth,
                      icon: const Icon(Icons.chevron_left),
                      tooltip: '前月',
                    ),
                    Text(
                      '${_month.year}/${_month.month.toString().padLeft(2, '0')}',
                    ),
                    IconButton(
                      onPressed: _isNextDisabled ? null : _nextMonth,
                      icon: const Icon(Icons.chevron_right),
                      tooltip: '翌月',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            _MonthlyWinRateChart(month: _month),
            const SizedBox(height: 16),
            // ゲーム選択へ（ナビ近道は維持）
            FilledButton.icon(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const GameSelectPage())),
              icon: const Icon(Icons.list),
              label: const Text('ゲーム選択へ'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodaySummaryCard extends ConsumerWidget {
  final DateTime date;
  const _TodaySummaryCard({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUsecase = ref.watch(getMonthlyWinRatesPerGameUsecaseProvider);
    return asyncUsecase.when(
      loading: () => _skeleton(context),
      error: (e, st) => _errorBox(context, e),
      data: (usecase) {
        // 月単位の集計から当日分を抽出（ゲーム別 + キャラ別内訳も利用）
        return FutureBuilder<List<GameMonthlySeries>>(
          future: usecase.execute(DateTime(date.year, date.month, 1)),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return _skeleton(context);
            final series = snapshot.data!;
            final today = DateTime(date.year, date.month, date.day);
            // ゲーム別に当日のポイントを抽出
            final items = <_TodayGameRow>[];
            for (final s in series) {
              final pt = s.points.firstWhere(
                (p) =>
                    p.day.year == today.year &&
                    p.day.month == today.month &&
                    p.day.day == today.day,
                orElse: () => DailyWinRatePoint(
                  day: DateTime(1970),
                  winRate: 0,
                  wins: 0,
                  losses: 0,
                  byCharacter: {},
                ),
              );
              final total = pt.wins + pt.losses;
              if (total > 0) {
                items.add(
                  _TodayGameRow(
                    gameName: s.gameName,
                    wins: pt.wins,
                    losses: pt.losses,
                    byCharacter: pt.byCharacter,
                  ),
                );
              }
            }
            items.sort(
              (a, b) => (b.wins + b.losses).compareTo(a.wins + a.losses),
            );
            if (items.isEmpty) {
              return _emptyBox(context, '当日の対戦はありません');
            }
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final row = items[index];
                  final total = row.wins + row.losses;
                  final rate = total == 0 ? 0 : (row.wins / total) * 100;
                  return ExpansionTile(
                    title: Text(row.gameName),
                    subtitle: Text(
                      '合計 $total / 勝 ${row.wins} / 負 ${row.losses} / ${rate.toStringAsFixed(1)}%',
                    ),
                    children: [
                      if (row.byCharacter.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            'キャラ別データなし',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            children: [
                              for (final e
                                  in row.byCharacter.entries.toList()..sort(
                                    (a, b) => (b.value.total).compareTo(
                                      a.value.total,
                                    ),
                                  ))
                                ListTile(
                                  dense: true,
                                  title: Text(e.key),
                                  subtitle: Text(
                                    '合計 ${e.value.total} / 勝 ${e.value.wins} / 負 ${e.value.losses} / '
                                    '${(e.value.rate * 100).toStringAsFixed(1)}%',
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _skeleton(BuildContext context) => Container(
    height: 96,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
    ),
    alignment: Alignment.center,
    child: const CircularProgressIndicator.adaptive(),
  );

  Widget _errorBox(BuildContext context, Object e) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text('読み込みエラー: $e'),
  );

  Widget _emptyBox(BuildContext context, String msg) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(msg),
  );
}

class _TodayGameRow {
  final String gameName;
  final int wins;
  final int losses;
  final Map<String, CharWinLoss> byCharacter;
  _TodayGameRow({
    required this.gameName,
    required this.wins,
    required this.losses,
    required this.byCharacter,
  });
}

class _SevenDayTrendCard extends ConsumerWidget {
  const _SevenDayTrendCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbAsync = ref.watch(appDatabaseProvider);
    return dbAsync.when(
      loading: () => _skeleton(context),
      error: (e, st) => _sevenErrorBox(context, e),
      data: (db) {
        final today = DateTime.now();
        final start = DateTime(
          today.year,
          today.month,
          today.day,
        ).subtract(const Duration(days: 6));
        final end = DateTime(today.year, today.month, today.day);
        return StreamBuilder(
          stream: db.watchByRange(start: start, end: end),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return _skeleton(context);
            final rows = snapshot.data!;
            final points = _aggregateSevenDays(rows, start);
            if (points.isEmpty) return _emptyBox(context, 'データがありません');
            return Container(
              height: 160,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SfCartesianChart(
                plotAreaBorderWidth: 0,
                primaryXAxis: DateTimeAxis(
                  intervalType: DateTimeIntervalType.days,
                  dateFormat: null,
                  majorGridLines: const MajorGridLines(width: 0),
                ),
                primaryYAxis: NumericAxis(
                  minimum: 0,
                  maximum: 100,
                  interval: 25,
                  axisLabelFormatter: (args) => ChartAxisLabel(
                    '${args.value.toInt()}%',
                    Theme.of(context).textTheme.bodySmall!,
                  ),
                ),
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  builder:
                      (
                        dynamic data,
                        dynamic point,
                        dynamic seriesWidget,
                        int pointIndex,
                        int seriesIndex,
                      ) {
                        final sp = data as _SevenPoint;
                        String fmtPct(double v) => v.toStringAsFixed(1);
                        final rows = <Widget>[];
                        // Header: date
                        rows.add(
                          Text(
                            '${sp.day.month}/${sp.day.day}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        );
                        rows.add(const SizedBox(height: 4));
                        final win = sp.wins;
                        final loss = sp.losses;
                        final total = win + loss;
                        final pct = sp.pct;
                        rows.add(
                          Text(
                            '合算: Total:$total  Win:$win  Loss:$loss (${fmtPct(pct)}%)',
                          ),
                        );
                        return Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: rows,
                          ),
                        );
                      },
                ),
                series: [
                  LineSeries<_SevenPoint, DateTime>(
                    dataSource: points,
                    xValueMapper: (p, _) => p.day,
                    yValueMapper: (p, _) => p.pct,
                    color: Colors.blue,
                    width: 2,
                    markerSettings: const MarkerSettings(
                      isVisible: true,
                      width: 3,
                      height: 3,
                    ),
                    name: 'Win% (7d)',
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<_SevenPoint> _aggregateSevenDays(
    List<DailyCharacterRecordRow> rows,
    DateTime start,
  ) {
    // 集計（全ゲーム合算、日単位）
    final map = <int, _SevenPoint>{};
    for (final r in rows) {
      final ymd = r.yyyymmdd;
      final y = ymd ~/ 10000;
      final m = (ymd % 10000) ~/ 100;
      final d0 = ymd % 100;
      final d = DateTime(y, m, d0);
      final key = d.millisecondsSinceEpoch;
      final cur = map[key];
      final w = (cur?.wins ?? 0) + r.wins;
      final l = (cur?.losses ?? 0) + r.losses;
      map[key] = _SevenPoint(day: d, wins: w, losses: l);
    }
    final sorted = map.values.toList()..sort((a, b) => a.day.compareTo(b.day));
    // 試合がない日はプロットしない
    return [
      for (final e in sorted)
        if (e.wins + e.losses > 0)
          _SevenPoint(day: e.day, wins: e.wins, losses: e.losses),
    ];
  }

  Widget _sevenErrorBox(BuildContext context, Object e) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text('読み込みエラー: $e'),
  );

  Widget _skeleton(BuildContext context) => Container(
    height: 160,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
    ),
    alignment: Alignment.center,
    child: const CircularProgressIndicator.adaptive(),
  );

  Widget _emptyBox(BuildContext context, String msg) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(msg),
  );
}

class _SevenPoint {
  final DateTime day;
  final int wins;
  final int losses;
  _SevenPoint({required this.day, required this.wins, required this.losses});
  double get rate => (wins + losses) == 0 ? 0 : wins / (wins + losses);
  double get pct => rate * 100;
}

class _MonthlyWinRateChart extends ConsumerWidget {
  final DateTime month; // 1日固定
  const _MonthlyWinRateChart({required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUsecase = ref.watch(getMonthlyWinRatesPerGameUsecaseProvider);
    return asyncUsecase.when(
      loading: () => _skeleton(context),
      error: (e, st) => _errorBox(context, e),
      data: (usecase) {
        return FutureBuilder<List<GameMonthlySeries>>(
          future: usecase.execute(month),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return _skeleton(context);
            }
            final series = snapshot.data!;
            return _ChartWithLegend(series: series, month: month);
          },
        );
      },
    );
  }

  Widget _skeleton(BuildContext context) => Container(
    height: 220,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
    ),
    alignment: Alignment.center,
    child: const CircularProgressIndicator.adaptive(),
  );

  Widget _errorBox(BuildContext context, Object e) => Container(
    height: 220,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(12),
    ),
    alignment: Alignment.center,
    child: Text('読み込みエラー: $e'),
  );
}

class _ChartWithLegend extends StatelessWidget {
  final List<GameMonthlySeries> series;
  final DateTime month;
  const _ChartWithLegend({required this.series, required this.month});

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // X軸は常に1日から開始し、月の日数に応じて見やすい間隔に調整
    // 表示は常に1〜最終日。メモリは1刻みだが、表示するラベルは約6個になるよう間引く。
    // これにより「1」と「最終日(30/31)」の両方を必ず表示できる。
    final double xMin = 1;
    final palette = _buildPalette(context, series.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 220,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SfCartesianChart(
            plotAreaBorderWidth: 0,
            legend: const Legend(
              isVisible: true,
              overflowMode: LegendItemOverflowMode.wrap,
            ),
            primaryXAxis: NumericAxis(
              minimum: xMin,
              maximum: daysInMonth.toDouble(),
              interval: 1,
              edgeLabelPlacement: EdgeLabelPlacement.none,
              rangePadding: ChartRangePadding.none,
              labelIntersectAction: AxisLabelIntersectAction.none,
              majorGridLines: const MajorGridLines(width: 0),
              labelStyle: Theme.of(context).textTheme.bodySmall,
              axisLabelFormatter: (args) {
                final v = args.value.toInt();
                final show = shouldShowXAxisLabel(v, daysInMonth);
                return ChartAxisLabel(
                  show ? v.toString() : '',
                  Theme.of(context).textTheme.bodySmall!,
                );
              },
            ),
            primaryYAxis: NumericAxis(
              minimum: 0,
              maximum: 100,
              interval: 25,
              axisLabelFormatter: (args) => ChartAxisLabel(
                '${args.value.toInt()}%',
                Theme.of(context).textTheme.bodySmall!,
              ),
            ),
            series: [
              for (var i = 0; i < series.length; i++)
                LineSeries<_PlottedPoint, num>(
                  dataSource: [
                    for (final p in series[i].points)
                      _PlottedPoint(
                        day: p.day.day,
                        pct: p.winRate * 100,
                        series: series[i],
                        source: p,
                      ),
                  ],
                  xValueMapper: (pt, _) => pt.day,
                  yValueMapper: (pt, _) => pt.pct,
                  color: palette[i],
                  width: 2,
                  markerSettings: const MarkerSettings(
                    isVisible: true,
                    width: 4,
                    height: 4,
                  ),
                  name: series[i].gameName,
                ),
            ],
            tooltipBehavior: TooltipBehavior(
              enable: true,
              builder:
                  (
                    dynamic data,
                    dynamic point,
                    dynamic seriesWidget,
                    int pointIndex,
                    int seriesIndex,
                  ) {
                    final pp = data as _PlottedPoint;
                    final d = pp.source.day;
                    String fmtPct(double v) => v.toStringAsFixed(1);
                    final rows = <Widget>[];
                    // Header: Game name and date
                    rows.add(
                      Text(
                        '${pp.series.gameName}  ${d.month}/${d.day}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                    rows.add(const SizedBox(height: 4));
                    // Combined
                    final win = pp.source.wins;
                    final loss = pp.source.losses;
                    final total = win + loss;
                    final rate = pp.source.winRate * 100;
                    rows.add(
                      Text(
                        '合算: Total:$total: Win:$win Loss:$loss (${fmtPct(rate)}%)',
                      ),
                    );
                    // Per character (only ones with records)
                    final entries = pp.source.byCharacter.entries.toList()
                      ..sort(
                        (a, b) => (b.value.total).compareTo(a.value.total),
                      );
                    for (final e in entries) {
                      final cw = e.value.wins;
                      final cl = e.value.losses;
                      final total = cw + cl;
                      final rate = e.value.rate * 100;
                      rows.add(
                        Text(
                          '${e.key} Total:$total: Win:$cw Loss:$cl (${fmtPct(rate)}%)',
                        ),
                      );
                    }
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: rows,
                      ),
                    );
                  },
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  List<Color> _buildPalette(BuildContext context, int n) {
    final base = <Color>[
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.brown,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
    ];
    final out = <Color>[];
    for (var i = 0; i < n; i++) {
      out.add(base[i % base.length]);
    }
    return out;
  }
}
