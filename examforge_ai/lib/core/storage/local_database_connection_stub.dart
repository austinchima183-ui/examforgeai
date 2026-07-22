/// Stub connection file for platforms that don't match any conditional import.
/// This should never be used in practice since all platforms either support
/// dart:io or dart:html.
import 'package:drift/drift.dart';

QueryExecutor getQueryExecutor() {
  throw UnsupportedError('No database executor available for this platform.');
}
