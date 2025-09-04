import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../infrastructure/providers.dart';
import '../infrastructure/db/app_database.dart';
import 'register_page.dart';

class CharacterSelectPage extends ConsumerWidget {
  final String gameId;
  const CharacterSelectPage({super.key, required this.gameId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncChars = ref.watch(fetchCharactersByGameProvider(gameId));
    return Scaffold(
      appBar: AppBar(title: Text('キャラ選択 ($gameId)')),
      body: asyncChars.when(
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
              final color = c.colorArgb == null ? null : Color(c.colorArgb!);
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: color,
                  child: const Icon(Icons.person),
                ),
                title: Text(c.name),
                subtitle: Text(c.id),
                trailing: const Icon(Icons.chevron_right),
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addCharacter(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('キャラ追加'),
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
}
