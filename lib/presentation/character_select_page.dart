import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../infrastructure/db/app_database.dart';
import '../infrastructure/providers.dart';
import 'register_page.dart';

class CharacterSelectPage extends ConsumerWidget {
  final String gameId;
  const CharacterSelectPage({super.key, required this.gameId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncChars = ref.watch(fetchCharactersByGameProvider(gameId));
    return Scaffold(
      appBar: AppBar(title: Text('キャラ選択 ($gameId)')),
      body: Builder(
        builder: (scaffoldCtx) {
          return asyncChars.when(
            loading: () =>
                const Center(child: CircularProgressIndicator.adaptive()),
            error: (e, _) => Center(child: Text('読み込みエラー: $e')),
            data: (list) {
              if (list.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('キャラが未登録です'),
                      SizedBox(height: 8),
                      Text('右下の + から追加してください'),
                    ],
                  ),
                );
              }
              return ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final c = list[index];
                  final color = c.colorArgb == null
                      ? null
                      : Color(c.colorArgb!);
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color,
                      child: const Icon(Icons.person),
                    ),
                    title: Text(c.name),
                    trailing: PopupMenuButton<dynamic>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _onCharacterMenu(
                            scaffoldCtx,
                            ref,
                            _CharMenuAction.edit,
                            c,
                          );
                        } else if (value == 'delete') {
                          _onCharacterMenu(
                            scaffoldCtx,
                            ref,
                            _CharMenuAction.delete,
                            c,
                          );
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('名称変更')),
                        PopupMenuItem(value: 'delete', child: Text('削除')),
                      ],
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            RegisterPage(gameId: gameId, characterId: c.id),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: Builder(
        builder: (scaffoldCtx) => FloatingActionButton.extended(
          onPressed: () => _addCharacter(scaffoldCtx, ref),
          icon: const Icon(Icons.add),
          label: const Text('キャラ追加'),
        ),
      ),
    );
  }

  Future<void> _addCharacter(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final data = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('キャラを追加'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '表示名',
                  hintText: '例: リュウ',
                ),
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
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                Navigator.of(context).pop(name);
              },
              child: const Text('追加'),
            ),
          ],
        );
      },
    );
    if (data == null) return;
    final db = await ref.read(appDatabaseProvider.future);
    final id = _genId(prefix: 'char');
    final color = _colorFromId(id);
    await db.upsertCharacter(
      CharactersCompanion.insert(
        id: id,
        gameId: gameId,
        name: data,
        colorArgb: Value(color),
      ),
    );
    ref.invalidate(fetchCharactersByGameProvider(gameId));
  }

  String _genId({required String prefix}) {
    final ms = DateTime.now().millisecondsSinceEpoch;
    final rand = (ms ^ hashCode) & 0x7fffffff;
    final tail = rand.toRadixString(36);
    return '$prefix-$ms-$tail';
  }

  int _colorFromId(String id) {
    // 決定論的に色を生成（簡易）：idのhashからHを作り、固定S/LでHSV->ARGB
    final h = (id.hashCode & 0xFFFF) % 360;
    final color = HSVColor.fromAHSV(1.0, h.toDouble(), 0.5, 0.85).toColor();
    final a = (color.a * 255.0).round() & 0xff;
    final r = (color.r * 255.0).round() & 0xff;
    final g = (color.g * 255.0).round() & 0xff;
    final b = (color.b * 255.0).round() & 0xff;
    return (a << 24) | (r << 16) | (g << 8) | b; // ARGB int
  }

  Future<void> _onCharacterMenu(
    BuildContext context,
    WidgetRef ref,
    _CharMenuAction a,
    CharacterRow c,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final db = await ref.read(appDatabaseProvider.future);
    if (!context.mounted) return;
    switch (a) {
      case _CharMenuAction.edit:
        final controller = TextEditingController(text: c.name);
        final name = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('キャラ名を変更'),
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
        if (name != null && name != c.name) {
          await db.renameCharacter(id: c.id, name: name);
          // 先に既存の Snackbar を消してから表示
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(const SnackBar(content: Text('更新しました')));
          // 次フレームで再取得して UI 更新
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.invalidate(fetchCharactersByGameProvider(gameId));
          });
        }
        break;
      case _CharMenuAction.delete:
        final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('削除しますか？'),
            content: Text('キャラ「${c.name}」の記録も全て削除されます。'),
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
          await db.deleteCharacterAndRecords(gameId: gameId, characterId: c.id);
          // 先に既存の Snackbar を消してから表示
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(const SnackBar(content: Text('削除しました')));
          // 次フレームで再取得して UI 更新
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.invalidate(fetchCharactersByGameProvider(gameId));
          });
        }
        break;
    }
  }
}

enum _CharMenuAction { edit, delete }
