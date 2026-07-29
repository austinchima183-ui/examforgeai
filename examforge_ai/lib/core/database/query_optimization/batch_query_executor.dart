import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../utils/logger.dart';

// ═══════════════════════════════════════════════════════════════════════
// BATCH QUERY EXECUTOR
// ═══════════════════════════════════════════════════════════════════════
// Purpose: Replace N+1 loop patterns with efficient batch operations
// Root cause: Datasource audit found sequential inserts/updates in loops
//   - cloneExam() inserts sections/questions one-at-a-time
//   - reorderQuestions() updates sort_order per question individually
//   - moveQuestions() updates one-at-a-time in a loop
//   - toggleFavorite() makes 2 sequential queries
// Solution: Batch all inserts/updates into single Supabase calls
// ═══════════════════════════════════════════════════════════════════════

/// Utility class for executing batch database operations efficiently.
///
/// Replaces N+1 patterns (sequential loop inserts/updates) with
/// single batch calls, reducing network round-trips from N to 1.
///
/// Example (before — N+1):
///   for (final item in items) {
///     await supabase.from('table').insert(item); // N network calls
///   }
///
/// Example (after — batch):
///   await BatchQueryExecutor.batchInsert(supabase, 'table', items); // 1 call
class BatchQueryExecutor {
  BatchQueryExecutor._();

  /// Maximum number of rows Supabase can handle in a single insert.
  /// Supabase/PostgREST has a practical limit; we chunk at 500 to
  /// stay safe and avoid payload size limits.
  static const int _maxBatchSize = 500;

  // ═══════════════════════════════════════════════════════════════════
  // Batch Insert
  // ═══════════════════════════════════════════════════════════════════

  /// Insert multiple rows in a single (or chunked) Supabase call.
  ///
  /// For lists exceeding [_maxBatchSize], automatically chunks the
  /// insert into multiple calls to avoid payload size limits.
  ///
  /// Returns the combined list of inserted rows.
  static Future<List<Map<String, dynamic>>> batchInsert(
    sb.SupabaseClient supabase,
    String table,
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) return [];

    if (rows.length <= _maxBatchSize) {
      // Single batch — efficient
      final response = await supabase.from(table).insert(rows).select();
      AppLogger.info(
        'Batch insert: ${rows.length} rows into $table (1 call)',
      );
      return List<Map<String, dynamic>>.from(response);
    }

    // Chunked batch for large lists
    final allResults = <Map<String, dynamic>>[];
    final chunks = _chunk(rows, _maxBatchSize);

    for (int i = 0; i < chunks.length; i++) {
      final chunk = chunks[i];
      final response = await supabase.from(table).insert(chunk).select();
      allResults.addAll(List<Map<String, dynamic>>.from(response));
      AppLogger.debug(
        'Batch insert chunk ${i + 1}/${chunks.length}: '
        '${chunk.length} rows into $table',
      );
    }

    AppLogger.info(
      'Batch insert: ${rows.length} rows into $table '
      '(${chunks.length} chunked calls)',
    );
    return allResults;
  }

  /// Insert without returning data (fire-and-forget, faster).
  ///
  /// Use when you don't need the inserted rows back.
  static Future<void> batchInsertSilent(
    sb.SupabaseClient supabase,
    String table,
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) return;

    if (rows.length <= _maxBatchSize) {
      await supabase.from(table).insert(rows);
      AppLogger.info(
        'Batch insert silent: ${rows.length} rows into $table (1 call)',
      );
      return;
    }

    final chunks = _chunk(rows, _maxBatchSize);
    for (int i = 0; i < chunks.length; i++) {
      await supabase.from(table).insert(chunks[i]);
      AppLogger.debug(
        'Batch insert silent chunk ${i + 1}/${chunks.length}: '
        '${chunks[i].length} rows into $table',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Batch Update (Sort Order Reorder)
  // ═══════════════════════════════════════════════════════════════════

  /// Update sort_order for multiple items efficiently.
  ///
  /// Replaces the N+1 pattern of updating one item at a time:
  ///   for (var i = 0; i < ids.length; i++) {
  ///     await supabase.from('table')
  ///       .update({'sort_order': i})
  ///       .eq('exam_id', examId)
  ///       .eq('question_id', ids[i]);
  ///   }
  ///
  /// With a single RPC call (requires `batch_update_sort_order` SQL function)
  /// or a batched approach using parallel Future.wait.
  ///
  /// Strategy: If an RPC function exists, use it (1 network call).
  /// Otherwise, use Future.wait for parallel execution (N concurrent calls
  /// instead of N sequential — still reduces latency significantly).
  static Future<void> batchReorder(
    sb.SupabaseClient supabase,
    String table,
    String parentIdColumn,
    String parentIdValue,
    String idColumn,
    List<String> ids,
  ) async {
    if (ids.isEmpty) return;

    // Strategy 1: Try RPC first (single network call)
    try {
      await supabase.rpc(
        'batch_update_sort_order',
        params: {
          'table_name': table,
          'parent_column': parentIdColumn,
          'parent_value': parentIdValue,
          'id_column': idColumn,
          'ordered_ids': ids,
        },
      );
      AppLogger.info(
        'Batch reorder via RPC: ${ids.length} items in $table (1 call)',
      );
      return;
    } catch (e) {
      // RPC not available — fall through to parallel strategy
      AppLogger.debug(
        'batch_update_sort_order RPC not available, '
        'using parallel updates',
      );
    }

    // Strategy 2: Parallel updates (N concurrent, not sequential)
    final futures = <Future<void>>[];
    for (var i = 0; i < ids.length; i++) {
      futures.add(
        supabase
            .from(table)
            .update({'sort_order': i})
            .eq(parentIdColumn, parentIdValue)
            .eq(idColumn, ids[i]),
      );
    }
    await Future.wait(futures);
    AppLogger.info(
      'Batch reorder parallel: ${ids.length} items in $table '
      '(${ids.length} concurrent calls)',
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Upsert (Replace Sequential Check-Then-Insert/Update)
  // ═══════════════════════════════════════════════════════════════════

  /// Upsert a row using Supabase's native upsert, replacing the
  /// pattern of: select → check exists → update or insert.
  ///
  /// Example (before — 2-3 queries):
  ///   final existing = await supabase.from('table')
  ///     .select('id').eq('attempt_id', x).eq('question_id', y)
  ///     .maybeSingle();
  ///   if (existing != null) { update... } else { insert... }
  ///
  /// Example (after — 1 query):
  ///   await BatchQueryExecutor.smartUpsert(
  ///     supabase, 'table', data,
  ///     conflictColumns: ['attempt_id', 'question_id'],
  ///   );
  static Future<Map<String, dynamic>> smartUpsert(
    sb.SupabaseClient supabase,
    String table,
    Map<String, dynamic> data,
    {required List<String> conflictColumns,
    bool returnData = true}
  ) async {
    final query = supabase.from(table).upsert(
      data,
      onConflict: conflictColumns.join(','),
    );

    if (returnData) {
      final response = await query.select().single();
      AppLogger.debug(
        'Smart upsert: $table on conflict ${conflictColumns.join(",")} (1 call)',
      );
      return Map<String, dynamic>.from(response);
    }

    await query;
    AppLogger.debug(
      'Smart upsert silent: $table on conflict ${conflictColumns.join(",")} (1 call)',
    );
    return data;
  }

  /// Batch upsert multiple rows with conflict resolution.
  static Future<List<Map<String, dynamic>>> batchUpsert(
    sb.SupabaseClient supabase,
    String table,
    List<Map<String, dynamic>> rows,
    {required List<String> conflictColumns}
  ) async {
    if (rows.isEmpty) return [];

    if (rows.length <= _maxBatchSize) {
      final response = await supabase.from(table).upsert(
        rows,
        onConflict: conflictColumns.join(','),
      ).select();
      AppLogger.info(
        'Batch upsert: ${rows.length} rows into $table (1 call)',
      );
      return List<Map<String, dynamic>>.from(response);
    }

    final allResults = <Map<String, dynamic>>[];
    final chunks = _chunk(rows, _maxBatchSize);

    for (int i = 0; i < chunks.length; i++) {
      final response = await supabase.from(table).upsert(
        chunks[i],
        onConflict: conflictColumns.join(','),
      ).select();
      allResults.addAll(List<Map<String, dynamic>>.from(response));
    }

    return allResults;
  }

  // ═══════════════════════════════════════════════════════════════════
  // Batch Delete
  // ═══════════════════════════════════════════════════════════════════

  /// Delete multiple rows by IDs efficiently.
  ///
  /// Uses `.inFilter()` instead of sequential `.eq()` calls.
  static Future<void> batchDelete(
    sb.SupabaseClient supabase,
    String table,
    String idColumn,
    List<String> ids,
  ) async {
    if (ids.isEmpty) return;

    // Supabase .inFilter handles multiple IDs in one call
    await supabase.from(table).delete().inFilter(idColumn, ids);
    AppLogger.info(
      'Batch delete: ${ids.length} rows from $table (1 call)',
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Parallel Fetch (Replace Sequential Multi-Table Fetches)
  // ═══════════════════════════════════════════════════════════════════

  /// Fetch data from multiple tables in parallel.
  ///
  /// Replaces sequential fetches with Future.wait for concurrent
  /// execution, reducing total wall-clock time from sum(latencies)
  /// to max(latencies).
  ///
  /// Example (before — 3 sequential queries):
  ///   final exam = await getExam(id);
  ///   final questions = await getQuestions(id);
  ///   final students = await getStudents(id);
  ///
  /// Example (after — 3 parallel queries):
  ///   final results = await BatchQueryExecutor.parallelFetch([
  ///     () => supabase.from('exams').select().eq('id', id).single(),
  ///     () => supabase.from('exam_questions').select().eq('exam_id', id),
  ///     () => supabase.from('exam_students').select().eq('exam_id', id),
  ///   ]);
  static Future<List<dynamic>> parallelFetch(
    List<Future<dynamic>> futures,
  ) async {
    final results = await Future.wait(futures);
    AppLogger.debug(
      'Parallel fetch: ${futures.length} queries executed concurrently',
    );
    return results;
  }

  // ═══════════════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════════════

  /// Chunk a list into smaller lists of max [size].
  static List<List<T>> _chunk<T>(List<T> list, int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += size) {
      chunks.add(list.sublist(i, i + size > list.length ? list.length : i + size));
    }
    return chunks;
  }
}
