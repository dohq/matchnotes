import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:matchnotes/infrastructure/providers.dart';
import 'package:matchnotes/domain/date_utils.dart';
import 'package:matchnotes/domain/entities.dart' as domain;

class DailyPage extends ConsumerStatefulWidget {
  const DailyPage({super.key});

  @override
  ConsumerState<DailyPage> createState() => _DailyPageState();
}

class _DailyPageState extends ConsumerState<DailyPage> {
  final _gameIdCtl = TextEditingController(text: 'demo-game');
  final _charIdCtl = TextEditingController(text: 'char-1');
  DateTime _date = DateTime.now();

  int _wins = 0;
  int _losses = 0;
  String? _memo;
  String _summary = 'wins=0, losses=0, winRate=n/a';
  final TextEditingController _memoCtl = TextEditingController();

  bool _busy = false;
  List<domain.DailyCharacterRecord> _dailyList = const [];
  bool _initialized = false;

  String get gameId => _gameIdCtl.text.trim();
  String get charId => _charIdCtl.text.trim();
  DateTime get day {
    final cutoff = ref.read(cutoffHourProvider);
    return truncateWithCutoff(_date, cutoff);
  }

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    setState(() => _busy = true);
    try {
      await Future.wait([_refreshSummary(), _refreshRecord(), _refreshList()]);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _initialized = true;
        });
      }
    }
  }

  Future<void> _refreshSummary() async {
    final usecase = await ref.read(getDailyGameSummaryUsecaseProvider.future);
    final s = await usecase.execute(gameId: gameId, date: day);
    final wr = s.winRate;
    final wrText = wr == null ? 'n/a' : wr.toStringAsFixed(2);
    setState(() {
      _summary = 'wins=${s.wins}, losses=${s.losses}, winRate=$wrText';
    });
  }

  Future<void> _refreshRecord() async {
    final repo = await ref.read(dailyCharacterRecordRepositoryProvider.future);
    final rec = await repo.findById(
      domain.DailyCharacterRecordId(
        gameId: gameId,
        characterId: charId,
        date: day,
      ),
    );
    setState(() {
      _wins = rec?.wins ?? 0;
      _losses = rec?.losses ?? 0;
      _memo = rec?.memo;
      _memoCtl.text = _memo ?? '';
    });
  }

  Future<void> _refreshList() async {
    final repo = await ref.read(dailyCharacterRecordRepositoryProvider.future);
    final list = await repo.findByGameAndDay(gameId: gameId, day: day);
    setState(() => _dailyList = list);
  }

  Future<void> _addWin() async {
    setState(() => _busy = true);
    try {
      final addWin = await ref.read(addWinUsecaseProvider.future);
      await addWin.execute(gameId: gameId, characterId: charId, date: day);
      await _refreshAll();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addLoss() async {
    setState(() => _busy = true);
    try {
      final addLoss = await ref.read(addLossUsecaseProvider.future);
      await addLoss.execute(gameId: gameId, characterId: charId, date: day);
      await _refreshAll();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveMemo() async {
    setState(() => _busy = true);
    try {
      final repo = await ref.read(
        dailyCharacterRecordRepositoryProvider.future,
      );
      final id = domain.DailyCharacterRecordId(
        gameId: gameId,
        characterId: charId,
        date: day,
      );
      final current =
          await repo.findById(id) ??
          domain.DailyCharacterRecord(id: id, wins: 0, losses: 0, memo: null);
      await repo.upsert(current.copyWith(memo: _memo));
      await _refreshRecord();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Memo saved.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copyMemoFromPrev() async {
    setState(() => _busy = true);
    try {
      final copy = await ref.read(
        copyMemoFromPreviousDayUsecaseProvider.future,
      );
      await copy.execute(gameId: gameId, characterId: charId, date: day);
      await _refreshRecord();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Copied from previous day.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _date = picked);
      await _refreshAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd');
    if (!_initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Records'),
        actions: [
          if (_busy)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _gameIdCtl,
                    decoration: const InputDecoration(labelText: 'Game ID'),
                    onSubmitted: (_) => _refreshAll(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _charIdCtl,
                    decoration: const InputDecoration(
                      labelText: 'Character ID',
                    ),
                    onSubmitted: (_) => _refreshAll(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Date: ${df.format(day)}'),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: _pickDate, child: const Text('Pick')),
                const Spacer(),
                OutlinedButton(
                  onPressed: _refreshAll,
                  child: const Text('Refresh'),
                ),
              ],
            ),
            const Divider(height: 24),
            Text('Summary: $_summary'),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _addWin,
                  child: const Text('Add Win'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addLoss,
                  child: const Text('Add Loss'),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              'Record ($gameId/$charId @ ${df.format(day)}): wins=$_wins, losses=$_losses',
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(labelText: 'Memo'),
              minLines: 1,
              maxLines: 3,
              controller: _memoCtl,
              onChanged: (v) => _memo = v.isEmpty ? null : v,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _busy ? null : _saveMemo,
                  child: const Text('Save Memo'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _busy ? null : _copyMemoFromPrev,
                  child: const Text('Copy Memo from Previous Day'),
                ),
              ],
            ),
            const Divider(height: 24),
            Text('Today list (${df.format(day)}):'),
            const SizedBox(height: 8),
            ..._dailyList.map(
              (e) => ListTile(
                title: Text(e.id.characterId),
                subtitle: Text(
                  'wins=${e.wins}, losses=${e.losses}\n${e.memo ?? ''}',
                ),
                isThreeLine: (e.memo ?? '').isNotEmpty,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
