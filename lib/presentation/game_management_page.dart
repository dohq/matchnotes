import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matchnotes/infrastructure/providers.dart';
import 'package:matchnotes/infrastructure/db/app_database.dart';

class GameManagementPage extends ConsumerWidget {
  const GameManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamesAsync = ref.watch(watchAllGamesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('ゲーム管理')),
      body: gamesAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (e, st) => Center(child: Text('読み込みエラー: $e')),
        data: (games) {
          if (games.isEmpty) {
            return const Center(child: Text('ゲームがありません。右下の + から追加'));
          }
          return ListView.builder(
            itemCount: games.length,
            itemBuilder: (context, index) {
              final g = games[index];
              return ListTile(
                leading: const Icon(Icons.sports_esports),
                title: Text(g.name),
                subtitle: Text(g.id),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: '名称変更',
                      icon: const Icon(Icons.edit),
                      onPressed: () => _rename(context, ref, g),
                    ),
                    IconButton(
                      tooltip: '削除',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _delete(context, ref, g),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _add(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final controllerId = TextEditingController();
    final controllerName = TextEditingController();
    final result = await showDialog<({String id, String name})>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ゲームを追加'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controllerId,
                decoration: const InputDecoration(labelText: 'ゲームID (英数字推奨)'),
              ),
              TextField(
                controller: controllerName,
                decoration: const InputDecoration(labelText: '表示名'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () {
                final id = controllerId.text.trim();
                final name = controllerName.text.trim();
                if (id.isEmpty || name.isEmpty) return;
                Navigator.of(context).pop((id: id, name: name));
              },
              child: const Text('追加'),
            ),
          ],
        );
      },
    );
    if (result == null) return;
    final db = await ref.read(appDatabaseProvider.future);
    await db.upsertGame(
      GamesCompanion.insert(id: result.id, name: result.name),
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref, GameRow g) async {
    final controller = TextEditingController(text: g.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('名称変更'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: '新しい名前'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('更新'),
            ),
          ],
        );
      },
    );
    if (newName == null || newName.isEmpty) return;
    final db = await ref.read(appDatabaseProvider.future);
    await db.renameGame(id: g.id, name: newName);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, GameRow g) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除確認'),
        content: Text('ゲーム「${g.name}」と関連する全ての記録を削除します。よろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final db = await ref.read(appDatabaseProvider.future);
    await db.deleteGameAndRecords(g.id);
  }
}
