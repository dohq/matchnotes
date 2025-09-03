import 'package:drift_sqflite/drift_sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'app_database.dart';

Future<AppDatabase> openAppDatabase({bool logStatements = false}) async {
  final dir = await getApplicationDocumentsDirectory();
  final dbFolder = Directory(dir.path);
  if (!await dbFolder.exists()) {
    await dbFolder.create(recursive: true);
  }
  final executor = SqfliteQueryExecutor(
    path: '${dbFolder.path}/matchnotes.db',
    logStatements: logStatements,
  );
  return AppDatabase(executor);
}
