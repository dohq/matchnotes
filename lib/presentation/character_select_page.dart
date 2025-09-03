import 'package:flutter/material.dart';
import 'register_page.dart';

class CharacterSelectPage extends StatelessWidget {
  final String gameId;
  const CharacterSelectPage({super.key, required this.gameId});

  @override
  Widget build(BuildContext context) {
    final characters = const ['char-1', 'char-2', 'char-3'];
    return Scaffold(
      appBar: AppBar(title: Text('キャラ選択 ($gameId)')),
      body: ListView.separated(
        itemCount: characters.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final c = characters[index];
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(c),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RegisterPage(gameId: gameId, characterId: c),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('未実装です')));
        },
        icon: const Icon(Icons.add),
        label: const Text('キャラ追加'),
      ),
    );
  }
}
