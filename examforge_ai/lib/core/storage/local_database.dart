/// Drift-based local database for ExamForge AI offline-first support.
///
/// Defines all tables needed for structured offline data persistence,
/// including sync queue, caching, drafts, user data, question bank,
/// resources, announcements, timetables, exam attempts, notifications,
/// connectivity logs, and sync metadata.
///
/// Run code generation after modifying this file:
/// ```sh
/// dart run build_runner build --delete-conflicting-outputs
/// ```

library;

import 'package:drift/drift.dart';

import '../utils/logger.dart';

// Conditional import for platform-specific database driver
// On web, use drift/web.dart with WebDatabase; on native, use drift/native.dart
import 'local_database_connection_stub.dart'
    if (dart.library.io) 'local_database_connection_io.dart'
    if (dart.library.html) 'local_database_connection_web.dart';

part 'local_database.g.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// TABLE DEFINITIONS
// ═══════════════════════════════════════════════════════════════════════════════

/// Offline sync queue – stores pending operations to be replayed
/// when connectivity is restored.
class LocalSyncQueueTable extends Table {
  /// Unique identifier for the sync queue entry.
  TextColumn get id => text()();

  /// Owner of the sync entry.
  TextColumn get userId => text()();

  /// Target table name on the remote.
  TextColumn get targetTable => text()();

  /// Remote record ID (null for inserts).
  TextColumn get recordId => text().nullable()();

  /// Operation type: insert, update, or delete.
  TextColumn get operation => text()();

  /// JSON-encoded payload for the operation.
  TextColumn get payload => text()();

  /// Priority (lower = higher priority). Defaults to 5.
  IntColumn get priority => integer().withDefault(const Constant(5))();

  /// Number of attempts made so far.
  IntColumn get attempts => integer().withDefault(const Constant(0))();

  /// Maximum number of retry attempts before marking dead.
  IntColumn get maxAttempts => integer().withDefault(const Constant(5))();

  /// Timestamp of the last attempt.
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();

  /// When the next retry should be attempted.
  DateTimeColumn get nextRetryAt => dateTime().nullable()();

  /// Status: pending, in_progress, completed, failed, dead.
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();

  /// Error message from the last failed attempt.
  TextColumn get errorMessage => text().nullable()();

  /// When the entry was created locally.
  DateTimeColumn get createdAt => dateTime()();

  /// When the entry was last updated locally.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cached API responses – stores server data locally for fast reads.
class LocalCacheTable extends Table {
  /// Unique identifier for the cache entry.
  TextColumn get id => text()();

  /// Owner of the cached data.
  TextColumn get userId => text()();

  /// Composite cache key (usually `resourceType:resourceId`).
  TextColumn get cacheKey => text()();

  /// Type of resource (e.g. `exam`, `question`, `user`).
  TextColumn get resourceType => text()();

  /// Identifier for the specific resource.
  TextColumn get resourceId => text()();

  /// JSON-encoded response data.
  TextColumn get data => text()();

  /// Cache version for optimistic concurrency.
  IntColumn get version => integer().withDefault(const Constant(1))();

  /// When the cache entry expires (null = never expires).
  DateTimeColumn get expiresAt => dateTime().nullable()();

  /// Approximate size of the cached data in bytes.
  IntColumn get fileSizeBytes =>
      integer().withDefault(const Constant(0))();

  /// Checksum of the data for integrity verification.
  TextColumn get checksum => text().nullable()();

  /// Whether the data is encrypted at rest.
  BoolColumn get isEncrypted =>
      boolean().withDefault(const Constant(false))();

  /// Number of times this entry has been accessed.
  IntColumn get accessCount =>
      integer().withDefault(const Constant(0))();

  /// When this entry was last accessed.
  DateTimeColumn get lastAccessedAt => dateTime().nullable()();

  /// When the cache entry was created.
  DateTimeColumn get createdAt => dateTime()();

  /// When the cache entry was last updated.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Draft work – in-progress exam/assignment/lesson_plan creation etc.
class LocalDraftsTable extends Table {
  /// Unique identifier for the draft.
  TextColumn get id => text()();

  /// Owner of the draft.
  TextColumn get userId => text()();

  /// Type of draft: exam, assignment, lesson_plan, question, resource.
  TextColumn get draftType => text()();

  /// Optional title for the draft.
  TextColumn get title => text().nullable()();

  /// JSON-encoded draft content.
  TextColumn get content => text()();

  /// School ID this draft belongs to.
  TextColumn get schoolId => text().nullable()();

  /// Subject ID this draft belongs to.
  TextColumn get subjectId => text().nullable()();

  /// Whether the draft has been synced to the server.
  BoolColumn get isSynced =>
      boolean().withDefault(const Constant(false))();

  /// When the draft was last edited.
  DateTimeColumn get lastEditedAt => dateTime()();

  /// When the draft was created.
  DateTimeColumn get createdAt => dateTime()();

  /// When the draft was last updated.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cached user profiles and preferences for quick local access.
class LocalUserDataTable extends Table {
  /// Unique identifier for the user data entry.
  TextColumn get id => text()();

  /// User ID this data belongs to.
  TextColumn get userId => text()();

  /// JSON-encoded profile data.
  TextColumn get profileData => text()();

  /// JSON-encoded user preferences (null if not set).
  TextColumn get preferences => text().nullable()();

  /// User role (admin, teacher, student, parent, super_admin).
  TextColumn get role => text()();

  /// School ID the user belongs to.
  TextColumn get schoolId => text().nullable()();

  /// When the profile was last synced with the server.
  DateTimeColumn get lastSyncedAt => dateTime()();

  /// When the entry was created.
  DateTimeColumn get createdAt => dateTime()();

  /// When the entry was last updated.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cached questions for offline question-bank access.
class LocalQuestionBankTable extends Table {
  /// Unique identifier for the cached question.
  TextColumn get id => text()();

  /// JSON-encoded question data.
  TextColumn get questionData => text()();

  /// Subject ID this question belongs to.
  TextColumn get subjectId => text()();

  /// Class level (e.g. `JSS1`, `SSS2`).
  TextColumn get classLevel => text()();

  /// School ID (null for global marketplace questions).
  TextColumn get schoolId => text().nullable()();

  /// Whether the question has been synced to the server.
  BoolColumn get isSynced =>
      boolean().withDefault(const Constant(false))();

  /// When the question was last modified.
  DateTimeColumn get lastModifiedAt => dateTime()();

  /// When the entry was created.
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Downloaded educational resources available offline.
class LocalResourcesTable extends Table {
  /// Unique identifier for the cached resource.
  TextColumn get id => text()();

  /// Owner of the cached resource.
  TextColumn get userId => text()();

  /// Resource type (e.g. `pdf`, `video`, `document`).
  TextColumn get resourceType => text()();

  /// Remote resource identifier.
  TextColumn get resourceId => text()();

  /// Human-readable title.
  TextColumn get title => text()();

  /// Local file path where the resource is stored.
  TextColumn get filePath => text()();

  /// File size in bytes.
  IntColumn get fileSizeBytes => integer()();

  /// MIME type of the resource.
  TextColumn get mimeType => text().nullable()();

  /// Checksum for integrity verification.
  TextColumn get checksum => text().nullable()();

  /// When the resource license expires (null = no expiry).
  DateTimeColumn get licenseExpiresAt => dateTime().nullable()();

  /// Whether the resource file is currently available on disk.
  BoolColumn get isAvailable =>
      boolean().withDefault(const Constant(true))();

  /// Number of times the resource has been accessed.
  IntColumn get accessCount =>
      integer().withDefault(const Constant(0))();

  /// When the resource was last accessed.
  DateTimeColumn get lastAccessedAt => dateTime().nullable()();

  /// When the entry was created.
  DateTimeColumn get createdAt => dateTime()();

  /// When the entry was last updated.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cached announcements for offline reading.
class LocalAnnouncementsTable extends Table {
  /// Unique identifier for the cached announcement.
  TextColumn get id => text()();

  /// School ID this announcement belongs to.
  TextColumn get schoolId => text()();

  /// JSON-encoded announcement data.
  TextColumn get announcementData => text()();

  /// Whether the user has read this announcement.
  BoolColumn get isRead =>
      boolean().withDefault(const Constant(false))();

  /// When the announcement was created on the server.
  DateTimeColumn get createdAt => dateTime()();

  /// When the announcement expires (null = never expires).
  DateTimeColumn get expiresAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cached timetables for offline schedule access.
class LocalTimetableTable extends Table {
  /// Unique identifier for the cached timetable.
  TextColumn get id => text()();

  /// School ID this timetable belongs to.
  TextColumn get schoolId => text()();

  /// Class ID (null for teacher / school-wide timetables).
  TextColumn get classId => text().nullable()();

  /// JSON-encoded timetable data.
  TextColumn get timetableData => text()();

  /// Start of the week this timetable covers.
  DateTimeColumn get weekStart => dateTime()();

  /// When the entry was created.
  DateTimeColumn get createdAt => dateTime()();

  /// When the entry was last updated.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Offline exam attempts – stored locally and synced after completion.
class LocalExamAttemptsTable extends Table {
  /// Unique identifier for the exam attempt.
  TextColumn get id => text()();

  /// Exam ID this attempt belongs to.
  TextColumn get examId => text()();

  /// Student ID who is taking the exam.
  TextColumn get studentId => text()();

  /// School ID (null for marketplace exams).
  TextColumn get schoolId => text().nullable()();

  /// JSON-encoded attempt metadata.
  TextColumn get attemptData => text()();

  /// JSON-encoded answers.
  /// SECURITY: When isEncrypted is true, this contains AES-encrypted
  /// ciphertext (base64). When false, it contains plaintext JSON (legacy).
  TextColumn get answers => text()();

  /// Whether the answers column is encrypted.
  /// All new records are encrypted. Legacy records may be plaintext.
  BoolColumn get isEncrypted =>
      boolean().withDefault(const Constant(true))();

  /// When the attempt was started.
  DateTimeColumn get startedAt => dateTime()();

  /// When the attempt was completed (null if in progress).
  DateTimeColumn get completedAt => dateTime().nullable()();

  /// Total time taken in seconds.
  IntColumn get timeTakenSeconds =>
      integer().withDefault(const Constant(0))();

  /// Hash for integrity verification (anti-cheat).
  TextColumn get integrityHash => text().nullable()();

  /// Sync status: pending, synced, validated, rejected.
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending'))();

  /// Number of sync attempts made.
  IntColumn get syncAttempts =>
      integer().withDefault(const Constant(0))();

  /// When the attempt was successfully synced.
  DateTimeColumn get syncedAt => dateTime().nullable()();

  /// JSON-encoded validation errors from the server.
  TextColumn get validationErrors => text().nullable()();

  /// When the entry was created.
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cached notifications for offline access.
class LocalNotificationsTable extends Table {
  /// Unique identifier for the cached notification.
  TextColumn get id => text()();

  /// User ID this notification belongs to.
  TextColumn get userId => text()();

  /// JSON-encoded notification data.
  TextColumn get notificationData => text()();

  /// Notification type (e.g. `exam_reminder`, `result_published`).
  TextColumn get type => text()();

  /// Notification title.
  TextColumn get title => text()();

  /// Whether the user has read this notification.
  BoolColumn get isRead =>
      boolean().withDefault(const Constant(false))();

  /// When the notification was received.
  DateTimeColumn get receivedAt => dateTime()();

  /// When the entry was created.
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local connectivity logs for network quality tracking.
class ConnectivityLogsTable extends Table {
  /// Unique identifier for the log entry.
  TextColumn get id => text()();

  /// Connection type (wifi, mobile, ethernet, none).
  TextColumn get connectionType => text()();

  /// Connection quality (excellent, good, poor, offline).
  TextColumn get connectionQuality => text()();

  /// Latency in milliseconds.
  IntColumn get latencyMs => integer().nullable()();

  /// Bandwidth in kilobits per second.
  IntColumn get bandwidthKbps => integer().nullable()();

  /// Whether the device was offline at the time of recording.
  BoolColumn get wasOffline => boolean()();

  /// Duration of the offline period in seconds (null if online).
  IntColumn get offlineDurationSeconds => integer().nullable()();

  /// When the log was recorded.
  DateTimeColumn get recordedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Per-table sync metadata – tracks the last sync state for each table.
class LocalSyncMetadataTable extends Table {
  /// Unique identifier for the metadata entry.
  TextColumn get id => text()();

  /// User ID this metadata belongs to.
  TextColumn get userId => text()();

  /// Table name this metadata tracks.
  TextColumn get targetTable => text()();

  /// When the table was last fully synced.
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  /// Sync cursor for incremental syncs.
  TextColumn get syncCursor => text().nullable()();

  /// Number of records at the time of last sync.
  IntColumn get recordCount =>
      integer().withDefault(const Constant(0))();

  /// Checksum of the table data at last sync.
  TextColumn get checksum => text().nullable()();

  /// Whether the last sync was a full sync.
  BoolColumn get isFullSync =>
      boolean().withDefault(const Constant(false))();

  /// When the metadata entry was created.
  DateTimeColumn get createdAt => dateTime()();

  /// When the metadata entry was last updated.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ═══════════════════════════════════════════════════════════════════════════════
// DATABASE CLASS
// ═══════════════════════════════════════════════════════════════════════════════

/// Main Drift database for ExamForge AI offline-first support.
///
/// After modifying tables, run:
/// ```sh
/// dart run build_runner build --delete-conflicting-outputs
/// ```
@DriftDatabase(
  tables: [
    LocalSyncQueueTable,
    LocalCacheTable,
    LocalDraftsTable,
    LocalUserDataTable,
    LocalQuestionBankTable,
    LocalResourcesTable,
    LocalAnnouncementsTable,
    LocalTimetableTable,
    LocalExamAttemptsTable,
    LocalNotificationsTable,
    ConnectivityLogsTable,
    LocalSyncMetadataTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Creates the [AppDatabase] with a platform-appropriate connection.
  AppDatabase() : super(createDatabaseExecutor());

  /// Creates the [AppDatabase] with an existing [QueryExecutor].
  ///
  /// Useful for testing with an in-memory database.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          AppLogger.info('AppDatabase: all tables created');
        },
        onUpgrade: (Migrator m, int from, int to) async {
          AppLogger.info(
            'AppDatabase: migrating from v$from to v$to',
          );
          // Future migrations go here.
        },
        beforeOpen: (OpeningDetails details) async {
          AppLogger.info(
            'AppDatabase: opening (v${details.versionBefore})',
          );
        },
      );

  // ─── DAO-style convenience getters ────────────────────────────────

  /// Access the sync queue table.
  $LocalSyncQueueTableTable get syncQueue => localSyncQueueTable;

  /// Access the cache table.
  $LocalCacheTableTable get cache => localCacheTable;

  /// Access the drafts table.
  $LocalDraftsTableTable get drafts => localDraftsTable;

  /// Access the user data table.
  $LocalUserDataTableTable get userData => localUserDataTable;

  /// Access the question bank table.
  $LocalQuestionBankTableTable get questionBank => localQuestionBankTable;

  /// Access the resources table.
  $LocalResourcesTableTable get resources => localResourcesTable;

  /// Access the announcements table.
  $LocalAnnouncementsTableTable get announcements => localAnnouncementsTable;

  /// Access the timetable table.
  $LocalTimetableTableTable get timetable => localTimetableTable;

  /// Access the exam attempts table.
  $LocalExamAttemptsTableTable get examAttempts => localExamAttemptsTable;

  /// Access the notifications table.
  $LocalNotificationsTableTable get notifications => localNotificationsTable;

  /// Access the connectivity logs table.
  $ConnectivityLogsTableTable get connectivityLogs => connectivityLogsTable;

  /// Access the sync metadata table.
  $LocalSyncMetadataTableTable get syncMetadata => localSyncMetadataTable;

  // ─── Utility methods ─────────────────────────────────────────────

  /// Deletes all rows from every table.
  ///
  /// Use with caution – this is destructive and irreversible.
  Future<void> clearAllData() async {
    await transaction(() async {
      await delete(localSyncQueueTable).go();
      await delete(localCacheTable).go();
      await delete(localDraftsTable).go();
      await delete(localUserDataTable).go();
      await delete(localQuestionBankTable).go();
      await delete(localResourcesTable).go();
      await delete(localAnnouncementsTable).go();
      await delete(localTimetableTable).go();
      await delete(localExamAttemptsTable).go();
      await delete(localNotificationsTable).go();
      await delete(connectivityLogsTable).go();
      await delete(localSyncMetadataTable).go();
      AppLogger.info('AppDatabase: all data cleared');
    });
  }

  /// Deletes cache entries that have passed their expiry time.
  Future<int> clearExpiredCache() async {
    final now = DateTime.now();
    final count = await (delete(localCacheTable)
          ..where((t) => t.expiresAt.isNotNull() & t.expiresAt.isSmallerThanValue(now)))
        .go();
    AppLogger.info('AppDatabase: cleared $count expired cache entries');
    return count;
  }

  /// Returns a map of table name → row count for diagnostic purposes.
  Future<Map<String, int>> getDatabaseSize() async {
    final results = <String, int>{};

    results['localSyncQueue'] =
        await (select(localSyncQueueTable)).get().then((r) => r.length);
    results['localCache'] =
        await (select(localCacheTable)).get().then((r) => r.length);
    results['localDrafts'] =
        await (select(localDraftsTable)).get().then((r) => r.length);
    results['localUserData'] =
        await (select(localUserDataTable)).get().then((r) => r.length);
    results['localQuestionBank'] =
        await (select(localQuestionBankTable)).get().then((r) => r.length);
    results['localResources'] =
        await (select(localResourcesTable)).get().then((r) => r.length);
    results['localAnnouncements'] =
        await (select(localAnnouncementsTable)).get().then((r) => r.length);
    results['localTimetable'] =
        await (select(localTimetableTable)).get().then((r) => r.length);
    results['localExamAttempts'] =
        await (select(localExamAttemptsTable)).get().then((r) => r.length);
    results['localNotifications'] =
        await (select(localNotificationsTable)).get().then((r) => r.length);
    results['connectivityLogs'] =
        await (select(connectivityLogsTable)).get().then((r) => r.length);
    results['localSyncMetadata'] =
        await (select(localSyncMetadataTable)).get().then((r) => r.length);

    return results;
  }

  /// Compacts the database by running VACUUM.
  ///
  /// This reclaims unused space and can improve read performance
  /// after large deletions. Must be run outside a transaction.
  Future<void> vacuum() async {
    await customStatement('VACUUM');
    AppLogger.info('AppDatabase: VACUUM completed');
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CONNECTION HELPER
// ═══════════════════════════════════════════════════════════════════════════════

/// Creates the appropriate database query executor for the current platform.
/// On native platforms (iOS/Android/macOS/Windows/Linux), uses SQLite via dart:ffi.
/// On web, uses a WebDatabase backed by IndexedDB or OPFS.
QueryExecutor createDatabaseExecutor() => getQueryExecutor();
