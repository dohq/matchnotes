import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'game_select_page.dart';
import 'settings_page.dart';

class TopPage extends StatefulWidget {
  const TopPage({super.key});

  @override
  State<TopPage> createState() => _TopPageState();
}

class _TopPageState extends State<TopPage> {
  final DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matchnotes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsPage())),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // Calendar placeholder
            Text(
              'Calendar (focused: ${df.format(_focusedDay)})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Text('Calendar widget placeholder'),
            ),
            const SizedBox(height: 16),
            // Daily rates list placeholder
            Text(
              'Daily win rates',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...List.generate(
              5,
              (i) => ListTile(
                leading: const Icon(Icons.sports_esports),
                title: Text('2025-09-${(i + 1).toString().padLeft(2, '0')}'),
                subtitle: const Text('winRate: --'),
              ),
            ),
            const SizedBox(height: 16),
            // Graph placeholder
            Text(
              'Win rate graph',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Text('Graph placeholder'),
            ),
            const SizedBox(height: 16),
            // Navigation to Game Select
            FilledButton.icon(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const GameSelectPage())),
              icon: const Icon(Icons.list),
              label: const Text('ゲーム選択へ'),
            ),
          ],
        ),
      ),
    );
  }
}
