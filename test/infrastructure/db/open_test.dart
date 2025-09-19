import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:matchnotes/infrastructure/db/open.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.appSupportPath);

  final String appSupportPath;

  @override
  Future<String?> getApplicationSupportPath() async => appSupportPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PathProviderPlatform original;

  setUp(() {
    original = PathProviderPlatform.instance;
  });

  tearDown(() {
    PathProviderPlatform.instance = original;
  });

  test(
    'openAppDatabase creates database file under application support dir',
    () async {
      final temp = await Directory.systemTemp.createTemp('open_app_database');
      addTearDown(() async => temp.delete(recursive: true));

      PathProviderPlatform.instance = _FakePathProvider(temp.path);

      final db = await openAppDatabase();
      addTearDown(() async => db.close());

      await db.customSelect('SELECT 1').getSingle();

      final expectedPath = p.join(temp.path, 'matchnotes.db');
      expect(File(expectedPath).existsSync(), isTrue);
    },
  );
}
