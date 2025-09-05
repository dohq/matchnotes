import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities.dart' as domain;
import '../infrastructure/providers.dart';
import 'memo_page.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class RegisterPage extends ConsumerStatefulWidget {
  final String gameId;
  final String characterId;
  const RegisterPage({
    super.key,
    required this.gameId,
    required this.characterId,
  });

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final DateTime _date = DateTime.now();
  int _wins = 0;
  int _losses = 0;
  bool _busy = false;
  final _undo = <Future<void> Function()>[]; // simple undo stack

  String get gameId => widget.gameId;
  String get charId => widget.characterId;
  DateTime get day => DateTime(_date.year, _date.month, _date.day);

  @override
  void initState() {
    super.initState();
    // keepScreenOnProvider の値に応じて画面ロック防止を切り替える
    // 初期値反映
    final keepOn = ref.read(keepScreenOnProvider);
    if (keepOn) {
      // ignore: discarded_futures
      WakelockPlus.enable();
    } else {
      // ignore: discarded_futures
      WakelockPlus.disable();
    }
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _busy = true);
    try {
      final repo = await ref.read(
        dailyCharacterRecordRepositoryProvider.future,
      );
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
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _incWin() async {
    setState(() => _busy = true);
    try {
      final addWin = await ref.read(addWinUsecaseProvider.future);
      await addWin.execute(gameId: gameId, characterId: charId, date: day);
      // TopPage のサマリ/トレンド再読込のために invalidate
      ref.invalidate(getMonthlyWinRatesPerGameUsecaseProvider);
      ref.invalidate(dailyCharacterRecordRepositoryProvider);
      _undo.add(() async {
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
        await repo.upsert(
          current.copyWith(wins: (current.wins - 1).clamp(0, 1 << 31)),
        );
      });
      await _refresh();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _incLoss() async {
    setState(() => _busy = true);
    try {
      final addLoss = await ref.read(addLossUsecaseProvider.future);
      await addLoss.execute(gameId: gameId, characterId: charId, date: day);
      // TopPage のサマリ/トレンド再読込のために invalidate
      ref.invalidate(getMonthlyWinRatesPerGameUsecaseProvider);
      ref.invalidate(dailyCharacterRecordRepositoryProvider);
      _undo.add(() async {
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
        await repo.upsert(
          current.copyWith(losses: (current.losses - 1).clamp(0, 1 << 31)),
        );
      });
      await _refresh();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _undoLast() async {
    if (_undo.isEmpty) return;
    setState(() => _busy = true);
    final op = _undo.removeLast();
    try {
      await op();
      // 取り消し後も最新にする
      ref.invalidate(getMonthlyWinRatesPerGameUsecaseProvider);
      ref.invalidate(dailyCharacterRecordRepositoryProvider);
      await _refresh();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    // ページ離脱時は必ず wakelock を解除する
    // ignore: discarded_futures
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 設定の変更を監視（build 内で listen する必要がある）
    ref.listen<bool>(keepScreenOnProvider, (prev, next) {
      if (next) {
        // ignore: discarded_futures
        WakelockPlus.enable();
      } else {
        // ignore: discarded_futures
        WakelockPlus.disable();
      }
    });
    final gameAsync = ref.watch(fetchGameByIdProvider(gameId));
    final charAsync = ref.watch(fetchCharacterByIdProvider(charId));
    // どちらかが読み込み中ならローディング
    if (gameAsync.isLoading || charAsync.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      );
    }
    // どちらかがエラーなら表示
    if (gameAsync.hasError || charAsync.hasError) {
      final ge = gameAsync.error;
      final ce = charAsync.error;
      return Scaffold(body: Center(child: Text('読み込みエラー: ${ge ?? ce}')));
    }
    final game = gameAsync.asData?.value;
    final character = charAsync.asData?.value;
    if (game == null || character == null) {
      return const Scaffold(body: Center(child: Text('データが見つかりません')));
    }
    final gameName = game.name;
    final charName = character.name;
    final df = DateFormat('yyyy-MM-dd');
    final wr = (_wins + _losses) == 0 ? null : _wins / (_wins + _losses);
    final wrText = wr == null ? 'n/a' : wr.toStringAsFixed(2);
    return Scaffold(
      appBar: AppBar(title: Text('登録: $gameName/$charName')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('今日の勝率: $wrText'),
            const SizedBox(height: 8),
            Text('日付: ${df.format(day)}'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: _busy ? null : _incWin,
                  icon: const Icon(Icons.thumb_up),
                  label: const Text('勝利+1'),
                ),
                FilledButton.icon(
                  onPressed: _busy ? null : _incLoss,
                  icon: const Icon(Icons.thumb_down),
                  label: const Text('負け+1'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _undoLast,
                  icon: const Icon(Icons.undo),
                  label: const Text('Undo'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder: (_) => MemoPage(
                                  gameId: gameId,
                                  characterId: charId,
                                  date: day,
                                ),
                              ),
                            )
                            .then((_) => _refresh()),
                  icon: const Icon(Icons.note),
                  label: const Text('メモ'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_busy) const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
