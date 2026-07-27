/// Web platform database connection using Drift's WebDatabase.
library;
import 'package:drift/drift.dart';
import 'package:drift/web.dart';

import '../utils/logger.dart';

QueryExecutor getQueryExecutor() {
  AppLogger.info('AppDatabase: using WebDatabase (IndexedDB)');
  return WebDatabase('examforge_ai');
}
