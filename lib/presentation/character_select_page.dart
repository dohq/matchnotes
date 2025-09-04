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
    final idController = TextEditingController();
    final nameController = TextEditingController();
    final colorController = TextEditingController();
    final data = await showDialog<({String id, String name, int? color})>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('キャラを追加'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idController,
                decoration: const InputDecoration(
                  labelText: 'キャラID (全体で一意に)',
                  hintText: '例: sf6-ryu',
                ),
              ),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '表示名',
                  hintText: '例: リュウ',
                ),
              ),
              TextField(
                controller: colorController,
                decoration: const InputDecoration(
                  labelText: '色 (ARGB 8桁の16進, 任意)',
                  hintText: '例: FF2196F3',
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
                final id = idController.text.trim();
                final name = nameController.text.trim();
                if (id.isEmpty || name.isEmpty) return;
                int? color;
                final txt = colorController.text.trim();
                if (txt.isNotEmpty) {
                  final normalized = txt.replaceAll('#', '');
                  if (RegExp(r'^[0-9a-fA-F]{8}$').hasMatch(normalized)) {
                    color = int.parse(normalized, radix: 16);
                  }
                }
                Navigator.of(context).pop((id: id, name: name, color: color));
              },
              child: const Text('追加'),
            ),
          ],
        );
      },
    );
    if (data == null) return;
    final db = await ref.read(appDatabaseProvider.future);
    await db.upsertCharacter(
      CharactersCompanion.insert(
        id: data.id,
        gameId: gameId,
        name: data.name,
        colorArgb: Value(data.color),
      ),
    );
    ref.invalidate(fetchCharactersByGameProvider(gameId));
  }
}
