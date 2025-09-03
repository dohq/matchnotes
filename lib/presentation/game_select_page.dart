import 'package:flutter/material.dart';
import 'character_select_page.dart';

class GameSelectPage extends StatelessWidget {
  const GameSelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with real games from repository
    final games = const ['demo-game', 'game-2'];
    return Scaffold(
      appBar: AppBar(title: const Text('ゲーム選択')),
      body: ListView.separated(
        itemCount: games.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final g = games[index];
          return ListTile(
            leading: const Icon(Icons.sports_esports),
            title: Text(g),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CharacterSelectPage(gameId: g)),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: implement add game dialog
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Add game (TODO)')));
        },
        icon: const Icon(Icons.add),
        label: const Text('ゲーム追加'),
      ),
    );
  }
}
