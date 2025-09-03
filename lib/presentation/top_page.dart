import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:matchnotes/infrastructure/providers.dart';
import 'package:matchnotes/domain/usecases/get_monthly_win_rates_per_game.dart';
import 'game_select_page.dart';
import 'settings_page.dart';
import 'package:table_calendar/table_calendar.dart';

class TopPage extends ConsumerStatefulWidget {
  const TopPage({super.key});

  @override
  ConsumerState<TopPage> createState() => _TopPageState();
}

class _Point {
  final int x;
  final double y;
  const _Point(this.x, this.y);
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
              edgeLabelPlacement: EdgeLabelPlacement.shift,
              majorGridLines: const MajorGridLines(width: 0),
              labelStyle: Theme.of(context).textTheme.bodySmall,
              axisLabelFormatter: (args) {
                final v = args.value.toInt();
                final last = daysInMonth;
                if (v == 1 || v == last) {
                  return ChartAxisLabel(
                    v.toString(),
                    Theme.of(context).textTheme.bodySmall!,
                  );
                }
                // 1〜最終日の範囲をおおよそ6分割してその分割点のみ表示
                final step = ((last - 1) / 6).ceil();
                if ((v - 1) % step == 0) {
                  return ChartAxisLabel(
                    v.toString(),
                    Theme.of(context).textTheme.bodySmall!,
                  );
                }
                return ChartAxisLabel(
                  '',
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
                LineSeries<_Point, num>(
                  dataSource: [
                    for (final p in series[i].points)
                      _Point(p.day.day, (p.winRate * 100)),
                  ],
                  xValueMapper: (pt, _) => pt.x,
                  yValueMapper: (pt, _) => pt.y,
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
            tooltipBehavior: TooltipBehavior(enable: true),
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
