import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:matchnotes/infrastructure/providers.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(themeModeProvider);
    final themeCtl = ref.read(themeModeProvider.notifier);
    void setMode(ThemeMode m) => themeCtl.setMode(m);
    final keepOn = ref.watch(keepScreenOnProvider);
    final keepCtl = ref.read(keepScreenOnProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          const ListTile(title: Text('テーマモード')),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('システムに合わせる'),
                  icon: Icon(Icons.settings_suggest_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('ライト（OFF）'),
                  icon: Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('ダーク（ON）'),
                  icon: Icon(Icons.dark_mode_outlined),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (set) {
                if (set.isNotEmpty) setMode(set.first);
              },
            ),
          ),
          SwitchListTile(
            title: const Text('勝敗登録ページで画面ロック防止'),
            value: keepOn,
            onChanged: (v) => keepCtl.setKeepOn(v),
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
                    // 一旦一時ディレクトリへ出力してから保存先へ移す
                    final tempDir = await getTemporaryDirectory();
                    final tmpFile = await usecase.execute(targetDir: tempDir);
                    final bytes = await tmpFile.readAsBytes();
                    final fileName = tmpFile.uri.pathSegments.last;

                    String outPath;
                    if (Platform.isAndroid) {
                      final msp = MediaStore();
                      // MediaStore 経由で Downloads コレクションに保存（Android10+対応）
                      final info = await msp.saveFile(
                        tempFilePath: tmpFile.path,
                        dirType: DirType.download,
                        dirName: DirName.download,
                        relativePath: FilePath.root,
                      );
                      if (info == null || !info.isSuccessful) {
                        throw 'MediaStore への保存に失敗しました';
                      }
                      outPath = info.uri.toString();
                    } else {
                      final downloadsDir = await getDownloadsDirectory();
                      if (downloadsDir == null) {
                        throw 'Downloads ディレクトリが取得できませんでした';
                      }
                      outPath = '${downloadsDir.path}/$fileName';
                    }

                    if (!Platform.isAndroid) {
                      final outFile = File(outPath);
                      await outFile.writeAsBytes(bytes, flush: true);
                    }

                    // 一時ファイルは削除（失敗は無視）
                    try {
                      await tmpFile.delete();
                    } catch (_) {}

                    messenger.showSnackBar(
                      SnackBar(content: Text('エクスポート完了: $outPath')),
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
