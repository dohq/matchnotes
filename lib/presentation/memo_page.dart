import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../domain/entities.dart' as domain;
import '../infrastructure/providers.dart';

class MemoPage extends ConsumerStatefulWidget {
  final String gameId;
  final String characterId;
  final DateTime date;
  const MemoPage({
    super.key,
    required this.gameId,
    required this.characterId,
    required this.date,
  });

  @override
  ConsumerState<MemoPage> createState() => _MemoPageState();
}

class _MemoPageState extends ConsumerState<MemoPage> {
  final _ctl = TextEditingController();
  bool _busy = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _busy = true);
    try {
      final repo = await ref.read(
        dailyCharacterRecordRepositoryProvider.future,
      );
      final rec = await repo.findById(
        domain.DailyCharacterRecordId(
          gameId: widget.gameId,
          characterId: widget.characterId,
          date: widget.date,
        ),
      );
      _ctl.text = rec?.memo ?? '';
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _initialized = true;
        });
      }
    }
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final repo = await ref.read(
        dailyCharacterRecordRepositoryProvider.future,
      );
      final id = domain.DailyCharacterRecordId(
        gameId: widget.gameId,
        characterId: widget.characterId,
        date: widget.date,
      );
      final current =
          await repo.findById(id) ??
          domain.DailyCharacterRecord(id: id, wins: 0, losses: 0, memo: null);
      final normalized = _ctl.text.trim();
      final next = domain.DailyCharacterRecord(
        id: current.id,
        wins: current.wins,
        losses: current.losses,
        memo: normalized.isEmpty ? null : normalized,
      );
      await repo.upsert(next);
      // 明示的にリポジトリを無効化して呼び出し元の再取得を促す
      ref.invalidate(dailyCharacterRecordRepositoryProvider);
      if (mounted) {
        // 呼び出し元へ更新後の memo を返す（null または文字列）
        Navigator.of(context).pop(normalized.isEmpty ? null : normalized);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copyPrev() async {
    setState(() => _busy = true);
    try {
      final usecase = await ref.read(
        copyMemoFromPreviousDayUsecaseProvider.future,
      );
      await usecase.execute(
        gameId: widget.gameId,
        characterId: widget.characterId,
        date: widget.date,
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Copied from previous day.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
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
      appBar: AppBar(title: Text('メモ (${df.format(widget.date)})')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _ctl,
              minLines: 4,
              maxLines: 10,
              decoration: const InputDecoration(labelText: 'Memo'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton(
                  onPressed: _busy ? null : _save,
                  child: const Text('保存'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _busy ? null : _copyPrev,
                  child: const Text('前日のメモをコピー'),
                ),
              ],
            ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
