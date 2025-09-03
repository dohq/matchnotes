import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:matchnotes/infrastructure/providers.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:matchnotes/presentation/game_management_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
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
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('ゲーム管理'),
            subtitle: const Text('一覧 / 追加 / 名称変更 / 削除'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const GameManagementPage()),
              );
            },
          ),
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.file_upload),
            title: const Text('データのインポート'),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['csv'],
                  dialogTitle: 'CSVファイルを選択',
                );
                if (result == null || result.files.single.path == null) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('キャンセルされました')),
                  );
                  return;
                }
                final path = result.files.single.path!;
                final usecaseAsync = ref.read(
                  importDailyRecordsCsvUsecaseProvider,
                );
                await usecaseAsync.when(
                  data: (usecase) async {
                    try {
                      final file = File(path);
                      final report = await usecase.executeWithReport(
                        file: file,
                      );
                      // 上位5件のみ表示、残りは件数で示す
                      final maxShow = 5;
                      final shownErrors = report.errors.take(maxShow).toList();
                      final remaining =
                          report.errors.length - shownErrors.length;
                      // 表示用本文
                      final sb = StringBuffer()
                        ..writeln('インポート: ${report.imported} 件')
                        ..writeln('スキップ: ${report.skipped} 件');
                      if (report.errors.isNotEmpty) {
                        sb.writeln('\nエラー詳細（一部）:');
                        for (final e in shownErrors) {
                          sb.writeln('- $e');
                        }
                        if (remaining > 0) {
                          sb.writeln('… ほか $remaining 件');
                        }
                      }
                      if (!context.mounted) return;
                      await showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('インポート結果'),
                          content: SingleChildScrollView(
                            child: Text(sb.toString()),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('閉じる'),
                            ),
                          ],
                        ),
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('インポート失敗: $e')),
                      );
                    }
                  },
                  loading: () {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('準備中です…')),
                    );
                  },
                  error: (e, st) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('インポート不可: $e')),
                    );
                  },
                );
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text('インポート失敗: $e')));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('データのエクスポート'),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final usecaseAsync = ref.read(
                exportDailyRecordsCsvUsecaseProvider,
              );
              await usecaseAsync.when(
                data: (usecase) async {
                  try {
                    final dir = await getApplicationDocumentsDirectory();
                    final file = await usecase.execute(targetDir: dir);
                    messenger.showSnackBar(
                      SnackBar(content: Text('エクスポート完了: ${file.path}')),
                    );
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('エクスポート失敗: $e')),
                    );
                  }
                },
                loading: () {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('準備中です…')),
                  );
                },
                error: (e, st) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('エクスポート不可: $e')),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
