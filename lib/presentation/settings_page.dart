import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matchnotes/infrastructure/providers.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:path_provider/path_provider.dart';

const keepScreenOnSwitchKey = ValueKey('settings.keepScreenOnSwitch');
const hapticsSwitchKey = ValueKey('settings.hapticsSwitch');

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
            key: keepScreenOnSwitchKey,
            title: const Text('勝敗登録ページで画面ロック防止'),
            value: keepOn,
            onChanged: (v) => keepCtl.setKeepOn(v),
          ),
          // Haptics toggle
          Builder(
            builder: (context) {
              final haptics = ref.watch(hapticsOnTapProvider);
              final hCtl = ref.read(hapticsOnTapProvider.notifier);
              return SwitchListTile(
                key: hapticsSwitchKey,
                title: const Text('勝敗ボタンのタップ時にバイブレーション'),
                value: haptics,
                onChanged: (v) => hCtl.setEnabled(v),
              );
            },
          ),
          const Divider(height: 0),
          // 日付切替時刻（カットオフ）
          Builder(
            builder: (context) {
              final cutoffMin = ref.watch(cutoffMinutesProvider);
              final cutoffCtl = ref.read(cutoffMinutesProvider.notifier);
              final hh = (cutoffMin ~/ 60).toString().padLeft(2, '0');
              final mm = (cutoffMin % 60).toString().padLeft(2, '0');
              final label = '$hh:$mm';
              return ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('日付の切り替わり時刻'),
                subtitle: Text('現在: $label  / 指定時刻までは前日扱い'),
                onTap: () async {
                  if (!context.mounted) return;
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                      hour: cutoffMin ~/ 60,
                      minute: cutoffMin % 60,
                    ),
                    helpText: '日付の切り替え時刻',
                    builder: (ctx, child) {
                      final mq = MediaQuery.of(ctx);
                      return MediaQuery(
                        data: mq.copyWith(alwaysUse24HourFormat: true),
                        child: child ?? const SizedBox.shrink(),
                      );
                    },
                  );
                  if (picked == null) return;
                  await cutoffCtl.setHourMinute(
                    hour: picked.hour,
                    minute: picked.minute,
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '切り替え時刻を ${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')} に設定しました',
                      ),
                    ),
                  );
                },
                trailing: const Icon(Icons.chevron_right),
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
                // 上書き確認ダイアログ
                if (!context.mounted) return;
                final proceed =
                    await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('インポートの確認'),
                        content: const Text(
                          'CSV に含まれる日付・ゲーム・キャラクターの組み合わせは、\n'
                          '既存データがある場合に勝敗数で上書きされます。\n\n'
                          'インポートを実行しますか？',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('キャンセル'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('インポートする'),
                          ),
                        ],
                      ),
                    ) ??
                    false;
                if (!proceed) return;

                try {
                  // 初回でも確実に usecase を取得
                  final usecase = await ref.read(
                    importDailyRecordsCsvUsecaseProvider.future,
                  );

                  // 進行ダイアログ
                  if (!context.mounted) return;
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const AlertDialog(
                      content: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('インポート中…'),
                        ],
                      ),
                    ),
                  );

                  final file = File(path);
                  final report = await usecase.executeWithReport(file: file);

                  if (!context.mounted) return;
                  Navigator.of(context).pop(); // 進行ダイアログを閉じる

                  // キャッシュ無効化（画面が依存する可能性のあるプロバイダ）
                  ref.invalidate(dailyCharacterRecordRepositoryProvider);
                  ref.invalidate(getMonthlyWinRatesPerGameUsecaseProvider);

                  // 結果ダイアログ
                  final maxShow = 5;
                  final shownErrors = report.errors.take(maxShow).toList();
                  final remaining = report.errors.length - shownErrors.length;
                  final sb = StringBuffer()
                    ..writeln('インポート: ${report.imported} 件')
                    ..writeln('スキップ: ${report.skipped} 件');
                  if (report.errors.isNotEmpty) {
                    sb.writeln('\nエラー詳細（一部）:');
                    for (final e in shownErrors) {
                      sb.writeln('- $e');
                    }
                    if (remaining > 0) sb.writeln('… ほか $remaining 件');
                  }
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
                  // 進行ダイアログが出ていれば閉じる
                  if (context.mounted && Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                  messenger.showSnackBar(
                    SnackBar(content: Text('インポート失敗: $e')),
                  );
                }
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
              try {
                // Usecase を Future 経由で取得（初回でも確実に実行）
                final usecase = await ref.read(
                  exportDailyRecordsCsvUsecaseProvider.future,
                );

                // 一旦一時ディレクトリへ出力してから保存先へ移す
                final tempDir = await getTemporaryDirectory();
                final tmpFile = await usecase.execute(targetDir: tempDir);
                final bytes = await tmpFile.readAsBytes();
                // 期待ファイル名（固定）
                const desiredFileName = 'matchnotes_backup.csv';
                // MediaStore.saveFile は tempFile のファイル名を元に保存されるため、
                // 一時ファイルを目的の名前にリネームしてから渡す。
                final renamedTmp = File('${tempDir.path}/$desiredFileName');
                if (renamedTmp.path != tmpFile.path) {
                  await tmpFile.rename(renamedTmp.path);
                }

                String outLabel; // Snackbar 表示用
                if (Platform.isAndroid) {
                  final msp = MediaStore();
                  // MediaStore 経由で Downloads コレクションに保存（Android10+対応）
                  final info = await msp.saveFile(
                    tempFilePath: renamedTmp.path,
                    dirType: DirType.download,
                    dirName: DirName.download,
                    // Downloads/MatchNotes/ 配下に保存
                    relativePath: 'MatchNotes',
                  );
                  if (info == null || !info.isSuccessful) {
                    throw 'MediaStore への保存に失敗しました';
                  }
                  // 実際に保存されたファイル名を表示（重複時の自動リネームも反映）
                  outLabel = 'Downloads/${info.name}';
                } else if (Platform.isIOS) {
                  // iOS: アプリ専用 Documents/MatchNotes に保存
                  final docsDir = await getApplicationDocumentsDirectory();
                  final outDir = Directory('${docsDir.path}/MatchNotes');
                  if (!await outDir.exists()) {
                    await outDir.create(recursive: true);
                  }
                  final outPath = '${outDir.path}/$desiredFileName';
                  final outFile = File(outPath);
                  await outFile.writeAsBytes(bytes, flush: true);
                  outLabel = outPath;
                } else {
                  // Desktop: Downloads/MatchNotes に保存
                  final downloadsDir = await getDownloadsDirectory();
                  if (downloadsDir == null) {
                    throw 'Downloads ディレクトリが取得できませんでした';
                  }
                  final outDir = Directory('${downloadsDir.path}/MatchNotes');
                  if (!await outDir.exists()) {
                    await outDir.create(recursive: true);
                  }
                  final outPath = '${outDir.path}/$desiredFileName';
                  final outFile = File(outPath);
                  await outFile.writeAsBytes(bytes, flush: true);
                  outLabel = outPath;
                }

                // 一時ファイルは削除（失敗は無視）
                try {
                  await renamedTmp.delete();
                } catch (_) {}

                messenger.showSnackBar(
                  SnackBar(content: Text('エクスポート完了: $outLabel')),
                );
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text('エクスポート失敗: $e')));
              }
            },
          ),
        ],
      ),
    );
  }
}
