import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../domain/entities.dart' as domain;
import '../infrastructure/providers.dart';
import 'memo_page.dart';

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
  String? _memo;

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
        _memo = rec?.memo;
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
    ButtonStyle winButtonStyle(BuildContext context) {
      final cs = Theme.of(context).colorScheme;
      return FilledButton.styleFrom(
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 24),
      );
    }

    ButtonStyle lossButtonStyle(BuildContext context) {
      final cs = Theme.of(context).colorScheme;
      return FilledButton.styleFrom(
        backgroundColor: cs.errorContainer,
        foregroundColor: cs.onErrorContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 24),
      );
    }

    Widget statTile({required String label, required String value}) {
      final textTheme = Theme.of(context).textTheme;
      final cs = Theme.of(context).colorScheme;
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              value,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

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
    final wrPercent = wr == null ? null : (wr * 100);
    final wrText = wrPercent == null
        ? 'n/a'
        : '${wrPercent.toStringAsFixed(1)}%';

    void showSnack(String msg) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(msg),
            duration: const Duration(milliseconds: 800),
          ),
        );
    }

    Future<void> onWinTap() async {
      if (_busy) return;
      HapticFeedback.lightImpact();
      await _incWin();
      showSnack('勝+1');
    }

    Future<void> onLossTap() async {
      if (_busy) return;
      HapticFeedback.lightImpact();
      await _incLoss();
      showSnack('負+1');
    }

    Future<void> onUndoTap() async {
      if (_busy) return;
      HapticFeedback.selectionClick();
      await _undoLast();
      showSnack('Undoしました');
    }

    Future<void> onMemoTap() async {
      if (_busy) return;
      HapticFeedback.selectionClick();
      await Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (_) =>
                  MemoPage(gameId: gameId, characterId: charId, date: day),
            ),
          )
          .then((_) => _refresh());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('登録')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダ情報（上：日付 中央、中央：巨大勝率、下：合計/勝/負の3分割）
            // 日付（中央・大きめ）
            Center(
              child: Text(
                df.format(day),
                style:
                    Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ) ??
                    const TextStyle(fontSize: 34, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 6),
            // ゲーム名/キャラ名（中央・横幅の約2/3に合わせて拡大縮小）
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: FractionallySizedBox(
                  widthFactor: 0.66,
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: Text(
                      '$gameName / $charName',
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 120, // FittedBoxで縮小
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            // 勝率（横幅いっぱいに近いサイズで自動縮小）
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Builder(
                  builder: (context) {
                    final hasPercent = wrText.trim().endsWith('%');
                    final numberPart = hasPercent
                        ? wrText.trim().substring(0, wrText.trim().length - 1)
                        : wrText.trim();
                    return RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style.copyWith(
                          fontSize: 200,
                          fontWeight: FontWeight.w900,
                        ),
                        children: [
                          TextSpan(text: numberPart),
                          if (hasPercent)
                            const TextSpan(
                              text: '%',
                              style: TextStyle(
                                fontSize: 100, // 数字よりやや小さく
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: statTile(
                    label: '合計',
                    value: (_wins + _losses).toString(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: statTile(label: '勝', value: _wins.toString()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: statTile(label: '負', value: _losses.toString()),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // メモ表示エリア（長文時はスクロール。残りの空き高さをすべて使用）
            Builder(
              builder: (context) {
                final theme = Theme.of(context);
                final cs = theme.colorScheme;
                final textTheme = theme.textTheme;
                final hasMemo = (_memo != null && _memo!.trim().isNotEmpty);
                return Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        hasMemo ? _memo!.trim() : 'メモがある場合はここに表示されます',
                        style: hasMemo
                            ? textTheme.bodyMedium
                            : textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.7),
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // ここから下は通常のフロー（ページ全体がスクロール対象）

            // Undo / メモ をカウントボタンの上に配置
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : onUndoTap,
                    icon: const Icon(Icons.undo),
                    label: const Text('Undo'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : onMemoTap,
                    icon: const Icon(Icons.edit_note),
                    label: const Text('メモの編集'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 大ボタン2分割
            SizedBox(
              height: 120,
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _busy ? null : onWinTap,
                      style: winButtonStyle(context),
                      child: const Text(
                        '勝 +1',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _busy ? null : onLossTap,
                      style: lossButtonStyle(context),
                      child: const Text(
                        '負 +1',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_busy)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
