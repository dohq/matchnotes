import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../infrastructure/providers.dart';
import 'character_select_page.dart';
import 'game_management_page.dart';

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
                leading: const Icon(Icons.sports_esports),
                title: Text(g.name),
                subtitle: Text(g.id),
                trailing: const Icon(Icons.chevron_right),
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
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const GameManagementPage()));
        },
        icon: const Icon(Icons.add),
        label: const Text('ゲーム追加'),
      ),
    );
  }
}
