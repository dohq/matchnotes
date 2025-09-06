import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../domain/date_utils.dart';
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
  // Tap history and elapsed time ticker
  final List<_TapEvent> _history = <_TapEvent>[]; // latest first
  DateTime? _lastTapAt;
  Timer? _ticker;
  final DateTime _date = DateTime.now();
  int _wins = 0;
  int _losses = 0;
  bool _busy = false;
  final _undo = <Future<void> Function()>[]; // simple undo stack
  String? _memo;
  // メモ欄スクロール用
  final ScrollController _memoScroll = ScrollController();

  String get gameId => widget.gameId;
  String get charId => widget.characterId;
  DateTime get day {
    final cutoffMin = ref.read(cutoffMinutesProvider);
    return truncateWithCutoffMinutes(_date, cutoffMin);
  }

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
    // 前回画面の値が一瞬見えないよう、初回は明示的にクリアしてから取得
    setState(() {
      _wins = 0;
      _losses = 0;
      _memo = null;
      _undo.clear();
    });
    _refresh();
    // 10秒ごとに経過時間表示を更新
    _ticker = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      if (_lastTapAt != null) {
        setState(() {}); // re-render elapsed text
      }
    });
  }

  @override
  void didUpdateWidget(covariant RegisterPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gameId != widget.gameId ||
        oldWidget.characterId != widget.characterId) {
      // 別ゲーム/キャラに切り替わった場合は一旦値をクリアし最新を取得
      setState(() {
        _wins = 0;
        _losses = 0;
        _memo = null;
        _undo.clear();
      });
      _refresh();
    }
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
        final rawMemo = rec?.memo;
        // 空文字や空白のみは null として扱い、UI ではプレースホルダ表示
        _memo = (rawMemo == null || rawMemo.trim().isEmpty) ? null : rawMemo;
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

  void _pushHistory(_TapEvent e) {
    _lastTapAt = e.at;
    _history.insert(0, e);
    if (_history.length > 50) {
      _history.removeRange(50, _history.length);
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    // ページ離脱時は必ず wakelock を解除する
    // ignore: discarded_futures
    WakelockPlus.disable();
    _memoScroll.dispose();
    _ticker?.cancel();
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
          color: cs.surfaceContainerLow,
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
    final total = _wins + _losses;
    final wrPercent = total == 0 ? 0.0 : (_wins / total) * 100;
    final wrText = '${wrPercent.toStringAsFixed(1)}%';

    Future<void> onWinTap() async {
      if (_busy) return;
      HapticFeedback.lightImpact();
      _pushHistory(_TapEvent(kind: TapKind.win, at: DateTime.now()));
      await _incWin();
    }

    Future<void> onLossTap() async {
      if (_busy) return;
      HapticFeedback.lightImpact();
      _pushHistory(_TapEvent(kind: TapKind.loss, at: DateTime.now()));
      await _incLoss();
    }

    Future<void> onUndoTap() async {
      if (_busy) return;
      HapticFeedback.selectionClick();
      await _undoLast();
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
          .then((result) {
            // 楽観的に即時反映（null または String）
            if (mounted) {
              setState(() {
                _memo = (result is String && result.trim().isNotEmpty)
                    ? result
                    : null;
              });
            }
            // メモ変更の即時反映のためリポジトリを明示的に無効化して再取得
            ref.invalidate(dailyCharacterRecordRepositoryProvider);
            return _refresh();
          });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('登録'),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        // メモ欄スクロール時に色が変わるのを防ぐ
        notificationPredicate: (_) => false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
                      fontWeight: FontWeight.w400,
                    ) ??
                    const TextStyle(fontSize: 34, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
            ),
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
            // メモ表示エリア（可変・上限あり）。余白がある場合は上限まで広がり、長文は内部スクロール。
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) {
                  final theme = Theme.of(context);
                  final cs = theme.colorScheme;
                  final textTheme = theme.textTheme;
                  final hasMemo = (_memo != null && _memo!.trim().isNotEmpty);
                  final textStyle = hasMemo
                      ? (textTheme.bodyMedium ?? const TextStyle())
                      : (textTheme.bodyMedium ?? const TextStyle()).copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                        );
                  final screenH = MediaQuery.of(context).size.height;
                  final capH = screenH * 0.32; // 上限（画面高さの約3割）
                  // テキスト高さを計測
                  final tp = TextPainter(
                    text: TextSpan(
                      text: hasMemo ? _memo!.trim() : 'メモがある場合はここに表示されます',
                      style: textStyle,
                    ),
                    textDirection: Directionality.of(context),
                    maxLines: null,
                  )..layout(maxWidth: box.maxWidth - 24);
                  final contentH = tp.size.height + 24; // 内側 padding 分を加味
                  // 余白がある場合は余白いっぱいまで使う（未使用スペースを作らない）
                  final viewportH = box.maxHeight.isFinite
                      ? box.maxHeight
                      : capH;
                  final targetH = contentH < viewportH ? contentH : viewportH;
                  final needsScroll = contentH > viewportH;

                  final memoBox = Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: needsScroll
                        ? Scrollbar(
                            controller: _memoScroll,
                            // 常時表示はしない（スクロール中のみ表示）
                            thumbVisibility: false,
                            child: SingleChildScrollView(
                              controller: _memoScroll,
                              child: Text(
                                hasMemo ? _memo!.trim() : 'メモがある場合はここに表示されます',
                                style: textStyle,
                              ),
                            ),
                          )
                        : Text(
                            hasMemo ? _memo!.trim() : 'メモがある場合はここに表示されます',
                            style: textStyle,
                          ),
                  );

                  // Expanded領域の先頭に上詰めで配置し、ボタンは常に下端に維持
                  return Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: double.infinity,
                      height: targetH.toDouble(),
                      child: memoBox,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

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

            const SizedBox(height: 8),
            // Bottom small history line
            _TapHistoryBar(history: _history, lastTapAt: _lastTapAt),
          ],
        ),
      ),
    );
  }
}

enum TapKind { win, loss }

class _TapEvent {
  final TapKind kind;
  final DateTime at;
  _TapEvent({required this.kind, required this.at});
}

class _TapHistoryBar extends StatelessWidget {
  final List<_TapEvent> history;
  final DateTime? lastTapAt;
  const _TapHistoryBar({required this.history, required this.lastTapAt});

  String _elapsedText() {
    if (lastTapAt == null) return '未登録';
    final diff = DateTime.now().difference(lastTapAt!);
    final s = diff.inSeconds;
    if (s < 60) return '$s秒前';
    final m = diff.inMinutes;
    if (m < 60) return '$m分前';
    final h = diff.inHours;
    return '$h時間前';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final cs = theme.colorScheme;
    // 右が最新になるように並べる（最新を右端に）
    final recent = history.take(10).toList().reversed.toList();
    final icons = <Widget>[
      for (final e in recent)
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Icon(
            Icons.circle,
            size: 10,
            color: e.kind == TapKind.win
                ? cs.primaryContainer
                : cs.errorContainer,
          ),
        ),
    ];
    return DefaultTextStyle(
      style: (textTheme.bodySmall ?? const TextStyle()).copyWith(
        color: cs.onSurfaceVariant,
      ),
      child: Row(
        children: [
          // 履歴（左に古い、右に新しい）
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: icons,
            ),
          ),
          // 右端に経過時間
          Text('最後に登録してから: ${_elapsedText()}'),
        ],
      ),
    );
  }
}
