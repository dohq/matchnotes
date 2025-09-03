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
      if (mounted) setState(() => _busy = false);
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
      await repo.upsert(
        current.copyWith(memo: _ctl.text.isEmpty ? null : _ctl.text),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Memo saved.')));
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
