import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matchnotes/domain/usecases/get_monthly_win_rates_per_game.dart';
import 'package:matchnotes/infrastructure/providers.dart';
import 'package:matchnotes/presentation/x_axis_labels.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:table_calendar/table_calendar.dart';

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
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matchnotes'),
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
            // Calendar
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(8),
              child: TableCalendar(
                focusedDay: _focusedDay,
                firstDay: DateTime.utc(2000, 1, 1),
                lastDay: DateTime.utc(2100, 12, 31),
                headerStyle: const HeaderStyle(formatButtonVisible: false),
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                },
                onPageChanged: (focused) {
                  setState(() => _focusedDay = focused);
                },
                calendarFormat: CalendarFormat.month,
              ),
            ),
            const SizedBox(height: 16),
            // Graph
            Text('日別勝率グラフ %', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _MonthlyWinRateChart(
              month: DateTime(_focusedDay.year, _focusedDay.month, 1),
            ),
            const SizedBox(height: 16),
            // Navigation to Game Select
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
