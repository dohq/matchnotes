import 'package:flutter/material.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matchnotes/infrastructure/providers.dart';
import 'package:matchnotes/presentation/top_page.dart';
import 'package:matchnotes/infrastructure/crash/crashlytics.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Android の MediaStore を利用するための初期化（1回のみ）
  await MediaStore.ensureInitialized();
  // MediaStore 側でアプリ既定のフォルダ名を設定（Downloads 直下でも要求される場合がある）
  MediaStore.appFolder = 'MatchNotes';

  // Crashlytics 有効化フラグ（Release 以外は既定で無効）
  const allowCrash = bool.fromEnvironment('ENABLE_CRASH', defaultValue: true);
  final enableCrashlytics = kReleaseMode && allowCrash;

  await runWithCrashReporting(
    app: const ProviderScope(child: MyApp()),
    enableCrashlytics: enableCrashlytics,
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'MatchNotes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: mode,
      home: const TopPage(),
    );
  }
}

// Demo用の旧UIは削除しました。
