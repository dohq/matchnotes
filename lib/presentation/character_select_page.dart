import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      body: asyncChars.when(
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (e, _) => Center(child: Text('読み込みエラー: $e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('キャラが未登録です'),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('キャラ追加は未実装です')),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('キャラ追加'),
                  ),
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
        onPressed: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('キャラ追加は未実装です')));
        },
        icon: const Icon(Icons.add),
        label: const Text('キャラ追加'),
      ),
    );
  }
}
