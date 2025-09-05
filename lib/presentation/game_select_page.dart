import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../infrastructure/db/app_database.dart';
import '../infrastructure/providers.dart';
import 'character_select_page.dart';

class GameSelectPage extends ConsumerWidget {
  const GameSelectPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamesAsync = ref.watch(watchAllGamesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('ゲーム選択')),
      body: gamesAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (e, _) => Center(child: Text('読み込みエラー: $e')),
        data: (games) {
          if (games.isEmpty) {
            return const Center(child: Text('ゲームがありません。右下の + から追加'));
          }
          return ListView.separated(
            itemCount: games.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final g = games[index];
              return ListTile(
                minVerticalPadding: 14,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                title: Text(
                  g.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontSize: 18),
                ),
                trailing: PopupMenuButton<_GameMenuAction>(
                  onSelected: (a) => _onGameMenu(context, ref, a, g),
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _GameMenuAction.edit,
                      child: Text('名称変更'),
                    ),
                    PopupMenuItem(
                      value: _GameMenuAction.delete,
                      child: Text('削除'),
                    ),
                  ],
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CharacterSelectPage(gameId: g.id),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addGame(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('ゲーム追加'),
      ),
    );
  }

  Future<void> _onGameMenu(
    BuildContext context,
    WidgetRef ref,
    _GameMenuAction a,
    GameRow g,
  ) async {
    final db = await ref.read(appDatabaseProvider.future);
    if (!context.mounted) return;
    switch (a) {
      case _GameMenuAction.edit:
        final controller = TextEditingController(text: g.name);
        final name = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('ゲーム名を変更'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: '表示名'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
              FilledButton(
                onPressed: () {
                  final v = controller.text.trim();
                  if (v.isEmpty) return;
                  Navigator.pop(context, v);
                },
                child: const Text('保存'),
              ),
            ],
          ),
        );
        if (name != null && name != g.name) {
          await db.renameGame(id: g.id, name: name);
          if (!context.mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('更新しました')));
          // invalidate monthly charts
          ref.invalidate(getMonthlyWinRatesPerGameUsecaseProvider);
        }
        break;
      case _GameMenuAction.delete:
        final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('削除しますか？'),
            content: Text('ゲーム「${g.name}」と関連する記録が全て削除されます。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('キャンセル'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('削除'),
              ),
            ],
          ),
        );
        if (ok == true) {
          await db.deleteGameAndRecords(g.id);
          if (!context.mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('削除しました')));
          // invalidate monthly charts
          ref.invalidate(getMonthlyWinRatesPerGameUsecaseProvider);
        }
        break;
    }
  }

  Future<void> _addGame(BuildContext context, WidgetRef ref) async {
    final controllerName = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ゲームを追加'),
        content: TextField(
          controller: controllerName,
          decoration: const InputDecoration(labelText: '表示名'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () {
              final v = controllerName.text.trim();
              if (v.isEmpty) return;
              Navigator.pop(context, v);
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
    if (name == null) return;
    final db = await ref.read(appDatabaseProvider.future);
    final id = _genId(prefix: 'game');
    await db.upsertGame(GamesCompanion.insert(id: id, name: name));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('追加しました')));
  }

  String _genId({required String prefix}) {
    final ms = DateTime.now().millisecondsSinceEpoch;
    final rand = (ms ^ hashCode) & 0x7fffffff;
    final tail = rand.toRadixString(36);
    return '$prefix-$ms-$tail';
  }
}

enum _GameMenuAction { edit, delete }
