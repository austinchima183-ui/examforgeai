/// IO (native) platform database connection using SQLite via dart:ffi.
library;
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../utils/logger.dart';

QueryExecutor getQueryExecutor() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'examforge_ai.db'));
    AppLogger.info('AppDatabase: file at ${file.path}');
    return NativeDatabase.createInBackground(file);
  });
}
