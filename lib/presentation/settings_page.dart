import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _darkMode = false; // TODO: wire to Theme/Provider
  bool _keepScreenOn = false; // TODO: implement wakelock

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('ダークモード'),
            value: _darkMode,
            onChanged: (v) => setState(() => _darkMode = v),
          ),
          SwitchListTile(
            title: const Text('勝敗登録ページで画面ロック防止'),
            value: _keepScreenOn,
            onChanged: (v) => setState(() => _keepScreenOn = v),
          ),
          ListTile(
            leading: const Icon(Icons.file_upload),
            title: const Text('データのインポート'),
            onTap: () {
              // TODO: implement import
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Import (TODO)')));
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('データのエクスポート'),
            onTap: () {
              // TODO: implement export
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Export (TODO)')));
            },
          ),
        ],
      ),
    );
  }
}
