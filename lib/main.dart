import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matchnotes/infrastructure/providers.dart';
import 'package:matchnotes/domain/entities.dart' as domain;
import 'package:matchnotes/presentation/top_page.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Matchnotes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const TopPage(),
    );
  }
}

class DemoPage extends ConsumerStatefulWidget {
  const DemoPage({super.key});

  @override
  ConsumerState<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends ConsumerState<DemoPage> {
  String summaryText = 'No data';
  String memoText = '-';

  final gameId = 'demo-game';
  final c1 = 'char-1';
  final c2 = 'char-2';
  DateTime get today => DateTime.now();
  Future<void> _refreshSummary() async {
    final usecase = await ref.read(getDailyGameSummaryUsecaseProvider.future);
    final s = await usecase.execute(gameId: gameId, date: today);
    setState(() {
      final wr = s.winRate;
      final wrText = wr == null ? 'n/a' : wr.toStringAsFixed(2);
      summaryText = 'wins=${s.wins}, losses=${s.losses}, winRate=$wrText';
    });
  }

  Future<void> _addWinC1() async {
    final usecase = await ref.read(addWinUsecaseProvider.future);
    await usecase.execute(gameId: gameId, characterId: c1, date: today);
    await _refreshSummary();
  }

  Future<void> _addLossC2() async {
    final usecase = await ref.read(addLossUsecaseProvider.future);
    await usecase.execute(gameId: gameId, characterId: c2, date: today);
    await _refreshSummary();
  }

  Future<void> _copyMemoFromPrevForC1() async {
    final copy = await ref.read(copyMemoFromPreviousDayUsecaseProvider.future);
    await copy.execute(gameId: gameId, characterId: c1, date: today);

    final repo = await ref.read(dailyCharacterRecordRepositoryProvider.future);
    final id = domain.DailyCharacterRecordId(
      gameId: gameId,
      characterId: c1,
      date: DateTime(today.year, today.month, today.day),
    );
    final rec = await repo.findById(id);
    setState(() {
      memoText = rec?.memo ?? '-';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Matchnotes Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Summary: $summaryText'),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _addWinC1,
                  child: const Text('Add Win (c1)'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addLossC2,
                  child: const Text('Add Loss (c2)'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _refreshSummary,
                  child: const Text('Refresh Summary'),
                ),
              ],
            ),
            const Divider(height: 24),
            Text('Today memo (c1): $memoText'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _copyMemoFromPrevForC1,
              child: const Text('Copy memo from previous day (c1)'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tip: create a previous day record for c1 with a memo to test copy.',
            ),
          ],
        ),
      ),
    );
  }
}
