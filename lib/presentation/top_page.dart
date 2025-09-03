import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:matchnotes/infrastructure/providers.dart';
import 'package:matchnotes/domain/usecases/get_monthly_win_rates_per_game.dart';
import 'game_select_page.dart';
import 'settings_page.dart';

class TopPage extends ConsumerStatefulWidget {
  const TopPage({super.key});

  @override
  ConsumerState<TopPage> createState() => _TopPageState();
}

class _TopPageState extends ConsumerState<TopPage> {
  final DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd');
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
            // Calendar placeholder
            Text(
              'Calendar (focused: ${df.format(_focusedDay)})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Text('Calendar widget placeholder'),
            ),
            const SizedBox(height: 16),
            // Graph
            Text(
              'Win rate graph',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _MonthlyWinRateChart(
              month: DateTime(_focusedDay.year, _focusedDay.month, 1),
            ),
            const SizedBox(height: 16),
            // Daily rates list placeholder
            Text(
              'Daily win rates',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...List.generate(
              5,
              (i) => ListTile(
                leading: const Icon(Icons.sports_esports),
                title: Text('2025-09-${(i + 1).toString().padLeft(2, '0')}'),
                subtitle: const Text('winRate: --'),
              ),
            ),
            const SizedBox(height: 16),
            // Graph
            Text(
              'Win rate graph',
              style: Theme.of(context).textTheme.titleMedium,
            ),
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
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
    final palette = _buildPalette(context, series.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 220,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: LineChart(
            LineChartData(
              minX: 1,
              maxX: daysInMonth.toDouble(),
              minY: 0,
              maxY: 1,
              gridData: FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    interval: 0.25,
                    getTitlesWidget: (value, meta) => Text(
                      (value).toStringAsFixed(2),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: (daysInMonth / 6).ceilToDouble(),
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              lineBarsData: [
                for (var i = 0; i < series.length; i++)
                  LineChartBarData(
                    isCurved: false,
                    color: palette[i],
                    barWidth: 2,
                    dotData: FlDotData(show: true),
                    spots: series[i].points
                        .map((p) => FlSpot(p.day.day.toDouble(), p.winRate))
                        .toList(growable: false),
                  ),
              ],
              borderData: FlBorderData(show: true),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            for (var i = 0; i < series.length; i++)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: palette[i],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    series[i].gameName,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
          ],
        ),
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
