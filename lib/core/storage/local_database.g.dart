// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_database.dart';

// ignore_for_file: type=lint
class $LocalSyncQueueTableTable extends LocalSyncQueueTable
    with TableInfo<$LocalSyncQueueTableTable, LocalSyncQueueTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSyncQueueTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _targetTableMeta =
      const VerificationMeta('targetTable');
  @override
  late final GeneratedColumn<String> targetTable = GeneratedColumn<String>(
      'target_table', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _recordIdMeta =
      const VerificationMeta('recordId');
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
      'record_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _operationMeta =
      const VerificationMeta('operation');
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
      'operation', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
      'priority', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(5));
  static const VerificationMeta _attemptsMeta =
      const VerificationMeta('attempts');
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
      'attempts', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _maxAttemptsMeta =
      const VerificationMeta('maxAttempts');
  @override
  late final GeneratedColumn<int> maxAttempts = GeneratedColumn<int>(
      'max_attempts', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(5));
  static const VerificationMeta _lastAttemptAtMeta =
      const VerificationMeta('lastAttemptAt');
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>('last_attempt_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _nextRetryAtMeta =
      const VerificationMeta('nextRetryAt');
  @override
  late final GeneratedColumn<DateTime> nextRetryAt = GeneratedColumn<DateTime>(
      'next_retry_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _errorMessageMeta =
      const VerificationMeta('errorMessage');
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
      'error_message', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        targetTable,
        recordId,
        operation,
        payload,
        priority,
        attempts,
        maxAttempts,
        lastAttemptAt,
        nextRetryAt,
        status,
        errorMessage,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_sync_queue_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<LocalSyncQueueTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('target_table')) {
      context.handle(
          _targetTableMeta,
          targetTable.isAcceptableOrUnknown(
              data['target_table']!, _targetTableMeta));
    } else if (isInserting) {
      context.missing(_targetTableMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(_recordIdMeta,
          recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta));
    }
    if (data.containsKey('operation')) {
      context.handle(_operationMeta,
          operation.isAcceptableOrUnknown(data['operation']!, _operationMeta));
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    }
    if (data.containsKey('attempts')) {
      context.handle(_attemptsMeta,
          attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta));
    }
    if (data.containsKey('max_attempts')) {
      context.handle(
          _maxAttemptsMeta,
          maxAttempts.isAcceptableOrUnknown(
              data['max_attempts']!, _maxAttemptsMeta));
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
          _lastAttemptAtMeta,
          lastAttemptAt.isAcceptableOrUnknown(
              data['last_attempt_at']!, _lastAttemptAtMeta));
    }
    if (data.containsKey('next_retry_at')) {
      context.handle(
          _nextRetryAtMeta,
          nextRetryAt.isAcceptableOrUnknown(
              data['next_retry_at']!, _nextRetryAtMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('error_message')) {
      context.handle(
          _errorMessageMeta,
          errorMessage.isAcceptableOrUnknown(
              data['error_message']!, _errorMessageMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalSyncQueueTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSyncQueueTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      targetTable: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}target_table'])!,
      recordId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}record_id']),
      operation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operation'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}priority'])!,
      attempts: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempts'])!,
      maxAttempts: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}max_attempts'])!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_attempt_at']),
      nextRetryAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}next_retry_at']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      errorMessage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error_message']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $LocalSyncQueueTableTable createAlias(String alias) {
    return $LocalSyncQueueTableTable(attachedDatabase, alias);
  }
}

class LocalSyncQueueTableData extends DataClass
    implements Insertable<LocalSyncQueueTableData> {
  /// Unique identifier for the sync queue entry.
  final String id;

  /// Owner of the sync entry.
  final String userId;

  /// Target table name on the remote.
  final String targetTable;

  /// Remote record ID (null for inserts).
  final String? recordId;

  /// Operation type: insert, update, or delete.
  final String operation;

  /// JSON-encoded payload for the operation.
  final String payload;

  /// Priority (lower = higher priority). Defaults to 5.
  final int priority;

  /// Number of attempts made so far.
  final int attempts;

  /// Maximum number of retry attempts before marking dead.
  final int maxAttempts;

  /// Timestamp of the last attempt.
  final DateTime? lastAttemptAt;

  /// When the next retry should be attempted.
  final DateTime? nextRetryAt;

  /// Status: pending, in_progress, completed, failed, dead.
  final String status;

  /// Error message from the last failed attempt.
  final String? errorMessage;

  /// When the entry was created locally.
  final DateTime createdAt;

  /// When the entry was last updated locally.
  final DateTime updatedAt;
  const LocalSyncQueueTableData(
      {required this.id,
      required this.userId,
      required this.targetTable,
      this.recordId,
      required this.operation,
      required this.payload,
      required this.priority,
      required this.attempts,
      required this.maxAttempts,
      this.lastAttemptAt,
      this.nextRetryAt,
      required this.status,
      this.errorMessage,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['target_table'] = Variable<String>(targetTable);
    if (!nullToAbsent || recordId != null) {
      map['record_id'] = Variable<String>(recordId);
    }
    map['operation'] = Variable<String>(operation);
    map['payload'] = Variable<String>(payload);
    map['priority'] = Variable<int>(priority);
    map['attempts'] = Variable<int>(attempts);
    map['max_attempts'] = Variable<int>(maxAttempts);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    if (!nullToAbsent || nextRetryAt != null) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalSyncQueueTableCompanion toCompanion(bool nullToAbsent) {
    return LocalSyncQueueTableCompanion(
      id: Value(id),
      userId: Value(userId),
      targetTable: Value(targetTable),
      recordId: recordId == null && nullToAbsent
          ? const Value.absent()
          : Value(recordId),
      operation: Value(operation),
      payload: Value(payload),
      priority: Value(priority),
      attempts: Value(attempts),
      maxAttempts: Value(maxAttempts),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      nextRetryAt: nextRetryAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextRetryAt),
      status: Value(status),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalSyncQueueTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSyncQueueTableData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      targetTable: serializer.fromJson<String>(json['targetTable']),
      recordId: serializer.fromJson<String?>(json['recordId']),
      operation: serializer.fromJson<String>(json['operation']),
      payload: serializer.fromJson<String>(json['payload']),
      priority: serializer.fromJson<int>(json['priority']),
      attempts: serializer.fromJson<int>(json['attempts']),
      maxAttempts: serializer.fromJson<int>(json['maxAttempts']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
      nextRetryAt: serializer.fromJson<DateTime?>(json['nextRetryAt']),
      status: serializer.fromJson<String>(json['status']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'targetTable': serializer.toJson<String>(targetTable),
      'recordId': serializer.toJson<String?>(recordId),
      'operation': serializer.toJson<String>(operation),
      'payload': serializer.toJson<String>(payload),
      'priority': serializer.toJson<int>(priority),
      'attempts': serializer.toJson<int>(attempts),
      'maxAttempts': serializer.toJson<int>(maxAttempts),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
      'nextRetryAt': serializer.toJson<DateTime?>(nextRetryAt),
      'status': serializer.toJson<String>(status),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalSyncQueueTableData copyWith(
          {String? id,
          String? userId,
          String? targetTable,
          Value<String?> recordId = const Value.absent(),
          String? operation,
          String? payload,
          int? priority,
          int? attempts,
          int? maxAttempts,
          Value<DateTime?> lastAttemptAt = const Value.absent(),
          Value<DateTime?> nextRetryAt = const Value.absent(),
          String? status,
          Value<String?> errorMessage = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      LocalSyncQueueTableData(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        targetTable: targetTable ?? this.targetTable,
        recordId: recordId.present ? recordId.value : this.recordId,
        operation: operation ?? this.operation,
        payload: payload ?? this.payload,
        priority: priority ?? this.priority,
        attempts: attempts ?? this.attempts,
        maxAttempts: maxAttempts ?? this.maxAttempts,
        lastAttemptAt:
            lastAttemptAt.present ? lastAttemptAt.value : this.lastAttemptAt,
        nextRetryAt: nextRetryAt.present ? nextRetryAt.value : this.nextRetryAt,
        status: status ?? this.status,
        errorMessage:
            errorMessage.present ? errorMessage.value : this.errorMessage,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  LocalSyncQueueTableData copyWithCompanion(LocalSyncQueueTableCompanion data) {
    return LocalSyncQueueTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      targetTable:
          data.targetTable.present ? data.targetTable.value : this.targetTable,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      operation: data.operation.present ? data.operation.value : this.operation,
      payload: data.payload.present ? data.payload.value : this.payload,
      priority: data.priority.present ? data.priority.value : this.priority,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      maxAttempts:
          data.maxAttempts.present ? data.maxAttempts.value : this.maxAttempts,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      nextRetryAt:
          data.nextRetryAt.present ? data.nextRetryAt.value : this.nextRetryAt,
      status: data.status.present ? data.status.value : this.status,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSyncQueueTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('targetTable: $targetTable, ')
          ..write('recordId: $recordId, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('priority: $priority, ')
          ..write('attempts: $attempts, ')
          ..write('maxAttempts: $maxAttempts, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('status: $status, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      targetTable,
      recordId,
      operation,
      payload,
      priority,
      attempts,
      maxAttempts,
      lastAttemptAt,
      nextRetryAt,
      status,
      errorMessage,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSyncQueueTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.targetTable == this.targetTable &&
          other.recordId == this.recordId &&
          other.operation == this.operation &&
          other.payload == this.payload &&
          other.priority == this.priority &&
          other.attempts == this.attempts &&
          other.maxAttempts == this.maxAttempts &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.nextRetryAt == this.nextRetryAt &&
          other.status == this.status &&
          other.errorMessage == this.errorMessage &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalSyncQueueTableCompanion
    extends UpdateCompanion<LocalSyncQueueTableData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> targetTable;
  final Value<String?> recordId;
  final Value<String> operation;
  final Value<String> payload;
  final Value<int> priority;
  final Value<int> attempts;
  final Value<int> maxAttempts;
  final Value<DateTime?> lastAttemptAt;
  final Value<DateTime?> nextRetryAt;
  final Value<String> status;
  final Value<String?> errorMessage;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalSyncQueueTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.targetTable = const Value.absent(),
    this.recordId = const Value.absent(),
    this.operation = const Value.absent(),
    this.payload = const Value.absent(),
    this.priority = const Value.absent(),
    this.attempts = const Value.absent(),
    this.maxAttempts = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.status = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSyncQueueTableCompanion.insert({
    required String id,
    required String userId,
    required String targetTable,
    this.recordId = const Value.absent(),
    required String operation,
    required String payload,
    this.priority = const Value.absent(),
    this.attempts = const Value.absent(),
    this.maxAttempts = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.status = const Value.absent(),
    this.errorMessage = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        targetTable = Value(targetTable),
        operation = Value(operation),
        payload = Value(payload),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<LocalSyncQueueTableData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? targetTable,
    Expression<String>? recordId,
    Expression<String>? operation,
    Expression<String>? payload,
    Expression<int>? priority,
    Expression<int>? attempts,
    Expression<int>? maxAttempts,
    Expression<DateTime>? lastAttemptAt,
    Expression<DateTime>? nextRetryAt,
    Expression<String>? status,
    Expression<String>? errorMessage,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (targetTable != null) 'target_table': targetTable,
      if (recordId != null) 'record_id': recordId,
      if (operation != null) 'operation': operation,
      if (payload != null) 'payload': payload,
      if (priority != null) 'priority': priority,
      if (attempts != null) 'attempts': attempts,
      if (maxAttempts != null) 'max_attempts': maxAttempts,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (nextRetryAt != null) 'next_retry_at': nextRetryAt,
      if (status != null) 'status': status,
      if (errorMessage != null) 'error_message': errorMessage,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSyncQueueTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? targetTable,
      Value<String?>? recordId,
      Value<String>? operation,
      Value<String>? payload,
      Value<int>? priority,
      Value<int>? attempts,
      Value<int>? maxAttempts,
      Value<DateTime?>? lastAttemptAt,
      Value<DateTime?>? nextRetryAt,
      Value<String>? status,
      Value<String?>? errorMessage,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return LocalSyncQueueTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      targetTable: targetTable ?? this.targetTable,
      recordId: recordId ?? this.recordId,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      priority: priority ?? this.priority,
      attempts: attempts ?? this.attempts,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (targetTable.present) {
      map['target_table'] = Variable<String>(targetTable.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (maxAttempts.present) {
      map['max_attempts'] = Variable<int>(maxAttempts.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (nextRetryAt.present) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSyncQueueTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('targetTable: $targetTable, ')
          ..write('recordId: $recordId, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('priority: $priority, ')
          ..write('attempts: $attempts, ')
          ..write('maxAttempts: $maxAttempts, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('status: $status, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalCacheTableTable extends LocalCacheTable
    with TableInfo<$LocalCacheTableTable, LocalCacheTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalCacheTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cacheKeyMeta =
      const VerificationMeta('cacheKey');
  @override
  late final GeneratedColumn<String> cacheKey = GeneratedColumn<String>(
      'cache_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _resourceTypeMeta =
      const VerificationMeta('resourceType');
  @override
  late final GeneratedColumn<String> resourceType = GeneratedColumn<String>(
      'resource_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _resourceIdMeta =
      const VerificationMeta('resourceId');
  @override
  late final GeneratedColumn<String> resourceId = GeneratedColumn<String>(
      'resource_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
      'data', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _expiresAtMeta =
      const VerificationMeta('expiresAt');
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
      'expires_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _fileSizeBytesMeta =
      const VerificationMeta('fileSizeBytes');
  @override
  late final GeneratedColumn<int> fileSizeBytes = GeneratedColumn<int>(
      'file_size_bytes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _checksumMeta =
      const VerificationMeta('checksum');
  @override
  late final GeneratedColumn<String> checksum = GeneratedColumn<String>(
      'checksum', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isEncryptedMeta =
      const VerificationMeta('isEncrypted');
  @override
  late final GeneratedColumn<bool> isEncrypted = GeneratedColumn<bool>(
      'is_encrypted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_encrypted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _accessCountMeta =
      const VerificationMeta('accessCount');
  @override
  late final GeneratedColumn<int> accessCount = GeneratedColumn<int>(
      'access_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastAccessedAtMeta =
      const VerificationMeta('lastAccessedAt');
  @override
  late final GeneratedColumn<DateTime> lastAccessedAt =
      GeneratedColumn<DateTime>('last_accessed_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        cacheKey,
        resourceType,
        resourceId,
        data,
        version,
        expiresAt,
        fileSizeBytes,
        checksum,
        isEncrypted,
        accessCount,
        lastAccessedAt,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_cache_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<LocalCacheTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('cache_key')) {
      context.handle(_cacheKeyMeta,
          cacheKey.isAcceptableOrUnknown(data['cache_key']!, _cacheKeyMeta));
    } else if (isInserting) {
      context.missing(_cacheKeyMeta);
    }
    if (data.containsKey('resource_type')) {
      context.handle(
          _resourceTypeMeta,
          resourceType.isAcceptableOrUnknown(
              data['resource_type']!, _resourceTypeMeta));
    } else if (isInserting) {
      context.missing(_resourceTypeMeta);
    }
    if (data.containsKey('resource_id')) {
      context.handle(
          _resourceIdMeta,
          resourceId.isAcceptableOrUnknown(
              data['resource_id']!, _resourceIdMeta));
    } else if (isInserting) {
      context.missing(_resourceIdMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
          _dataMeta, this.data.isAcceptableOrUnknown(data['data']!, _dataMeta));
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    }
    if (data.containsKey('expires_at')) {
      context.handle(_expiresAtMeta,
          expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta));
    }
    if (data.containsKey('file_size_bytes')) {
      context.handle(
          _fileSizeBytesMeta,
          fileSizeBytes.isAcceptableOrUnknown(
              data['file_size_bytes']!, _fileSizeBytesMeta));
    }
    if (data.containsKey('checksum')) {
      context.handle(_checksumMeta,
          checksum.isAcceptableOrUnknown(data['checksum']!, _checksumMeta));
    }
    if (data.containsKey('is_encrypted')) {
      context.handle(
          _isEncryptedMeta,
          isEncrypted.isAcceptableOrUnknown(
              data['is_encrypted']!, _isEncryptedMeta));
    }
    if (data.containsKey('access_count')) {
      context.handle(
          _accessCountMeta,
          accessCount.isAcceptableOrUnknown(
              data['access_count']!, _accessCountMeta));
    }
    if (data.containsKey('last_accessed_at')) {
      context.handle(
          _lastAccessedAtMeta,
          lastAccessedAt.isAcceptableOrUnknown(
              data['last_accessed_at']!, _lastAccessedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalCacheTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalCacheTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      cacheKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cache_key'])!,
      resourceType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}resource_type'])!,
      resourceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}resource_id'])!,
      data: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data'])!,
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
      expiresAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}expires_at']),
      fileSizeBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}file_size_bytes'])!,
      checksum: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}checksum']),
      isEncrypted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_encrypted'])!,
      accessCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}access_count'])!,
      lastAccessedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_accessed_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $LocalCacheTableTable createAlias(String alias) {
    return $LocalCacheTableTable(attachedDatabase, alias);
  }
}

class LocalCacheTableData extends DataClass
    implements Insertable<LocalCacheTableData> {
  /// Unique identifier for the cache entry.
  final String id;

  /// Owner of the cached data.
  final String userId;

  /// Composite cache key (usually `resourceType:resourceId`).
  final String cacheKey;

  /// Type of resource (e.g. `exam`, `question`, `user`).
  final String resourceType;

  /// Identifier for the specific resource.
  final String resourceId;

  /// JSON-encoded response data.
  final String data;

  /// Cache version for optimistic concurrency.
  final int version;

  /// When the cache entry expires (null = never expires).
  final DateTime? expiresAt;

  /// Approximate size of the cached data in bytes.
  final int fileSizeBytes;

  /// Checksum of the data for integrity verification.
  final String? checksum;

  /// Whether the data is encrypted at rest.
  final bool isEncrypted;

  /// Number of times this entry has been accessed.
  final int accessCount;

  /// When this entry was last accessed.
  final DateTime? lastAccessedAt;

  /// When the cache entry was created.
  final DateTime createdAt;

  /// When the cache entry was last updated.
  final DateTime updatedAt;
  const LocalCacheTableData(
      {required this.id,
      required this.userId,
      required this.cacheKey,
      required this.resourceType,
      required this.resourceId,
      required this.data,
      required this.version,
      this.expiresAt,
      required this.fileSizeBytes,
      this.checksum,
      required this.isEncrypted,
      required this.accessCount,
      this.lastAccessedAt,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['cache_key'] = Variable<String>(cacheKey);
    map['resource_type'] = Variable<String>(resourceType);
    map['resource_id'] = Variable<String>(resourceId);
    map['data'] = Variable<String>(data);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<DateTime>(expiresAt);
    }
    map['file_size_bytes'] = Variable<int>(fileSizeBytes);
    if (!nullToAbsent || checksum != null) {
      map['checksum'] = Variable<String>(checksum);
    }
    map['is_encrypted'] = Variable<bool>(isEncrypted);
    map['access_count'] = Variable<int>(accessCount);
    if (!nullToAbsent || lastAccessedAt != null) {
      map['last_accessed_at'] = Variable<DateTime>(lastAccessedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalCacheTableCompanion toCompanion(bool nullToAbsent) {
    return LocalCacheTableCompanion(
      id: Value(id),
      userId: Value(userId),
      cacheKey: Value(cacheKey),
      resourceType: Value(resourceType),
      resourceId: Value(resourceId),
      data: Value(data),
      version: Value(version),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
      fileSizeBytes: Value(fileSizeBytes),
      checksum: checksum == null && nullToAbsent
          ? const Value.absent()
          : Value(checksum),
      isEncrypted: Value(isEncrypted),
      accessCount: Value(accessCount),
      lastAccessedAt: lastAccessedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAccessedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalCacheTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalCacheTableData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      cacheKey: serializer.fromJson<String>(json['cacheKey']),
      resourceType: serializer.fromJson<String>(json['resourceType']),
      resourceId: serializer.fromJson<String>(json['resourceId']),
      data: serializer.fromJson<String>(json['data']),
      version: serializer.fromJson<int>(json['version']),
      expiresAt: serializer.fromJson<DateTime?>(json['expiresAt']),
      fileSizeBytes: serializer.fromJson<int>(json['fileSizeBytes']),
      checksum: serializer.fromJson<String?>(json['checksum']),
      isEncrypted: serializer.fromJson<bool>(json['isEncrypted']),
      accessCount: serializer.fromJson<int>(json['accessCount']),
      lastAccessedAt: serializer.fromJson<DateTime?>(json['lastAccessedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'cacheKey': serializer.toJson<String>(cacheKey),
      'resourceType': serializer.toJson<String>(resourceType),
      'resourceId': serializer.toJson<String>(resourceId),
      'data': serializer.toJson<String>(data),
      'version': serializer.toJson<int>(version),
      'expiresAt': serializer.toJson<DateTime?>(expiresAt),
      'fileSizeBytes': serializer.toJson<int>(fileSizeBytes),
      'checksum': serializer.toJson<String?>(checksum),
      'isEncrypted': serializer.toJson<bool>(isEncrypted),
      'accessCount': serializer.toJson<int>(accessCount),
      'lastAccessedAt': serializer.toJson<DateTime?>(lastAccessedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalCacheTableData copyWith(
          {String? id,
          String? userId,
          String? cacheKey,
          String? resourceType,
          String? resourceId,
          String? data,
          int? version,
          Value<DateTime?> expiresAt = const Value.absent(),
          int? fileSizeBytes,
          Value<String?> checksum = const Value.absent(),
          bool? isEncrypted,
          int? accessCount,
          Value<DateTime?> lastAccessedAt = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      LocalCacheTableData(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        cacheKey: cacheKey ?? this.cacheKey,
        resourceType: resourceType ?? this.resourceType,
        resourceId: resourceId ?? this.resourceId,
        data: data ?? this.data,
        version: version ?? this.version,
        expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
        fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
        checksum: checksum.present ? checksum.value : this.checksum,
        isEncrypted: isEncrypted ?? this.isEncrypted,
        accessCount: accessCount ?? this.accessCount,
        lastAccessedAt:
            lastAccessedAt.present ? lastAccessedAt.value : this.lastAccessedAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  LocalCacheTableData copyWithCompanion(LocalCacheTableCompanion data) {
    return LocalCacheTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      resourceType: data.resourceType.present
          ? data.resourceType.value
          : this.resourceType,
      resourceId:
          data.resourceId.present ? data.resourceId.value : this.resourceId,
      data: data.data.present ? data.data.value : this.data,
      version: data.version.present ? data.version.value : this.version,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      fileSizeBytes: data.fileSizeBytes.present
          ? data.fileSizeBytes.value
          : this.fileSizeBytes,
      checksum: data.checksum.present ? data.checksum.value : this.checksum,
      isEncrypted:
          data.isEncrypted.present ? data.isEncrypted.value : this.isEncrypted,
      accessCount:
          data.accessCount.present ? data.accessCount.value : this.accessCount,
      lastAccessedAt: data.lastAccessedAt.present
          ? data.lastAccessedAt.value
          : this.lastAccessedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalCacheTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('cacheKey: $cacheKey, ')
          ..write('resourceType: $resourceType, ')
          ..write('resourceId: $resourceId, ')
          ..write('data: $data, ')
          ..write('version: $version, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('checksum: $checksum, ')
          ..write('isEncrypted: $isEncrypted, ')
          ..write('accessCount: $accessCount, ')
          ..write('lastAccessedAt: $lastAccessedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      cacheKey,
      resourceType,
      resourceId,
      data,
      version,
      expiresAt,
      fileSizeBytes,
      checksum,
      isEncrypted,
      accessCount,
      lastAccessedAt,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalCacheTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.cacheKey == this.cacheKey &&
          other.resourceType == this.resourceType &&
          other.resourceId == this.resourceId &&
          other.data == this.data &&
          other.version == this.version &&
          other.expiresAt == this.expiresAt &&
          other.fileSizeBytes == this.fileSizeBytes &&
          other.checksum == this.checksum &&
          other.isEncrypted == this.isEncrypted &&
          other.accessCount == this.accessCount &&
          other.lastAccessedAt == this.lastAccessedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalCacheTableCompanion extends UpdateCompanion<LocalCacheTableData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> cacheKey;
  final Value<String> resourceType;
  final Value<String> resourceId;
  final Value<String> data;
  final Value<int> version;
  final Value<DateTime?> expiresAt;
  final Value<int> fileSizeBytes;
  final Value<String?> checksum;
  final Value<bool> isEncrypted;
  final Value<int> accessCount;
  final Value<DateTime?> lastAccessedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalCacheTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.cacheKey = const Value.absent(),
    this.resourceType = const Value.absent(),
    this.resourceId = const Value.absent(),
    this.data = const Value.absent(),
    this.version = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.checksum = const Value.absent(),
    this.isEncrypted = const Value.absent(),
    this.accessCount = const Value.absent(),
    this.lastAccessedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalCacheTableCompanion.insert({
    required String id,
    required String userId,
    required String cacheKey,
    required String resourceType,
    required String resourceId,
    required String data,
    this.version = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.checksum = const Value.absent(),
    this.isEncrypted = const Value.absent(),
    this.accessCount = const Value.absent(),
    this.lastAccessedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        cacheKey = Value(cacheKey),
        resourceType = Value(resourceType),
        resourceId = Value(resourceId),
        data = Value(data),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<LocalCacheTableData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? cacheKey,
    Expression<String>? resourceType,
    Expression<String>? resourceId,
    Expression<String>? data,
    Expression<int>? version,
    Expression<DateTime>? expiresAt,
    Expression<int>? fileSizeBytes,
    Expression<String>? checksum,
    Expression<bool>? isEncrypted,
    Expression<int>? accessCount,
    Expression<DateTime>? lastAccessedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (cacheKey != null) 'cache_key': cacheKey,
      if (resourceType != null) 'resource_type': resourceType,
      if (resourceId != null) 'resource_id': resourceId,
      if (data != null) 'data': data,
      if (version != null) 'version': version,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
      if (checksum != null) 'checksum': checksum,
      if (isEncrypted != null) 'is_encrypted': isEncrypted,
      if (accessCount != null) 'access_count': accessCount,
      if (lastAccessedAt != null) 'last_accessed_at': lastAccessedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalCacheTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? cacheKey,
      Value<String>? resourceType,
      Value<String>? resourceId,
      Value<String>? data,
      Value<int>? version,
      Value<DateTime?>? expiresAt,
      Value<int>? fileSizeBytes,
      Value<String?>? checksum,
      Value<bool>? isEncrypted,
      Value<int>? accessCount,
      Value<DateTime?>? lastAccessedAt,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return LocalCacheTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      cacheKey: cacheKey ?? this.cacheKey,
      resourceType: resourceType ?? this.resourceType,
      resourceId: resourceId ?? this.resourceId,
      data: data ?? this.data,
      version: version ?? this.version,
      expiresAt: expiresAt ?? this.expiresAt,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      checksum: checksum ?? this.checksum,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      accessCount: accessCount ?? this.accessCount,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (cacheKey.present) {
      map['cache_key'] = Variable<String>(cacheKey.value);
    }
    if (resourceType.present) {
      map['resource_type'] = Variable<String>(resourceType.value);
    }
    if (resourceId.present) {
      map['resource_id'] = Variable<String>(resourceId.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (fileSizeBytes.present) {
      map['file_size_bytes'] = Variable<int>(fileSizeBytes.value);
    }
    if (checksum.present) {
      map['checksum'] = Variable<String>(checksum.value);
    }
    if (isEncrypted.present) {
      map['is_encrypted'] = Variable<bool>(isEncrypted.value);
    }
    if (accessCount.present) {
      map['access_count'] = Variable<int>(accessCount.value);
    }
    if (lastAccessedAt.present) {
      map['last_accessed_at'] = Variable<DateTime>(lastAccessedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalCacheTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('cacheKey: $cacheKey, ')
          ..write('resourceType: $resourceType, ')
          ..write('resourceId: $resourceId, ')
          ..write('data: $data, ')
          ..write('version: $version, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('checksum: $checksum, ')
          ..write('isEncrypted: $isEncrypted, ')
          ..write('accessCount: $accessCount, ')
          ..write('lastAccessedAt: $lastAccessedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalDraftsTableTable extends LocalDraftsTable
    with TableInfo<$LocalDraftsTableTable, LocalDraftsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalDraftsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _draftTypeMeta =
      const VerificationMeta('draftType');
  @override
  late final GeneratedColumn<String> draftType = GeneratedColumn<String>(
      'draft_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _schoolIdMeta =
      const VerificationMeta('schoolId');
  @override
  late final GeneratedColumn<String> schoolId = GeneratedColumn<String>(
      'school_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _subjectIdMeta =
      const VerificationMeta('subjectId');
  @override
  late final GeneratedColumn<String> subjectId = GeneratedColumn<String>(
      'subject_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _lastEditedAtMeta =
      const VerificationMeta('lastEditedAt');
  @override
  late final GeneratedColumn<DateTime> lastEditedAt = GeneratedColumn<DateTime>(
      'last_edited_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        draftType,
        title,
        content,
        schoolId,
        subjectId,
        isSynced,
        lastEditedAt,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_drafts_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<LocalDraftsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('draft_type')) {
      context.handle(_draftTypeMeta,
          draftType.isAcceptableOrUnknown(data['draft_type']!, _draftTypeMeta));
    } else if (isInserting) {
      context.missing(_draftTypeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('school_id')) {
      context.handle(_schoolIdMeta,
          schoolId.isAcceptableOrUnknown(data['school_id']!, _schoolIdMeta));
    }
    if (data.containsKey('subject_id')) {
      context.handle(_subjectIdMeta,
          subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('last_edited_at')) {
      context.handle(
          _lastEditedAtMeta,
          lastEditedAt.isAcceptableOrUnknown(
              data['last_edited_at']!, _lastEditedAtMeta));
    } else if (isInserting) {
      context.missing(_lastEditedAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalDraftsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalDraftsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      draftType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}draft_type'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title']),
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      schoolId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}school_id']),
      subjectId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subject_id']),
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      lastEditedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_edited_at'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $LocalDraftsTableTable createAlias(String alias) {
    return $LocalDraftsTableTable(attachedDatabase, alias);
  }
}

class LocalDraftsTableData extends DataClass
    implements Insertable<LocalDraftsTableData> {
  /// Unique identifier for the draft.
  final String id;

  /// Owner of the draft.
  final String userId;

  /// Type of draft: exam, assignment, lesson_plan, question, resource.
  final String draftType;

  /// Optional title for the draft.
  final String? title;

  /// JSON-encoded draft content.
  final String content;

  /// School ID this draft belongs to.
  final String? schoolId;

  /// Subject ID this draft belongs to.
  final String? subjectId;

  /// Whether the draft has been synced to the server.
  final bool isSynced;

  /// When the draft was last edited.
  final DateTime lastEditedAt;

  /// When the draft was created.
  final DateTime createdAt;

  /// When the draft was last updated.
  final DateTime updatedAt;
  const LocalDraftsTableData(
      {required this.id,
      required this.userId,
      required this.draftType,
      this.title,
      required this.content,
      this.schoolId,
      this.subjectId,
      required this.isSynced,
      required this.lastEditedAt,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['draft_type'] = Variable<String>(draftType);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || schoolId != null) {
      map['school_id'] = Variable<String>(schoolId);
    }
    if (!nullToAbsent || subjectId != null) {
      map['subject_id'] = Variable<String>(subjectId);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    map['last_edited_at'] = Variable<DateTime>(lastEditedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalDraftsTableCompanion toCompanion(bool nullToAbsent) {
    return LocalDraftsTableCompanion(
      id: Value(id),
      userId: Value(userId),
      draftType: Value(draftType),
      title:
          title == null && nullToAbsent ? const Value.absent() : Value(title),
      content: Value(content),
      schoolId: schoolId == null && nullToAbsent
          ? const Value.absent()
          : Value(schoolId),
      subjectId: subjectId == null && nullToAbsent
          ? const Value.absent()
          : Value(subjectId),
      isSynced: Value(isSynced),
      lastEditedAt: Value(lastEditedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalDraftsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalDraftsTableData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      draftType: serializer.fromJson<String>(json['draftType']),
      title: serializer.fromJson<String?>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      schoolId: serializer.fromJson<String?>(json['schoolId']),
      subjectId: serializer.fromJson<String?>(json['subjectId']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      lastEditedAt: serializer.fromJson<DateTime>(json['lastEditedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'draftType': serializer.toJson<String>(draftType),
      'title': serializer.toJson<String?>(title),
      'content': serializer.toJson<String>(content),
      'schoolId': serializer.toJson<String?>(schoolId),
      'subjectId': serializer.toJson<String?>(subjectId),
      'isSynced': serializer.toJson<bool>(isSynced),
      'lastEditedAt': serializer.toJson<DateTime>(lastEditedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalDraftsTableData copyWith(
          {String? id,
          String? userId,
          String? draftType,
          Value<String?> title = const Value.absent(),
          String? content,
          Value<String?> schoolId = const Value.absent(),
          Value<String?> subjectId = const Value.absent(),
          bool? isSynced,
          DateTime? lastEditedAt,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      LocalDraftsTableData(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        draftType: draftType ?? this.draftType,
        title: title.present ? title.value : this.title,
        content: content ?? this.content,
        schoolId: schoolId.present ? schoolId.value : this.schoolId,
        subjectId: subjectId.present ? subjectId.value : this.subjectId,
        isSynced: isSynced ?? this.isSynced,
        lastEditedAt: lastEditedAt ?? this.lastEditedAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  LocalDraftsTableData copyWithCompanion(LocalDraftsTableCompanion data) {
    return LocalDraftsTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      draftType: data.draftType.present ? data.draftType.value : this.draftType,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      schoolId: data.schoolId.present ? data.schoolId.value : this.schoolId,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      lastEditedAt: data.lastEditedAt.present
          ? data.lastEditedAt.value
          : this.lastEditedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalDraftsTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('draftType: $draftType, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('schoolId: $schoolId, ')
          ..write('subjectId: $subjectId, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastEditedAt: $lastEditedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, draftType, title, content,
      schoolId, subjectId, isSynced, lastEditedAt, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalDraftsTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.draftType == this.draftType &&
          other.title == this.title &&
          other.content == this.content &&
          other.schoolId == this.schoolId &&
          other.subjectId == this.subjectId &&
          other.isSynced == this.isSynced &&
          other.lastEditedAt == this.lastEditedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalDraftsTableCompanion extends UpdateCompanion<LocalDraftsTableData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> draftType;
  final Value<String?> title;
  final Value<String> content;
  final Value<String?> schoolId;
  final Value<String?> subjectId;
  final Value<bool> isSynced;
  final Value<DateTime> lastEditedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalDraftsTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.draftType = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.schoolId = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastEditedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalDraftsTableCompanion.insert({
    required String id,
    required String userId,
    required String draftType,
    this.title = const Value.absent(),
    required String content,
    this.schoolId = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.isSynced = const Value.absent(),
    required DateTime lastEditedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        draftType = Value(draftType),
        content = Value(content),
        lastEditedAt = Value(lastEditedAt),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<LocalDraftsTableData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? draftType,
    Expression<String>? title,
    Expression<String>? content,
    Expression<String>? schoolId,
    Expression<String>? subjectId,
    Expression<bool>? isSynced,
    Expression<DateTime>? lastEditedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (draftType != null) 'draft_type': draftType,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (schoolId != null) 'school_id': schoolId,
      if (subjectId != null) 'subject_id': subjectId,
      if (isSynced != null) 'is_synced': isSynced,
      if (lastEditedAt != null) 'last_edited_at': lastEditedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalDraftsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? draftType,
      Value<String?>? title,
      Value<String>? content,
      Value<String?>? schoolId,
      Value<String?>? subjectId,
      Value<bool>? isSynced,
      Value<DateTime>? lastEditedAt,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return LocalDraftsTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      draftType: draftType ?? this.draftType,
      title: title ?? this.title,
      content: content ?? this.content,
      schoolId: schoolId ?? this.schoolId,
      subjectId: subjectId ?? this.subjectId,
      isSynced: isSynced ?? this.isSynced,
      lastEditedAt: lastEditedAt ?? this.lastEditedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (draftType.present) {
      map['draft_type'] = Variable<String>(draftType.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (schoolId.present) {
      map['school_id'] = Variable<String>(schoolId.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<String>(subjectId.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (lastEditedAt.present) {
      map['last_edited_at'] = Variable<DateTime>(lastEditedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalDraftsTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('draftType: $draftType, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('schoolId: $schoolId, ')
          ..write('subjectId: $subjectId, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastEditedAt: $lastEditedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalUserDataTableTable extends LocalUserDataTable
    with TableInfo<$LocalUserDataTableTable, LocalUserDataTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalUserDataTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _profileDataMeta =
      const VerificationMeta('profileData');
  @override
  late final GeneratedColumn<String> profileData = GeneratedColumn<String>(
      'profile_data', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _preferencesMeta =
      const VerificationMeta('preferences');
  @override
  late final GeneratedColumn<String> preferences = GeneratedColumn<String>(
      'preferences', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _schoolIdMeta =
      const VerificationMeta('schoolId');
  @override
  late final GeneratedColumn<String> schoolId = GeneratedColumn<String>(
      'school_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastSyncedAtMeta =
      const VerificationMeta('lastSyncedAt');
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
      'last_synced_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        profileData,
        preferences,
        role,
        schoolId,
        lastSyncedAt,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_user_data_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<LocalUserDataTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('profile_data')) {
      context.handle(
          _profileDataMeta,
          profileData.isAcceptableOrUnknown(
              data['profile_data']!, _profileDataMeta));
    } else if (isInserting) {
      context.missing(_profileDataMeta);
    }
    if (data.containsKey('preferences')) {
      context.handle(
          _preferencesMeta,
          preferences.isAcceptableOrUnknown(
              data['preferences']!, _preferencesMeta));
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('school_id')) {
      context.handle(_schoolIdMeta,
          schoolId.isAcceptableOrUnknown(data['school_id']!, _schoolIdMeta));
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
          _lastSyncedAtMeta,
          lastSyncedAt.isAcceptableOrUnknown(
              data['last_synced_at']!, _lastSyncedAtMeta));
    } else if (isInserting) {
      context.missing(_lastSyncedAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalUserDataTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalUserDataTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      profileData: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}profile_data'])!,
      preferences: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}preferences']),
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      schoolId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}school_id']),
      lastSyncedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_synced_at'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $LocalUserDataTableTable createAlias(String alias) {
    return $LocalUserDataTableTable(attachedDatabase, alias);
  }
}

class LocalUserDataTableData extends DataClass
    implements Insertable<LocalUserDataTableData> {
  /// Unique identifier for the user data entry.
  final String id;

  /// User ID this data belongs to.
  final String userId;

  /// JSON-encoded profile data.
  final String profileData;

  /// JSON-encoded user preferences (null if not set).
  final String? preferences;

  /// User role (admin, teacher, student, parent, super_admin).
  final String role;

  /// School ID the user belongs to.
  final String? schoolId;

  /// When the profile was last synced with the server.
  final DateTime lastSyncedAt;

  /// When the entry was created.
  final DateTime createdAt;

  /// When the entry was last updated.
  final DateTime updatedAt;
  const LocalUserDataTableData(
      {required this.id,
      required this.userId,
      required this.profileData,
      this.preferences,
      required this.role,
      this.schoolId,
      required this.lastSyncedAt,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['profile_data'] = Variable<String>(profileData);
    if (!nullToAbsent || preferences != null) {
      map['preferences'] = Variable<String>(preferences);
    }
    map['role'] = Variable<String>(role);
    if (!nullToAbsent || schoolId != null) {
      map['school_id'] = Variable<String>(schoolId);
    }
    map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalUserDataTableCompanion toCompanion(bool nullToAbsent) {
    return LocalUserDataTableCompanion(
      id: Value(id),
      userId: Value(userId),
      profileData: Value(profileData),
      preferences: preferences == null && nullToAbsent
          ? const Value.absent()
          : Value(preferences),
      role: Value(role),
      schoolId: schoolId == null && nullToAbsent
          ? const Value.absent()
          : Value(schoolId),
      lastSyncedAt: Value(lastSyncedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalUserDataTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalUserDataTableData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      profileData: serializer.fromJson<String>(json['profileData']),
      preferences: serializer.fromJson<String?>(json['preferences']),
      role: serializer.fromJson<String>(json['role']),
      schoolId: serializer.fromJson<String?>(json['schoolId']),
      lastSyncedAt: serializer.fromJson<DateTime>(json['lastSyncedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'profileData': serializer.toJson<String>(profileData),
      'preferences': serializer.toJson<String?>(preferences),
      'role': serializer.toJson<String>(role),
      'schoolId': serializer.toJson<String?>(schoolId),
      'lastSyncedAt': serializer.toJson<DateTime>(lastSyncedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalUserDataTableData copyWith(
          {String? id,
          String? userId,
          String? profileData,
          Value<String?> preferences = const Value.absent(),
          String? role,
          Value<String?> schoolId = const Value.absent(),
          DateTime? lastSyncedAt,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      LocalUserDataTableData(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        profileData: profileData ?? this.profileData,
        preferences: preferences.present ? preferences.value : this.preferences,
        role: role ?? this.role,
        schoolId: schoolId.present ? schoolId.value : this.schoolId,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  LocalUserDataTableData copyWithCompanion(LocalUserDataTableCompanion data) {
    return LocalUserDataTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      profileData:
          data.profileData.present ? data.profileData.value : this.profileData,
      preferences:
          data.preferences.present ? data.preferences.value : this.preferences,
      role: data.role.present ? data.role.value : this.role,
      schoolId: data.schoolId.present ? data.schoolId.value : this.schoolId,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalUserDataTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('profileData: $profileData, ')
          ..write('preferences: $preferences, ')
          ..write('role: $role, ')
          ..write('schoolId: $schoolId, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, profileData, preferences, role,
      schoolId, lastSyncedAt, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalUserDataTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.profileData == this.profileData &&
          other.preferences == this.preferences &&
          other.role == this.role &&
          other.schoolId == this.schoolId &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalUserDataTableCompanion
    extends UpdateCompanion<LocalUserDataTableData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> profileData;
  final Value<String?> preferences;
  final Value<String> role;
  final Value<String?> schoolId;
  final Value<DateTime> lastSyncedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalUserDataTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.profileData = const Value.absent(),
    this.preferences = const Value.absent(),
    this.role = const Value.absent(),
    this.schoolId = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalUserDataTableCompanion.insert({
    required String id,
    required String userId,
    required String profileData,
    this.preferences = const Value.absent(),
    required String role,
    this.schoolId = const Value.absent(),
    required DateTime lastSyncedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        profileData = Value(profileData),
        role = Value(role),
        lastSyncedAt = Value(lastSyncedAt),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<LocalUserDataTableData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? profileData,
    Expression<String>? preferences,
    Expression<String>? role,
    Expression<String>? schoolId,
    Expression<DateTime>? lastSyncedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (profileData != null) 'profile_data': profileData,
      if (preferences != null) 'preferences': preferences,
      if (role != null) 'role': role,
      if (schoolId != null) 'school_id': schoolId,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalUserDataTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? profileData,
      Value<String?>? preferences,
      Value<String>? role,
      Value<String?>? schoolId,
      Value<DateTime>? lastSyncedAt,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return LocalUserDataTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      profileData: profileData ?? this.profileData,
      preferences: preferences ?? this.preferences,
      role: role ?? this.role,
      schoolId: schoolId ?? this.schoolId,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (profileData.present) {
      map['profile_data'] = Variable<String>(profileData.value);
    }
    if (preferences.present) {
      map['preferences'] = Variable<String>(preferences.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (schoolId.present) {
      map['school_id'] = Variable<String>(schoolId.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalUserDataTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('profileData: $profileData, ')
          ..write('preferences: $preferences, ')
          ..write('role: $role, ')
          ..write('schoolId: $schoolId, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalQuestionBankTableTable extends LocalQuestionBankTable
    with TableInfo<$LocalQuestionBankTableTable, LocalQuestionBankTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalQuestionBankTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _questionDataMeta =
      const VerificationMeta('questionData');
  @override
  late final GeneratedColumn<String> questionData = GeneratedColumn<String>(
      'question_data', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subjectIdMeta =
      const VerificationMeta('subjectId');
  @override
  late final GeneratedColumn<String> subjectId = GeneratedColumn<String>(
      'subject_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _classLevelMeta =
      const VerificationMeta('classLevel');
  @override
  late final GeneratedColumn<String> classLevel = GeneratedColumn<String>(
      'class_level', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _schoolIdMeta =
      const VerificationMeta('schoolId');
  @override
  late final GeneratedColumn<String> schoolId = GeneratedColumn<String>(
      'school_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _lastModifiedAtMeta =
      const VerificationMeta('lastModifiedAt');
  @override
  late final GeneratedColumn<DateTime> lastModifiedAt =
      GeneratedColumn<DateTime>('last_modified_at', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        questionData,
        subjectId,
        classLevel,
        schoolId,
        isSynced,
        lastModifiedAt,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_question_bank_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<LocalQuestionBankTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('question_data')) {
      context.handle(
          _questionDataMeta,
          questionData.isAcceptableOrUnknown(
              data['question_data']!, _questionDataMeta));
    } else if (isInserting) {
      context.missing(_questionDataMeta);
    }
    if (data.containsKey('subject_id')) {
      context.handle(_subjectIdMeta,
          subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta));
    } else if (isInserting) {
      context.missing(_subjectIdMeta);
    }
    if (data.containsKey('class_level')) {
      context.handle(
          _classLevelMeta,
          classLevel.isAcceptableOrUnknown(
              data['class_level']!, _classLevelMeta));
    } else if (isInserting) {
      context.missing(_classLevelMeta);
    }
    if (data.containsKey('school_id')) {
      context.handle(_schoolIdMeta,
          schoolId.isAcceptableOrUnknown(data['school_id']!, _schoolIdMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('last_modified_at')) {
      context.handle(
          _lastModifiedAtMeta,
          lastModifiedAt.isAcceptableOrUnknown(
              data['last_modified_at']!, _lastModifiedAtMeta));
    } else if (isInserting) {
      context.missing(_lastModifiedAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalQuestionBankTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalQuestionBankTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      questionData: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}question_data'])!,
      subjectId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subject_id'])!,
      classLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}class_level'])!,
      schoolId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}school_id']),
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      lastModifiedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_modified_at'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $LocalQuestionBankTableTable createAlias(String alias) {
    return $LocalQuestionBankTableTable(attachedDatabase, alias);
  }
}

class LocalQuestionBankTableData extends DataClass
    implements Insertable<LocalQuestionBankTableData> {
  /// Unique identifier for the cached question.
  final String id;

  /// JSON-encoded question data.
  final String questionData;

  /// Subject ID this question belongs to.
  final String subjectId;

  /// Class level (e.g. `JSS1`, `SSS2`).
  final String classLevel;

  /// School ID (null for global marketplace questions).
  final String? schoolId;

  /// Whether the question has been synced to the server.
  final bool isSynced;

  /// When the question was last modified.
  final DateTime lastModifiedAt;

  /// When the entry was created.
  final DateTime createdAt;
  const LocalQuestionBankTableData(
      {required this.id,
      required this.questionData,
      required this.subjectId,
      required this.classLevel,
      this.schoolId,
      required this.isSynced,
      required this.lastModifiedAt,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['question_data'] = Variable<String>(questionData);
    map['subject_id'] = Variable<String>(subjectId);
    map['class_level'] = Variable<String>(classLevel);
    if (!nullToAbsent || schoolId != null) {
      map['school_id'] = Variable<String>(schoolId);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    map['last_modified_at'] = Variable<DateTime>(lastModifiedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalQuestionBankTableCompanion toCompanion(bool nullToAbsent) {
    return LocalQuestionBankTableCompanion(
      id: Value(id),
      questionData: Value(questionData),
      subjectId: Value(subjectId),
      classLevel: Value(classLevel),
      schoolId: schoolId == null && nullToAbsent
          ? const Value.absent()
          : Value(schoolId),
      isSynced: Value(isSynced),
      lastModifiedAt: Value(lastModifiedAt),
      createdAt: Value(createdAt),
    );
  }

  factory LocalQuestionBankTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalQuestionBankTableData(
      id: serializer.fromJson<String>(json['id']),
      questionData: serializer.fromJson<String>(json['questionData']),
      subjectId: serializer.fromJson<String>(json['subjectId']),
      classLevel: serializer.fromJson<String>(json['classLevel']),
      schoolId: serializer.fromJson<String?>(json['schoolId']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      lastModifiedAt: serializer.fromJson<DateTime>(json['lastModifiedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'questionData': serializer.toJson<String>(questionData),
      'subjectId': serializer.toJson<String>(subjectId),
      'classLevel': serializer.toJson<String>(classLevel),
      'schoolId': serializer.toJson<String?>(schoolId),
      'isSynced': serializer.toJson<bool>(isSynced),
      'lastModifiedAt': serializer.toJson<DateTime>(lastModifiedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalQuestionBankTableData copyWith(
          {String? id,
          String? questionData,
          String? subjectId,
          String? classLevel,
          Value<String?> schoolId = const Value.absent(),
          bool? isSynced,
          DateTime? lastModifiedAt,
          DateTime? createdAt}) =>
      LocalQuestionBankTableData(
        id: id ?? this.id,
        questionData: questionData ?? this.questionData,
        subjectId: subjectId ?? this.subjectId,
        classLevel: classLevel ?? this.classLevel,
        schoolId: schoolId.present ? schoolId.value : this.schoolId,
        isSynced: isSynced ?? this.isSynced,
        lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
        createdAt: createdAt ?? this.createdAt,
      );
  LocalQuestionBankTableData copyWithCompanion(
      LocalQuestionBankTableCompanion data) {
    return LocalQuestionBankTableData(
      id: data.id.present ? data.id.value : this.id,
      questionData: data.questionData.present
          ? data.questionData.value
          : this.questionData,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      classLevel:
          data.classLevel.present ? data.classLevel.value : this.classLevel,
      schoolId: data.schoolId.present ? data.schoolId.value : this.schoolId,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      lastModifiedAt: data.lastModifiedAt.present
          ? data.lastModifiedAt.value
          : this.lastModifiedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalQuestionBankTableData(')
          ..write('id: $id, ')
          ..write('questionData: $questionData, ')
          ..write('subjectId: $subjectId, ')
          ..write('classLevel: $classLevel, ')
          ..write('schoolId: $schoolId, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastModifiedAt: $lastModifiedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, questionData, subjectId, classLevel,
      schoolId, isSynced, lastModifiedAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalQuestionBankTableData &&
          other.id == this.id &&
          other.questionData == this.questionData &&
          other.subjectId == this.subjectId &&
          other.classLevel == this.classLevel &&
          other.schoolId == this.schoolId &&
          other.isSynced == this.isSynced &&
          other.lastModifiedAt == this.lastModifiedAt &&
          other.createdAt == this.createdAt);
}

class LocalQuestionBankTableCompanion
    extends UpdateCompanion<LocalQuestionBankTableData> {
  final Value<String> id;
  final Value<String> questionData;
  final Value<String> subjectId;
  final Value<String> classLevel;
  final Value<String?> schoolId;
  final Value<bool> isSynced;
  final Value<DateTime> lastModifiedAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LocalQuestionBankTableCompanion({
    this.id = const Value.absent(),
    this.questionData = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.classLevel = const Value.absent(),
    this.schoolId = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastModifiedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalQuestionBankTableCompanion.insert({
    required String id,
    required String questionData,
    required String subjectId,
    required String classLevel,
    this.schoolId = const Value.absent(),
    this.isSynced = const Value.absent(),
    required DateTime lastModifiedAt,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        questionData = Value(questionData),
        subjectId = Value(subjectId),
        classLevel = Value(classLevel),
        lastModifiedAt = Value(lastModifiedAt),
        createdAt = Value(createdAt);
  static Insertable<LocalQuestionBankTableData> custom({
    Expression<String>? id,
    Expression<String>? questionData,
    Expression<String>? subjectId,
    Expression<String>? classLevel,
    Expression<String>? schoolId,
    Expression<bool>? isSynced,
    Expression<DateTime>? lastModifiedAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (questionData != null) 'question_data': questionData,
      if (subjectId != null) 'subject_id': subjectId,
      if (classLevel != null) 'class_level': classLevel,
      if (schoolId != null) 'school_id': schoolId,
      if (isSynced != null) 'is_synced': isSynced,
      if (lastModifiedAt != null) 'last_modified_at': lastModifiedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalQuestionBankTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? questionData,
      Value<String>? subjectId,
      Value<String>? classLevel,
      Value<String?>? schoolId,
      Value<bool>? isSynced,
      Value<DateTime>? lastModifiedAt,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return LocalQuestionBankTableCompanion(
      id: id ?? this.id,
      questionData: questionData ?? this.questionData,
      subjectId: subjectId ?? this.subjectId,
      classLevel: classLevel ?? this.classLevel,
      schoolId: schoolId ?? this.schoolId,
      isSynced: isSynced ?? this.isSynced,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (questionData.present) {
      map['question_data'] = Variable<String>(questionData.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<String>(subjectId.value);
    }
    if (classLevel.present) {
      map['class_level'] = Variable<String>(classLevel.value);
    }
    if (schoolId.present) {
      map['school_id'] = Variable<String>(schoolId.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (lastModifiedAt.present) {
      map['last_modified_at'] = Variable<DateTime>(lastModifiedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalQuestionBankTableCompanion(')
          ..write('id: $id, ')
          ..write('questionData: $questionData, ')
          ..write('subjectId: $subjectId, ')
          ..write('classLevel: $classLevel, ')
          ..write('schoolId: $schoolId, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastModifiedAt: $lastModifiedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalResourcesTableTable extends LocalResourcesTable
    with TableInfo<$LocalResourcesTableTable, LocalResourcesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalResourcesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _resourceTypeMeta =
      const VerificationMeta('resourceType');
  @override
  late final GeneratedColumn<String> resourceType = GeneratedColumn<String>(
      'resource_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _resourceIdMeta =
      const VerificationMeta('resourceId');
  @override
  late final GeneratedColumn<String> resourceId = GeneratedColumn<String>(
      'resource_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _filePathMeta =
      const VerificationMeta('filePath');
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
      'file_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fileSizeBytesMeta =
      const VerificationMeta('fileSizeBytes');
  @override
  late final GeneratedColumn<int> fileSizeBytes = GeneratedColumn<int>(
      'file_size_bytes', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _mimeTypeMeta =
      const VerificationMeta('mimeType');
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
      'mime_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _checksumMeta =
      const VerificationMeta('checksum');
  @override
  late final GeneratedColumn<String> checksum = GeneratedColumn<String>(
      'checksum', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _licenseExpiresAtMeta =
      const VerificationMeta('licenseExpiresAt');
  @override
  late final GeneratedColumn<DateTime> licenseExpiresAt =
      GeneratedColumn<DateTime>('license_expires_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _isAvailableMeta =
      const VerificationMeta('isAvailable');
  @override
  late final GeneratedColumn<bool> isAvailable = GeneratedColumn<bool>(
      'is_available', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_available" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _accessCountMeta =
      const VerificationMeta('accessCount');
  @override
  late final GeneratedColumn<int> accessCount = GeneratedColumn<int>(
      'access_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastAccessedAtMeta =
      const VerificationMeta('lastAccessedAt');
  @override
  late final GeneratedColumn<DateTime> lastAccessedAt =
      GeneratedColumn<DateTime>('last_accessed_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        resourceType,
        resourceId,
        title,
        filePath,
        fileSizeBytes,
        mimeType,
        checksum,
        licenseExpiresAt,
        isAvailable,
        accessCount,
        lastAccessedAt,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_resources_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<LocalResourcesTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('resource_type')) {
      context.handle(
          _resourceTypeMeta,
          resourceType.isAcceptableOrUnknown(
              data['resource_type']!, _resourceTypeMeta));
    } else if (isInserting) {
      context.missing(_resourceTypeMeta);
    }
    if (data.containsKey('resource_id')) {
      context.handle(
          _resourceIdMeta,
          resourceId.isAcceptableOrUnknown(
              data['resource_id']!, _resourceIdMeta));
    } else if (isInserting) {
      context.missing(_resourceIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(_filePathMeta,
          filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta));
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('file_size_bytes')) {
      context.handle(
          _fileSizeBytesMeta,
          fileSizeBytes.isAcceptableOrUnknown(
              data['file_size_bytes']!, _fileSizeBytesMeta));
    } else if (isInserting) {
      context.missing(_fileSizeBytesMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(_mimeTypeMeta,
          mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta));
    }
    if (data.containsKey('checksum')) {
      context.handle(_checksumMeta,
          checksum.isAcceptableOrUnknown(data['checksum']!, _checksumMeta));
    }
    if (data.containsKey('license_expires_at')) {
      context.handle(
          _licenseExpiresAtMeta,
          licenseExpiresAt.isAcceptableOrUnknown(
              data['license_expires_at']!, _licenseExpiresAtMeta));
    }
    if (data.containsKey('is_available')) {
      context.handle(
          _isAvailableMeta,
          isAvailable.isAcceptableOrUnknown(
              data['is_available']!, _isAvailableMeta));
    }
    if (data.containsKey('access_count')) {
      context.handle(
          _accessCountMeta,
          accessCount.isAcceptableOrUnknown(
              data['access_count']!, _accessCountMeta));
    }
    if (data.containsKey('last_accessed_at')) {
      context.handle(
          _lastAccessedAtMeta,
          lastAccessedAt.isAcceptableOrUnknown(
              data['last_accessed_at']!, _lastAccessedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalResourcesTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalResourcesTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      resourceType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}resource_type'])!,
      resourceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}resource_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      filePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_path'])!,
      fileSizeBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}file_size_bytes'])!,
      mimeType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mime_type']),
      checksum: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}checksum']),
      licenseExpiresAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}license_expires_at']),
      isAvailable: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_available'])!,
      accessCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}access_count'])!,
      lastAccessedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_accessed_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $LocalResourcesTableTable createAlias(String alias) {
    return $LocalResourcesTableTable(attachedDatabase, alias);
  }
}

class LocalResourcesTableData extends DataClass
    implements Insertable<LocalResourcesTableData> {
  /// Unique identifier for the cached resource.
  final String id;

  /// Owner of the cached resource.
  final String userId;

  /// Resource type (e.g. `pdf`, `video`, `document`).
  final String resourceType;

  /// Remote resource identifier.
  final String resourceId;

  /// Human-readable title.
  final String title;

  /// Local file path where the resource is stored.
  final String filePath;

  /// File size in bytes.
  final int fileSizeBytes;

  /// MIME type of the resource.
  final String? mimeType;

  /// Checksum for integrity verification.
  final String? checksum;

  /// When the resource license expires (null = no expiry).
  final DateTime? licenseExpiresAt;

  /// Whether the resource file is currently available on disk.
  final bool isAvailable;

  /// Number of times the resource has been accessed.
  final int accessCount;

  /// When the resource was last accessed.
  final DateTime? lastAccessedAt;

  /// When the entry was created.
  final DateTime createdAt;

  /// When the entry was last updated.
  final DateTime updatedAt;
  const LocalResourcesTableData(
      {required this.id,
      required this.userId,
      required this.resourceType,
      required this.resourceId,
      required this.title,
      required this.filePath,
      required this.fileSizeBytes,
      this.mimeType,
      this.checksum,
      this.licenseExpiresAt,
      required this.isAvailable,
      required this.accessCount,
      this.lastAccessedAt,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['resource_type'] = Variable<String>(resourceType);
    map['resource_id'] = Variable<String>(resourceId);
    map['title'] = Variable<String>(title);
    map['file_path'] = Variable<String>(filePath);
    map['file_size_bytes'] = Variable<int>(fileSizeBytes);
    if (!nullToAbsent || mimeType != null) {
      map['mime_type'] = Variable<String>(mimeType);
    }
    if (!nullToAbsent || checksum != null) {
      map['checksum'] = Variable<String>(checksum);
    }
    if (!nullToAbsent || licenseExpiresAt != null) {
      map['license_expires_at'] = Variable<DateTime>(licenseExpiresAt);
    }
    map['is_available'] = Variable<bool>(isAvailable);
    map['access_count'] = Variable<int>(accessCount);
    if (!nullToAbsent || lastAccessedAt != null) {
      map['last_accessed_at'] = Variable<DateTime>(lastAccessedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalResourcesTableCompanion toCompanion(bool nullToAbsent) {
    return LocalResourcesTableCompanion(
      id: Value(id),
      userId: Value(userId),
      resourceType: Value(resourceType),
      resourceId: Value(resourceId),
      title: Value(title),
      filePath: Value(filePath),
      fileSizeBytes: Value(fileSizeBytes),
      mimeType: mimeType == null && nullToAbsent
          ? const Value.absent()
          : Value(mimeType),
      checksum: checksum == null && nullToAbsent
          ? const Value.absent()
          : Value(checksum),
      licenseExpiresAt: licenseExpiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(licenseExpiresAt),
      isAvailable: Value(isAvailable),
      accessCount: Value(accessCount),
      lastAccessedAt: lastAccessedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAccessedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalResourcesTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalResourcesTableData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      resourceType: serializer.fromJson<String>(json['resourceType']),
      resourceId: serializer.fromJson<String>(json['resourceId']),
      title: serializer.fromJson<String>(json['title']),
      filePath: serializer.fromJson<String>(json['filePath']),
      fileSizeBytes: serializer.fromJson<int>(json['fileSizeBytes']),
      mimeType: serializer.fromJson<String?>(json['mimeType']),
      checksum: serializer.fromJson<String?>(json['checksum']),
      licenseExpiresAt:
          serializer.fromJson<DateTime?>(json['licenseExpiresAt']),
      isAvailable: serializer.fromJson<bool>(json['isAvailable']),
      accessCount: serializer.fromJson<int>(json['accessCount']),
      lastAccessedAt: serializer.fromJson<DateTime?>(json['lastAccessedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'resourceType': serializer.toJson<String>(resourceType),
      'resourceId': serializer.toJson<String>(resourceId),
      'title': serializer.toJson<String>(title),
      'filePath': serializer.toJson<String>(filePath),
      'fileSizeBytes': serializer.toJson<int>(fileSizeBytes),
      'mimeType': serializer.toJson<String?>(mimeType),
      'checksum': serializer.toJson<String?>(checksum),
      'licenseExpiresAt': serializer.toJson<DateTime?>(licenseExpiresAt),
      'isAvailable': serializer.toJson<bool>(isAvailable),
      'accessCount': serializer.toJson<int>(accessCount),
      'lastAccessedAt': serializer.toJson<DateTime?>(lastAccessedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalResourcesTableData copyWith(
          {String? id,
          String? userId,
          String? resourceType,
          String? resourceId,
          String? title,
          String? filePath,
          int? fileSizeBytes,
          Value<String?> mimeType = const Value.absent(),
          Value<String?> checksum = const Value.absent(),
          Value<DateTime?> licenseExpiresAt = const Value.absent(),
          bool? isAvailable,
          int? accessCount,
          Value<DateTime?> lastAccessedAt = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      LocalResourcesTableData(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        resourceType: resourceType ?? this.resourceType,
        resourceId: resourceId ?? this.resourceId,
        title: title ?? this.title,
        filePath: filePath ?? this.filePath,
        fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
        mimeType: mimeType.present ? mimeType.value : this.mimeType,
        checksum: checksum.present ? checksum.value : this.checksum,
        licenseExpiresAt: licenseExpiresAt.present
            ? licenseExpiresAt.value
            : this.licenseExpiresAt,
        isAvailable: isAvailable ?? this.isAvailable,
        accessCount: accessCount ?? this.accessCount,
        lastAccessedAt:
            lastAccessedAt.present ? lastAccessedAt.value : this.lastAccessedAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  LocalResourcesTableData copyWithCompanion(LocalResourcesTableCompanion data) {
    return LocalResourcesTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      resourceType: data.resourceType.present
          ? data.resourceType.value
          : this.resourceType,
      resourceId:
          data.resourceId.present ? data.resourceId.value : this.resourceId,
      title: data.title.present ? data.title.value : this.title,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      fileSizeBytes: data.fileSizeBytes.present
          ? data.fileSizeBytes.value
          : this.fileSizeBytes,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      checksum: data.checksum.present ? data.checksum.value : this.checksum,
      licenseExpiresAt: data.licenseExpiresAt.present
          ? data.licenseExpiresAt.value
          : this.licenseExpiresAt,
      isAvailable:
          data.isAvailable.present ? data.isAvailable.value : this.isAvailable,
      accessCount:
          data.accessCount.present ? data.accessCount.value : this.accessCount,
      lastAccessedAt: data.lastAccessedAt.present
          ? data.lastAccessedAt.value
          : this.lastAccessedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalResourcesTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('resourceType: $resourceType, ')
          ..write('resourceId: $resourceId, ')
          ..write('title: $title, ')
          ..write('filePath: $filePath, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('mimeType: $mimeType, ')
          ..write('checksum: $checksum, ')
          ..write('licenseExpiresAt: $licenseExpiresAt, ')
          ..write('isAvailable: $isAvailable, ')
          ..write('accessCount: $accessCount, ')
          ..write('lastAccessedAt: $lastAccessedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      resourceType,
      resourceId,
      title,
      filePath,
      fileSizeBytes,
      mimeType,
      checksum,
      licenseExpiresAt,
      isAvailable,
      accessCount,
      lastAccessedAt,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalResourcesTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.resourceType == this.resourceType &&
          other.resourceId == this.resourceId &&
          other.title == this.title &&
          other.filePath == this.filePath &&
          other.fileSizeBytes == this.fileSizeBytes &&
          other.mimeType == this.mimeType &&
          other.checksum == this.checksum &&
          other.licenseExpiresAt == this.licenseExpiresAt &&
          other.isAvailable == this.isAvailable &&
          other.accessCount == this.accessCount &&
          other.lastAccessedAt == this.lastAccessedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalResourcesTableCompanion
    extends UpdateCompanion<LocalResourcesTableData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> resourceType;
  final Value<String> resourceId;
  final Value<String> title;
  final Value<String> filePath;
  final Value<int> fileSizeBytes;
  final Value<String?> mimeType;
  final Value<String?> checksum;
  final Value<DateTime?> licenseExpiresAt;
  final Value<bool> isAvailable;
  final Value<int> accessCount;
  final Value<DateTime?> lastAccessedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalResourcesTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.resourceType = const Value.absent(),
    this.resourceId = const Value.absent(),
    this.title = const Value.absent(),
    this.filePath = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.checksum = const Value.absent(),
    this.licenseExpiresAt = const Value.absent(),
    this.isAvailable = const Value.absent(),
    this.accessCount = const Value.absent(),
    this.lastAccessedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalResourcesTableCompanion.insert({
    required String id,
    required String userId,
    required String resourceType,
    required String resourceId,
    required String title,
    required String filePath,
    required int fileSizeBytes,
    this.mimeType = const Value.absent(),
    this.checksum = const Value.absent(),
    this.licenseExpiresAt = const Value.absent(),
    this.isAvailable = const Value.absent(),
    this.accessCount = const Value.absent(),
    this.lastAccessedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        resourceType = Value(resourceType),
        resourceId = Value(resourceId),
        title = Value(title),
        filePath = Value(filePath),
        fileSizeBytes = Value(fileSizeBytes),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<LocalResourcesTableData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? resourceType,
    Expression<String>? resourceId,
    Expression<String>? title,
    Expression<String>? filePath,
    Expression<int>? fileSizeBytes,
    Expression<String>? mimeType,
    Expression<String>? checksum,
    Expression<DateTime>? licenseExpiresAt,
    Expression<bool>? isAvailable,
    Expression<int>? accessCount,
    Expression<DateTime>? lastAccessedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (resourceType != null) 'resource_type': resourceType,
      if (resourceId != null) 'resource_id': resourceId,
      if (title != null) 'title': title,
      if (filePath != null) 'file_path': filePath,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
      if (mimeType != null) 'mime_type': mimeType,
      if (checksum != null) 'checksum': checksum,
      if (licenseExpiresAt != null) 'license_expires_at': licenseExpiresAt,
      if (isAvailable != null) 'is_available': isAvailable,
      if (accessCount != null) 'access_count': accessCount,
      if (lastAccessedAt != null) 'last_accessed_at': lastAccessedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalResourcesTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? resourceType,
      Value<String>? resourceId,
      Value<String>? title,
      Value<String>? filePath,
      Value<int>? fileSizeBytes,
      Value<String?>? mimeType,
      Value<String?>? checksum,
      Value<DateTime?>? licenseExpiresAt,
      Value<bool>? isAvailable,
      Value<int>? accessCount,
      Value<DateTime?>? lastAccessedAt,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return LocalResourcesTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      resourceType: resourceType ?? this.resourceType,
      resourceId: resourceId ?? this.resourceId,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      mimeType: mimeType ?? this.mimeType,
      checksum: checksum ?? this.checksum,
      licenseExpiresAt: licenseExpiresAt ?? this.licenseExpiresAt,
      isAvailable: isAvailable ?? this.isAvailable,
      accessCount: accessCount ?? this.accessCount,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (resourceType.present) {
      map['resource_type'] = Variable<String>(resourceType.value);
    }
    if (resourceId.present) {
      map['resource_id'] = Variable<String>(resourceId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (fileSizeBytes.present) {
      map['file_size_bytes'] = Variable<int>(fileSizeBytes.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (checksum.present) {
      map['checksum'] = Variable<String>(checksum.value);
    }
    if (licenseExpiresAt.present) {
      map['license_expires_at'] = Variable<DateTime>(licenseExpiresAt.value);
    }
    if (isAvailable.present) {
      map['is_available'] = Variable<bool>(isAvailable.value);
    }
    if (accessCount.present) {
      map['access_count'] = Variable<int>(accessCount.value);
    }
    if (lastAccessedAt.present) {
      map['last_accessed_at'] = Variable<DateTime>(lastAccessedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalResourcesTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('resourceType: $resourceType, ')
          ..write('resourceId: $resourceId, ')
          ..write('title: $title, ')
          ..write('filePath: $filePath, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('mimeType: $mimeType, ')
          ..write('checksum: $checksum, ')
          ..write('licenseExpiresAt: $licenseExpiresAt, ')
          ..write('isAvailable: $isAvailable, ')
          ..write('accessCount: $accessCount, ')
          ..write('lastAccessedAt: $lastAccessedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalAnnouncementsTableTable extends LocalAnnouncementsTable
    with TableInfo<$LocalAnnouncementsTableTable, LocalAnnouncementsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalAnnouncementsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _schoolIdMeta =
      const VerificationMeta('schoolId');
  @override
  late final GeneratedColumn<String> schoolId = GeneratedColumn<String>(
      'school_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _announcementDataMeta =
      const VerificationMeta('announcementData');
  @override
  late final GeneratedColumn<String> announcementData = GeneratedColumn<String>(
      'announcement_data', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
      'is_read', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_read" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _expiresAtMeta =
      const VerificationMeta('expiresAt');
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
      'expires_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, schoolId, announcementData, isRead, createdAt, expiresAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_announcements_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<LocalAnnouncementsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('school_id')) {
      context.handle(_schoolIdMeta,
          schoolId.isAcceptableOrUnknown(data['school_id']!, _schoolIdMeta));
    } else if (isInserting) {
      context.missing(_schoolIdMeta);
    }
    if (data.containsKey('announcement_data')) {
      context.handle(
          _announcementDataMeta,
          announcementData.isAcceptableOrUnknown(
              data['announcement_data']!, _announcementDataMeta));
    } else if (isInserting) {
      context.missing(_announcementDataMeta);
    }
    if (data.containsKey('is_read')) {
      context.handle(_isReadMeta,
          isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(_expiresAtMeta,
          expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalAnnouncementsTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalAnnouncementsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      schoolId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}school_id'])!,
      announcementData: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}announcement_data'])!,
      isRead: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_read'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      expiresAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}expires_at']),
    );
  }

  @override
  $LocalAnnouncementsTableTable createAlias(String alias) {
    return $LocalAnnouncementsTableTable(attachedDatabase, alias);
  }
}

class LocalAnnouncementsTableData extends DataClass
    implements Insertable<LocalAnnouncementsTableData> {
  /// Unique identifier for the cached announcement.
  final String id;

  /// School ID this announcement belongs to.
  final String schoolId;

  /// JSON-encoded announcement data.
  final String announcementData;

  /// Whether the user has read this announcement.
  final bool isRead;

  /// When the announcement was created on the server.
  final DateTime createdAt;

  /// When the announcement expires (null = never expires).
  final DateTime? expiresAt;
  const LocalAnnouncementsTableData(
      {required this.id,
      required this.schoolId,
      required this.announcementData,
      required this.isRead,
      required this.createdAt,
      this.expiresAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['school_id'] = Variable<String>(schoolId);
    map['announcement_data'] = Variable<String>(announcementData);
    map['is_read'] = Variable<bool>(isRead);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<DateTime>(expiresAt);
    }
    return map;
  }

  LocalAnnouncementsTableCompanion toCompanion(bool nullToAbsent) {
    return LocalAnnouncementsTableCompanion(
      id: Value(id),
      schoolId: Value(schoolId),
      announcementData: Value(announcementData),
      isRead: Value(isRead),
      createdAt: Value(createdAt),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
    );
  }

  factory LocalAnnouncementsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalAnnouncementsTableData(
      id: serializer.fromJson<String>(json['id']),
      schoolId: serializer.fromJson<String>(json['schoolId']),
      announcementData: serializer.fromJson<String>(json['announcementData']),
      isRead: serializer.fromJson<bool>(json['isRead']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      expiresAt: serializer.fromJson<DateTime?>(json['expiresAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'schoolId': serializer.toJson<String>(schoolId),
      'announcementData': serializer.toJson<String>(announcementData),
      'isRead': serializer.toJson<bool>(isRead),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'expiresAt': serializer.toJson<DateTime?>(expiresAt),
    };
  }

  LocalAnnouncementsTableData copyWith(
          {String? id,
          String? schoolId,
          String? announcementData,
          bool? isRead,
          DateTime? createdAt,
          Value<DateTime?> expiresAt = const Value.absent()}) =>
      LocalAnnouncementsTableData(
        id: id ?? this.id,
        schoolId: schoolId ?? this.schoolId,
        announcementData: announcementData ?? this.announcementData,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt ?? this.createdAt,
        expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
      );
  LocalAnnouncementsTableData copyWithCompanion(
      LocalAnnouncementsTableCompanion data) {
    return LocalAnnouncementsTableData(
      id: data.id.present ? data.id.value : this.id,
      schoolId: data.schoolId.present ? data.schoolId.value : this.schoolId,
      announcementData: data.announcementData.present
          ? data.announcementData.value
          : this.announcementData,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalAnnouncementsTableData(')
          ..write('id: $id, ')
          ..write('schoolId: $schoolId, ')
          ..write('announcementData: $announcementData, ')
          ..write('isRead: $isRead, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, schoolId, announcementData, isRead, createdAt, expiresAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalAnnouncementsTableData &&
          other.id == this.id &&
          other.schoolId == this.schoolId &&
          other.announcementData == this.announcementData &&
          other.isRead == this.isRead &&
          other.createdAt == this.createdAt &&
          other.expiresAt == this.expiresAt);
}

class LocalAnnouncementsTableCompanion
    extends UpdateCompanion<LocalAnnouncementsTableData> {
  final Value<String> id;
  final Value<String> schoolId;
  final Value<String> announcementData;
  final Value<bool> isRead;
  final Value<DateTime> createdAt;
  final Value<DateTime?> expiresAt;
  final Value<int> rowid;
  const LocalAnnouncementsTableCompanion({
    this.id = const Value.absent(),
    this.schoolId = const Value.absent(),
    this.announcementData = const Value.absent(),
    this.isRead = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalAnnouncementsTableCompanion.insert({
    required String id,
    required String schoolId,
    required String announcementData,
    this.isRead = const Value.absent(),
    required DateTime createdAt,
    this.expiresAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        schoolId = Value(schoolId),
        announcementData = Value(announcementData),
        createdAt = Value(createdAt);
  static Insertable<LocalAnnouncementsTableData> custom({
    Expression<String>? id,
    Expression<String>? schoolId,
    Expression<String>? announcementData,
    Expression<bool>? isRead,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? expiresAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (schoolId != null) 'school_id': schoolId,
      if (announcementData != null) 'announcement_data': announcementData,
      if (isRead != null) 'is_read': isRead,
      if (createdAt != null) 'created_at': createdAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalAnnouncementsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? schoolId,
      Value<String>? announcementData,
      Value<bool>? isRead,
      Value<DateTime>? createdAt,
      Value<DateTime?>? expiresAt,
      Value<int>? rowid}) {
    return LocalAnnouncementsTableCompanion(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      announcementData: announcementData ?? this.announcementData,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (schoolId.present) {
      map['school_id'] = Variable<String>(schoolId.value);
    }
    if (announcementData.present) {
      map['announcement_data'] = Variable<String>(announcementData.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalAnnouncementsTableCompanion(')
          ..write('id: $id, ')
          ..write('schoolId: $schoolId, ')
          ..write('announcementData: $announcementData, ')
          ..write('isRead: $isRead, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalTimetableTableTable extends LocalTimetableTable
    with TableInfo<$LocalTimetableTableTable, LocalTimetableTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalTimetableTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _schoolIdMeta =
      const VerificationMeta('schoolId');
  @override
  late final GeneratedColumn<String> schoolId = GeneratedColumn<String>(
      'school_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _classIdMeta =
      const VerificationMeta('classId');
  @override
  late final GeneratedColumn<String> classId = GeneratedColumn<String>(
      'class_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _timetableDataMeta =
      const VerificationMeta('timetableData');
  @override
  late final GeneratedColumn<String> timetableData = GeneratedColumn<String>(
      'timetable_data', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _weekStartMeta =
      const VerificationMeta('weekStart');
  @override
  late final GeneratedColumn<DateTime> weekStart = GeneratedColumn<DateTime>(
      'week_start', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, schoolId, classId, timetableData, weekStart, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_timetable_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<LocalTimetableTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('school_id')) {
      context.handle(_schoolIdMeta,
          schoolId.isAcceptableOrUnknown(data['school_id']!, _schoolIdMeta));
    } else if (isInserting) {
      context.missing(_schoolIdMeta);
    }
    if (data.containsKey('class_id')) {
      context.handle(_classIdMeta,
          classId.isAcceptableOrUnknown(data['class_id']!, _classIdMeta));
    }
    if (data.containsKey('timetable_data')) {
      context.handle(
          _timetableDataMeta,
          timetableData.isAcceptableOrUnknown(
              data['timetable_data']!, _timetableDataMeta));
    } else if (isInserting) {
      context.missing(_timetableDataMeta);
    }
    if (data.containsKey('week_start')) {
      context.handle(_weekStartMeta,
          weekStart.isAcceptableOrUnknown(data['week_start']!, _weekStartMeta));
    } else if (isInserting) {
      context.missing(_weekStartMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalTimetableTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalTimetableTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      schoolId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}school_id'])!,
      classId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}class_id']),
      timetableData: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}timetable_data'])!,
      weekStart: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}week_start'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $LocalTimetableTableTable createAlias(String alias) {
    return $LocalTimetableTableTable(attachedDatabase, alias);
  }
}

class LocalTimetableTableData extends DataClass
    implements Insertable<LocalTimetableTableData> {
  /// Unique identifier for the cached timetable.
  final String id;

  /// School ID this timetable belongs to.
  final String schoolId;

  /// Class ID (null for teacher / school-wide timetables).
  final String? classId;

  /// JSON-encoded timetable data.
  final String timetableData;

  /// Start of the week this timetable covers.
  final DateTime weekStart;

  /// When the entry was created.
  final DateTime createdAt;

  /// When the entry was last updated.
  final DateTime updatedAt;
  const LocalTimetableTableData(
      {required this.id,
      required this.schoolId,
      this.classId,
      required this.timetableData,
      required this.weekStart,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['school_id'] = Variable<String>(schoolId);
    if (!nullToAbsent || classId != null) {
      map['class_id'] = Variable<String>(classId);
    }
    map['timetable_data'] = Variable<String>(timetableData);
    map['week_start'] = Variable<DateTime>(weekStart);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalTimetableTableCompanion toCompanion(bool nullToAbsent) {
    return LocalTimetableTableCompanion(
      id: Value(id),
      schoolId: Value(schoolId),
      classId: classId == null && nullToAbsent
          ? const Value.absent()
          : Value(classId),
      timetableData: Value(timetableData),
      weekStart: Value(weekStart),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalTimetableTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalTimetableTableData(
      id: serializer.fromJson<String>(json['id']),
      schoolId: serializer.fromJson<String>(json['schoolId']),
      classId: serializer.fromJson<String?>(json['classId']),
      timetableData: serializer.fromJson<String>(json['timetableData']),
      weekStart: serializer.fromJson<DateTime>(json['weekStart']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'schoolId': serializer.toJson<String>(schoolId),
      'classId': serializer.toJson<String?>(classId),
      'timetableData': serializer.toJson<String>(timetableData),
      'weekStart': serializer.toJson<DateTime>(weekStart),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalTimetableTableData copyWith(
          {String? id,
          String? schoolId,
          Value<String?> classId = const Value.absent(),
          String? timetableData,
          DateTime? weekStart,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      LocalTimetableTableData(
        id: id ?? this.id,
        schoolId: schoolId ?? this.schoolId,
        classId: classId.present ? classId.value : this.classId,
        timetableData: timetableData ?? this.timetableData,
        weekStart: weekStart ?? this.weekStart,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  LocalTimetableTableData copyWithCompanion(LocalTimetableTableCompanion data) {
    return LocalTimetableTableData(
      id: data.id.present ? data.id.value : this.id,
      schoolId: data.schoolId.present ? data.schoolId.value : this.schoolId,
      classId: data.classId.present ? data.classId.value : this.classId,
      timetableData: data.timetableData.present
          ? data.timetableData.value
          : this.timetableData,
      weekStart: data.weekStart.present ? data.weekStart.value : this.weekStart,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalTimetableTableData(')
          ..write('id: $id, ')
          ..write('schoolId: $schoolId, ')
          ..write('classId: $classId, ')
          ..write('timetableData: $timetableData, ')
          ..write('weekStart: $weekStart, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, schoolId, classId, timetableData, weekStart, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalTimetableTableData &&
          other.id == this.id &&
          other.schoolId == this.schoolId &&
          other.classId == this.classId &&
          other.timetableData == this.timetableData &&
          other.weekStart == this.weekStart &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalTimetableTableCompanion
    extends UpdateCompanion<LocalTimetableTableData> {
  final Value<String> id;
  final Value<String> schoolId;
  final Value<String?> classId;
  final Value<String> timetableData;
  final Value<DateTime> weekStart;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalTimetableTableCompanion({
    this.id = const Value.absent(),
    this.schoolId = const Value.absent(),
    this.classId = const Value.absent(),
    this.timetableData = const Value.absent(),
    this.weekStart = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalTimetableTableCompanion.insert({
    required String id,
    required String schoolId,
    this.classId = const Value.absent(),
    required String timetableData,
    required DateTime weekStart,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        schoolId = Value(schoolId),
        timetableData = Value(timetableData),
        weekStart = Value(weekStart),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<LocalTimetableTableData> custom({
    Expression<String>? id,
    Expression<String>? schoolId,
    Expression<String>? classId,
    Expression<String>? timetableData,
    Expression<DateTime>? weekStart,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (schoolId != null) 'school_id': schoolId,
      if (classId != null) 'class_id': classId,
      if (timetableData != null) 'timetable_data': timetableData,
      if (weekStart != null) 'week_start': weekStart,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalTimetableTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? schoolId,
      Value<String?>? classId,
      Value<String>? timetableData,
      Value<DateTime>? weekStart,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return LocalTimetableTableCompanion(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      classId: classId ?? this.classId,
      timetableData: timetableData ?? this.timetableData,
      weekStart: weekStart ?? this.weekStart,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (schoolId.present) {
      map['school_id'] = Variable<String>(schoolId.value);
    }
    if (classId.present) {
      map['class_id'] = Variable<String>(classId.value);
    }
    if (timetableData.present) {
      map['timetable_data'] = Variable<String>(timetableData.value);
    }
    if (weekStart.present) {
      map['week_start'] = Variable<DateTime>(weekStart.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalTimetableTableCompanion(')
          ..write('id: $id, ')
          ..write('schoolId: $schoolId, ')
          ..write('classId: $classId, ')
          ..write('timetableData: $timetableData, ')
          ..write('weekStart: $weekStart, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalExamAttemptsTableTable extends LocalExamAttemptsTable
    with TableInfo<$LocalExamAttemptsTableTable, LocalExamAttemptsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalExamAttemptsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _examIdMeta = const VerificationMeta('examId');
  @override
  late final GeneratedColumn<String> examId = GeneratedColumn<String>(
      'exam_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _studentIdMeta =
      const VerificationMeta('studentId');
  @override
  late final GeneratedColumn<String> studentId = GeneratedColumn<String>(
      'student_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _schoolIdMeta =
      const VerificationMeta('schoolId');
  @override
  late final GeneratedColumn<String> schoolId = GeneratedColumn<String>(
      'school_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _attemptDataMeta =
      const VerificationMeta('attemptData');
  @override
  late final GeneratedColumn<String> attemptData = GeneratedColumn<String>(
      'attempt_data', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _answersMeta =
      const VerificationMeta('answers');
  @override
  late final GeneratedColumn<String> answers = GeneratedColumn<String>(
      'answers', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isEncryptedMeta =
      const VerificationMeta('isEncrypted');
  @override
  late final GeneratedColumn<bool> isEncrypted = GeneratedColumn<bool>(
      'is_encrypted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_encrypted" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
      'started_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _timeTakenSecondsMeta =
      const VerificationMeta('timeTakenSeconds');
  @override
  late final GeneratedColumn<int> timeTakenSeconds = GeneratedColumn<int>(
      'time_taken_seconds', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _integrityHashMeta =
      const VerificationMeta('integrityHash');
  @override
  late final GeneratedColumn<String> integrityHash = GeneratedColumn<String>(
      'integrity_hash', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _syncAttemptsMeta =
      const VerificationMeta('syncAttempts');
  @override
  late final GeneratedColumn<int> syncAttempts = GeneratedColumn<int>(
      'sync_attempts', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _validationErrorsMeta =
      const VerificationMeta('validationErrors');
  @override
  late final GeneratedColumn<String> validationErrors = GeneratedColumn<String>(
      'validation_errors', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        examId,
        studentId,
        schoolId,
        attemptData,
        answers,
        isEncrypted,
        startedAt,
        completedAt,
        timeTakenSeconds,
        integrityHash,
        syncStatus,
        syncAttempts,
        syncedAt,
        validationErrors,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_exam_attempts_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<LocalExamAttemptsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('exam_id')) {
      context.handle(_examIdMeta,
          examId.isAcceptableOrUnknown(data['exam_id']!, _examIdMeta));
    } else if (isInserting) {
      context.missing(_examIdMeta);
    }
    if (data.containsKey('student_id')) {
      context.handle(_studentIdMeta,
          studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta));
    } else if (isInserting) {
      context.missing(_studentIdMeta);
    }
    if (data.containsKey('school_id')) {
      context.handle(_schoolIdMeta,
          schoolId.isAcceptableOrUnknown(data['school_id']!, _schoolIdMeta));
    }
    if (data.containsKey('attempt_data')) {
      context.handle(
          _attemptDataMeta,
          attemptData.isAcceptableOrUnknown(
              data['attempt_data']!, _attemptDataMeta));
    } else if (isInserting) {
      context.missing(_attemptDataMeta);
    }
    if (data.containsKey('answers')) {
      context.handle(_answersMeta,
          answers.isAcceptableOrUnknown(data['answers']!, _answersMeta));
    } else if (isInserting) {
      context.missing(_answersMeta);
    }
    if (data.containsKey('is_encrypted')) {
      context.handle(
          _isEncryptedMeta,
          isEncrypted.isAcceptableOrUnknown(
              data['is_encrypted']!, _isEncryptedMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    if (data.containsKey('time_taken_seconds')) {
      context.handle(
          _timeTakenSecondsMeta,
          timeTakenSeconds.isAcceptableOrUnknown(
              data['time_taken_seconds']!, _timeTakenSecondsMeta));
    }
    if (data.containsKey('integrity_hash')) {
      context.handle(
          _integrityHashMeta,
          integrityHash.isAcceptableOrUnknown(
              data['integrity_hash']!, _integrityHashMeta));
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    }
    if (data.containsKey('sync_attempts')) {
      context.handle(
          _syncAttemptsMeta,
          syncAttempts.isAcceptableOrUnknown(
              data['sync_attempts']!, _syncAttemptsMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    if (data.containsKey('validation_errors')) {
      context.handle(
          _validationErrorsMeta,
          validationErrors.isAcceptableOrUnknown(
              data['validation_errors']!, _validationErrorsMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalExamAttemptsTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalExamAttemptsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      examId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}exam_id'])!,
      studentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}student_id'])!,
      schoolId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}school_id']),
      attemptData: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}attempt_data'])!,
      answers: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}answers'])!,
      isEncrypted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_encrypted'])!,
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}started_at'])!,
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at']),
      timeTakenSeconds: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}time_taken_seconds'])!,
      integrityHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}integrity_hash']),
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
      syncAttempts: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sync_attempts'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
      validationErrors: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}validation_errors']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $LocalExamAttemptsTableTable createAlias(String alias) {
    return $LocalExamAttemptsTableTable(attachedDatabase, alias);
  }
}

class LocalExamAttemptsTableData extends DataClass
    implements Insertable<LocalExamAttemptsTableData> {
  /// Unique identifier for the exam attempt.
  final String id;

  /// Exam ID this attempt belongs to.
  final String examId;

  /// Student ID who is taking the exam.
  final String studentId;

  /// School ID (null for marketplace exams).
  final String? schoolId;

  /// JSON-encoded attempt metadata.
  final String attemptData;

  /// JSON-encoded answers.
  /// SECURITY: When isEncrypted is true, this contains AES-encrypted
  /// ciphertext (base64). When false, it contains plaintext JSON (legacy).
  final String answers;

  /// Whether the answers column is encrypted.
  /// All new records are encrypted. Legacy records may be plaintext.
  final bool isEncrypted;

  /// When the attempt was started.
  final DateTime startedAt;

  /// When the attempt was completed (null if in progress).
  final DateTime? completedAt;

  /// Total time taken in seconds.
  final int timeTakenSeconds;

  /// Hash for integrity verification (anti-cheat).
  final String? integrityHash;

  /// Sync status: pending, synced, validated, rejected.
  final String syncStatus;

  /// Number of sync attempts made.
  final int syncAttempts;

  /// When the attempt was successfully synced.
  final DateTime? syncedAt;

  /// JSON-encoded validation errors from the server.
  final String? validationErrors;

  /// When the entry was created.
  final DateTime createdAt;
  const LocalExamAttemptsTableData(
      {required this.id,
      required this.examId,
      required this.studentId,
      this.schoolId,
      required this.attemptData,
      required this.answers,
      required this.isEncrypted,
      required this.startedAt,
      this.completedAt,
      required this.timeTakenSeconds,
      this.integrityHash,
      required this.syncStatus,
      required this.syncAttempts,
      this.syncedAt,
      this.validationErrors,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['exam_id'] = Variable<String>(examId);
    map['student_id'] = Variable<String>(studentId);
    if (!nullToAbsent || schoolId != null) {
      map['school_id'] = Variable<String>(schoolId);
    }
    map['attempt_data'] = Variable<String>(attemptData);
    map['answers'] = Variable<String>(answers);
    map['is_encrypted'] = Variable<bool>(isEncrypted);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['time_taken_seconds'] = Variable<int>(timeTakenSeconds);
    if (!nullToAbsent || integrityHash != null) {
      map['integrity_hash'] = Variable<String>(integrityHash);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['sync_attempts'] = Variable<int>(syncAttempts);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    if (!nullToAbsent || validationErrors != null) {
      map['validation_errors'] = Variable<String>(validationErrors);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalExamAttemptsTableCompanion toCompanion(bool nullToAbsent) {
    return LocalExamAttemptsTableCompanion(
      id: Value(id),
      examId: Value(examId),
      studentId: Value(studentId),
      schoolId: schoolId == null && nullToAbsent
          ? const Value.absent()
          : Value(schoolId),
      attemptData: Value(attemptData),
      answers: Value(answers),
      isEncrypted: Value(isEncrypted),
      startedAt: Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      timeTakenSeconds: Value(timeTakenSeconds),
      integrityHash: integrityHash == null && nullToAbsent
          ? const Value.absent()
          : Value(integrityHash),
      syncStatus: Value(syncStatus),
      syncAttempts: Value(syncAttempts),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      validationErrors: validationErrors == null && nullToAbsent
          ? const Value.absent()
          : Value(validationErrors),
      createdAt: Value(createdAt),
    );
  }

  factory LocalExamAttemptsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalExamAttemptsTableData(
      id: serializer.fromJson<String>(json['id']),
      examId: serializer.fromJson<String>(json['examId']),
      studentId: serializer.fromJson<String>(json['studentId']),
      schoolId: serializer.fromJson<String?>(json['schoolId']),
      attemptData: serializer.fromJson<String>(json['attemptData']),
      answers: serializer.fromJson<String>(json['answers']),
      isEncrypted: serializer.fromJson<bool>(json['isEncrypted']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      timeTakenSeconds: serializer.fromJson<int>(json['timeTakenSeconds']),
      integrityHash: serializer.fromJson<String?>(json['integrityHash']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      syncAttempts: serializer.fromJson<int>(json['syncAttempts']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      validationErrors: serializer.fromJson<String?>(json['validationErrors']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'examId': serializer.toJson<String>(examId),
      'studentId': serializer.toJson<String>(studentId),
      'schoolId': serializer.toJson<String?>(schoolId),
      'attemptData': serializer.toJson<String>(attemptData),
      'answers': serializer.toJson<String>(answers),
      'isEncrypted': serializer.toJson<bool>(isEncrypted),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'timeTakenSeconds': serializer.toJson<int>(timeTakenSeconds),
      'integrityHash': serializer.toJson<String?>(integrityHash),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'syncAttempts': serializer.toJson<int>(syncAttempts),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'validationErrors': serializer.toJson<String?>(validationErrors),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalExamAttemptsTableData copyWith(
          {String? id,
          String? examId,
          String? studentId,
          Value<String?> schoolId = const Value.absent(),
          String? attemptData,
          String? answers,
          bool? isEncrypted,
          DateTime? startedAt,
          Value<DateTime?> completedAt = const Value.absent(),
          int? timeTakenSeconds,
          Value<String?> integrityHash = const Value.absent(),
          String? syncStatus,
          int? syncAttempts,
          Value<DateTime?> syncedAt = const Value.absent(),
          Value<String?> validationErrors = const Value.absent(),
          DateTime? createdAt}) =>
      LocalExamAttemptsTableData(
        id: id ?? this.id,
        examId: examId ?? this.examId,
        studentId: studentId ?? this.studentId,
        schoolId: schoolId.present ? schoolId.value : this.schoolId,
        attemptData: attemptData ?? this.attemptData,
        answers: answers ?? this.answers,
        isEncrypted: isEncrypted ?? this.isEncrypted,
        startedAt: startedAt ?? this.startedAt,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
        timeTakenSeconds: timeTakenSeconds ?? this.timeTakenSeconds,
        integrityHash:
            integrityHash.present ? integrityHash.value : this.integrityHash,
        syncStatus: syncStatus ?? this.syncStatus,
        syncAttempts: syncAttempts ?? this.syncAttempts,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
        validationErrors: validationErrors.present
            ? validationErrors.value
            : this.validationErrors,
        createdAt: createdAt ?? this.createdAt,
      );
  LocalExamAttemptsTableData copyWithCompanion(
      LocalExamAttemptsTableCompanion data) {
    return LocalExamAttemptsTableData(
      id: data.id.present ? data.id.value : this.id,
      examId: data.examId.present ? data.examId.value : this.examId,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      schoolId: data.schoolId.present ? data.schoolId.value : this.schoolId,
      attemptData:
          data.attemptData.present ? data.attemptData.value : this.attemptData,
      answers: data.answers.present ? data.answers.value : this.answers,
      isEncrypted:
          data.isEncrypted.present ? data.isEncrypted.value : this.isEncrypted,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
      timeTakenSeconds: data.timeTakenSeconds.present
          ? data.timeTakenSeconds.value
          : this.timeTakenSeconds,
      integrityHash: data.integrityHash.present
          ? data.integrityHash.value
          : this.integrityHash,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      syncAttempts: data.syncAttempts.present
          ? data.syncAttempts.value
          : this.syncAttempts,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      validationErrors: data.validationErrors.present
          ? data.validationErrors.value
          : this.validationErrors,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalExamAttemptsTableData(')
          ..write('id: $id, ')
          ..write('examId: $examId, ')
          ..write('studentId: $studentId, ')
          ..write('schoolId: $schoolId, ')
          ..write('attemptData: $attemptData, ')
          ..write('answers: $answers, ')
          ..write('isEncrypted: $isEncrypted, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('timeTakenSeconds: $timeTakenSeconds, ')
          ..write('integrityHash: $integrityHash, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncAttempts: $syncAttempts, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('validationErrors: $validationErrors, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      examId,
      studentId,
      schoolId,
      attemptData,
      answers,
      isEncrypted,
      startedAt,
      completedAt,
      timeTakenSeconds,
      integrityHash,
      syncStatus,
      syncAttempts,
      syncedAt,
      validationErrors,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalExamAttemptsTableData &&
          other.id == this.id &&
          other.examId == this.examId &&
          other.studentId == this.studentId &&
          other.schoolId == this.schoolId &&
          other.attemptData == this.attemptData &&
          other.answers == this.answers &&
          other.isEncrypted == this.isEncrypted &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt &&
          other.timeTakenSeconds == this.timeTakenSeconds &&
          other.integrityHash == this.integrityHash &&
          other.syncStatus == this.syncStatus &&
          other.syncAttempts == this.syncAttempts &&
          other.syncedAt == this.syncedAt &&
          other.validationErrors == this.validationErrors &&
          other.createdAt == this.createdAt);
}

class LocalExamAttemptsTableCompanion
    extends UpdateCompanion<LocalExamAttemptsTableData> {
  final Value<String> id;
  final Value<String> examId;
  final Value<String> studentId;
  final Value<String?> schoolId;
  final Value<String> attemptData;
  final Value<String> answers;
  final Value<bool> isEncrypted;
  final Value<DateTime> startedAt;
  final Value<DateTime?> completedAt;
  final Value<int> timeTakenSeconds;
  final Value<String?> integrityHash;
  final Value<String> syncStatus;
  final Value<int> syncAttempts;
  final Value<DateTime?> syncedAt;
  final Value<String?> validationErrors;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LocalExamAttemptsTableCompanion({
    this.id = const Value.absent(),
    this.examId = const Value.absent(),
    this.studentId = const Value.absent(),
    this.schoolId = const Value.absent(),
    this.attemptData = const Value.absent(),
    this.answers = const Value.absent(),
    this.isEncrypted = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.timeTakenSeconds = const Value.absent(),
    this.integrityHash = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.syncAttempts = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.validationErrors = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalExamAttemptsTableCompanion.insert({
    required String id,
    required String examId,
    required String studentId,
    this.schoolId = const Value.absent(),
    required String attemptData,
    required String answers,
    this.isEncrypted = const Value.absent(),
    required DateTime startedAt,
    this.completedAt = const Value.absent(),
    this.timeTakenSeconds = const Value.absent(),
    this.integrityHash = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.syncAttempts = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.validationErrors = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        examId = Value(examId),
        studentId = Value(studentId),
        attemptData = Value(attemptData),
        answers = Value(answers),
        startedAt = Value(startedAt),
        createdAt = Value(createdAt);
  static Insertable<LocalExamAttemptsTableData> custom({
    Expression<String>? id,
    Expression<String>? examId,
    Expression<String>? studentId,
    Expression<String>? schoolId,
    Expression<String>? attemptData,
    Expression<String>? answers,
    Expression<bool>? isEncrypted,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
    Expression<int>? timeTakenSeconds,
    Expression<String>? integrityHash,
    Expression<String>? syncStatus,
    Expression<int>? syncAttempts,
    Expression<DateTime>? syncedAt,
    Expression<String>? validationErrors,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (examId != null) 'exam_id': examId,
      if (studentId != null) 'student_id': studentId,
      if (schoolId != null) 'school_id': schoolId,
      if (attemptData != null) 'attempt_data': attemptData,
      if (answers != null) 'answers': answers,
      if (isEncrypted != null) 'is_encrypted': isEncrypted,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (timeTakenSeconds != null) 'time_taken_seconds': timeTakenSeconds,
      if (integrityHash != null) 'integrity_hash': integrityHash,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (syncAttempts != null) 'sync_attempts': syncAttempts,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (validationErrors != null) 'validation_errors': validationErrors,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalExamAttemptsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? examId,
      Value<String>? studentId,
      Value<String?>? schoolId,
      Value<String>? attemptData,
      Value<String>? answers,
      Value<bool>? isEncrypted,
      Value<DateTime>? startedAt,
      Value<DateTime?>? completedAt,
      Value<int>? timeTakenSeconds,
      Value<String?>? integrityHash,
      Value<String>? syncStatus,
      Value<int>? syncAttempts,
      Value<DateTime?>? syncedAt,
      Value<String?>? validationErrors,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return LocalExamAttemptsTableCompanion(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      studentId: studentId ?? this.studentId,
      schoolId: schoolId ?? this.schoolId,
      attemptData: attemptData ?? this.attemptData,
      answers: answers ?? this.answers,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      timeTakenSeconds: timeTakenSeconds ?? this.timeTakenSeconds,
      integrityHash: integrityHash ?? this.integrityHash,
      syncStatus: syncStatus ?? this.syncStatus,
      syncAttempts: syncAttempts ?? this.syncAttempts,
      syncedAt: syncedAt ?? this.syncedAt,
      validationErrors: validationErrors ?? this.validationErrors,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (examId.present) {
      map['exam_id'] = Variable<String>(examId.value);
    }
    if (studentId.present) {
      map['student_id'] = Variable<String>(studentId.value);
    }
    if (schoolId.present) {
      map['school_id'] = Variable<String>(schoolId.value);
    }
    if (attemptData.present) {
      map['attempt_data'] = Variable<String>(attemptData.value);
    }
    if (answers.present) {
      map['answers'] = Variable<String>(answers.value);
    }
    if (isEncrypted.present) {
      map['is_encrypted'] = Variable<bool>(isEncrypted.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (timeTakenSeconds.present) {
      map['time_taken_seconds'] = Variable<int>(timeTakenSeconds.value);
    }
    if (integrityHash.present) {
      map['integrity_hash'] = Variable<String>(integrityHash.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (syncAttempts.present) {
      map['sync_attempts'] = Variable<int>(syncAttempts.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (validationErrors.present) {
      map['validation_errors'] = Variable<String>(validationErrors.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalExamAttemptsTableCompanion(')
          ..write('id: $id, ')
          ..write('examId: $examId, ')
          ..write('studentId: $studentId, ')
          ..write('schoolId: $schoolId, ')
          ..write('attemptData: $attemptData, ')
          ..write('answers: $answers, ')
          ..write('isEncrypted: $isEncrypted, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('timeTakenSeconds: $timeTakenSeconds, ')
          ..write('integrityHash: $integrityHash, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncAttempts: $syncAttempts, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('validationErrors: $validationErrors, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalNotificationsTableTable extends LocalNotificationsTable
    with TableInfo<$LocalNotificationsTableTable, LocalNotificationsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalNotificationsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _notificationDataMeta =
      const VerificationMeta('notificationData');
  @override
  late final GeneratedColumn<String> notificationData = GeneratedColumn<String>(
      'notification_data', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
      'is_read', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_read" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _receivedAtMeta =
      const VerificationMeta('receivedAt');
  @override
  late final GeneratedColumn<DateTime> receivedAt = GeneratedColumn<DateTime>(
      'received_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        notificationData,
        type,
        title,
        isRead,
        receivedAt,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_notifications_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<LocalNotificationsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('notification_data')) {
      context.handle(
          _notificationDataMeta,
          notificationData.isAcceptableOrUnknown(
              data['notification_data']!, _notificationDataMeta));
    } else if (isInserting) {
      context.missing(_notificationDataMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('is_read')) {
      context.handle(_isReadMeta,
          isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta));
    }
    if (data.containsKey('received_at')) {
      context.handle(
          _receivedAtMeta,
          receivedAt.isAcceptableOrUnknown(
              data['received_at']!, _receivedAtMeta));
    } else if (isInserting) {
      context.missing(_receivedAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalNotificationsTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalNotificationsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      notificationData: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}notification_data'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      isRead: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_read'])!,
      receivedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}received_at'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $LocalNotificationsTableTable createAlias(String alias) {
    return $LocalNotificationsTableTable(attachedDatabase, alias);
  }
}

class LocalNotificationsTableData extends DataClass
    implements Insertable<LocalNotificationsTableData> {
  /// Unique identifier for the cached notification.
  final String id;

  /// User ID this notification belongs to.
  final String userId;

  /// JSON-encoded notification data.
  final String notificationData;

  /// Notification type (e.g. `exam_reminder`, `result_published`).
  final String type;

  /// Notification title.
  final String title;

  /// Whether the user has read this notification.
  final bool isRead;

  /// When the notification was received.
  final DateTime receivedAt;

  /// When the entry was created.
  final DateTime createdAt;
  const LocalNotificationsTableData(
      {required this.id,
      required this.userId,
      required this.notificationData,
      required this.type,
      required this.title,
      required this.isRead,
      required this.receivedAt,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['notification_data'] = Variable<String>(notificationData);
    map['type'] = Variable<String>(type);
    map['title'] = Variable<String>(title);
    map['is_read'] = Variable<bool>(isRead);
    map['received_at'] = Variable<DateTime>(receivedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalNotificationsTableCompanion toCompanion(bool nullToAbsent) {
    return LocalNotificationsTableCompanion(
      id: Value(id),
      userId: Value(userId),
      notificationData: Value(notificationData),
      type: Value(type),
      title: Value(title),
      isRead: Value(isRead),
      receivedAt: Value(receivedAt),
      createdAt: Value(createdAt),
    );
  }

  factory LocalNotificationsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalNotificationsTableData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      notificationData: serializer.fromJson<String>(json['notificationData']),
      type: serializer.fromJson<String>(json['type']),
      title: serializer.fromJson<String>(json['title']),
      isRead: serializer.fromJson<bool>(json['isRead']),
      receivedAt: serializer.fromJson<DateTime>(json['receivedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'notificationData': serializer.toJson<String>(notificationData),
      'type': serializer.toJson<String>(type),
      'title': serializer.toJson<String>(title),
      'isRead': serializer.toJson<bool>(isRead),
      'receivedAt': serializer.toJson<DateTime>(receivedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalNotificationsTableData copyWith(
          {String? id,
          String? userId,
          String? notificationData,
          String? type,
          String? title,
          bool? isRead,
          DateTime? receivedAt,
          DateTime? createdAt}) =>
      LocalNotificationsTableData(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        notificationData: notificationData ?? this.notificationData,
        type: type ?? this.type,
        title: title ?? this.title,
        isRead: isRead ?? this.isRead,
        receivedAt: receivedAt ?? this.receivedAt,
        createdAt: createdAt ?? this.createdAt,
      );
  LocalNotificationsTableData copyWithCompanion(
      LocalNotificationsTableCompanion data) {
    return LocalNotificationsTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      notificationData: data.notificationData.present
          ? data.notificationData.value
          : this.notificationData,
      type: data.type.present ? data.type.value : this.type,
      title: data.title.present ? data.title.value : this.title,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
      receivedAt:
          data.receivedAt.present ? data.receivedAt.value : this.receivedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalNotificationsTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('notificationData: $notificationData, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('isRead: $isRead, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, userId, notificationData, type, title, isRead, receivedAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalNotificationsTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.notificationData == this.notificationData &&
          other.type == this.type &&
          other.title == this.title &&
          other.isRead == this.isRead &&
          other.receivedAt == this.receivedAt &&
          other.createdAt == this.createdAt);
}

class LocalNotificationsTableCompanion
    extends UpdateCompanion<LocalNotificationsTableData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> notificationData;
  final Value<String> type;
  final Value<String> title;
  final Value<bool> isRead;
  final Value<DateTime> receivedAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LocalNotificationsTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.notificationData = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.isRead = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalNotificationsTableCompanion.insert({
    required String id,
    required String userId,
    required String notificationData,
    required String type,
    required String title,
    this.isRead = const Value.absent(),
    required DateTime receivedAt,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        notificationData = Value(notificationData),
        type = Value(type),
        title = Value(title),
        receivedAt = Value(receivedAt),
        createdAt = Value(createdAt);
  static Insertable<LocalNotificationsTableData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? notificationData,
    Expression<String>? type,
    Expression<String>? title,
    Expression<bool>? isRead,
    Expression<DateTime>? receivedAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (notificationData != null) 'notification_data': notificationData,
      if (type != null) 'type': type,
      if (title != null) 'title': title,
      if (isRead != null) 'is_read': isRead,
      if (receivedAt != null) 'received_at': receivedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalNotificationsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? notificationData,
      Value<String>? type,
      Value<String>? title,
      Value<bool>? isRead,
      Value<DateTime>? receivedAt,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return LocalNotificationsTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      notificationData: notificationData ?? this.notificationData,
      type: type ?? this.type,
      title: title ?? this.title,
      isRead: isRead ?? this.isRead,
      receivedAt: receivedAt ?? this.receivedAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (notificationData.present) {
      map['notification_data'] = Variable<String>(notificationData.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<DateTime>(receivedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalNotificationsTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('notificationData: $notificationData, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('isRead: $isRead, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConnectivityLogsTableTable extends ConnectivityLogsTable
    with TableInfo<$ConnectivityLogsTableTable, ConnectivityLogsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConnectivityLogsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _connectionTypeMeta =
      const VerificationMeta('connectionType');
  @override
  late final GeneratedColumn<String> connectionType = GeneratedColumn<String>(
      'connection_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _connectionQualityMeta =
      const VerificationMeta('connectionQuality');
  @override
  late final GeneratedColumn<String> connectionQuality =
      GeneratedColumn<String>('connection_quality', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _latencyMsMeta =
      const VerificationMeta('latencyMs');
  @override
  late final GeneratedColumn<int> latencyMs = GeneratedColumn<int>(
      'latency_ms', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _bandwidthKbpsMeta =
      const VerificationMeta('bandwidthKbps');
  @override
  late final GeneratedColumn<int> bandwidthKbps = GeneratedColumn<int>(
      'bandwidth_kbps', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _wasOfflineMeta =
      const VerificationMeta('wasOffline');
  @override
  late final GeneratedColumn<bool> wasOffline = GeneratedColumn<bool>(
      'was_offline', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("was_offline" IN (0, 1))'));
  static const VerificationMeta _offlineDurationSecondsMeta =
      const VerificationMeta('offlineDurationSeconds');
  @override
  late final GeneratedColumn<int> offlineDurationSeconds = GeneratedColumn<int>(
      'offline_duration_seconds', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _recordedAtMeta =
      const VerificationMeta('recordedAt');
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
      'recorded_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        connectionType,
        connectionQuality,
        latencyMs,
        bandwidthKbps,
        wasOffline,
        offlineDurationSeconds,
        recordedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'connectivity_logs_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<ConnectivityLogsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('connection_type')) {
      context.handle(
          _connectionTypeMeta,
          connectionType.isAcceptableOrUnknown(
              data['connection_type']!, _connectionTypeMeta));
    } else if (isInserting) {
      context.missing(_connectionTypeMeta);
    }
    if (data.containsKey('connection_quality')) {
      context.handle(
          _connectionQualityMeta,
          connectionQuality.isAcceptableOrUnknown(
              data['connection_quality']!, _connectionQualityMeta));
    } else if (isInserting) {
      context.missing(_connectionQualityMeta);
    }
    if (data.containsKey('latency_ms')) {
      context.handle(_latencyMsMeta,
          latencyMs.isAcceptableOrUnknown(data['latency_ms']!, _latencyMsMeta));
    }
    if (data.containsKey('bandwidth_kbps')) {
      context.handle(
          _bandwidthKbpsMeta,
          bandwidthKbps.isAcceptableOrUnknown(
              data['bandwidth_kbps']!, _bandwidthKbpsMeta));
    }
    if (data.containsKey('was_offline')) {
      context.handle(
          _wasOfflineMeta,
          wasOffline.isAcceptableOrUnknown(
              data['was_offline']!, _wasOfflineMeta));
    } else if (isInserting) {
      context.missing(_wasOfflineMeta);
    }
    if (data.containsKey('offline_duration_seconds')) {
      context.handle(
          _offlineDurationSecondsMeta,
          offlineDurationSeconds.isAcceptableOrUnknown(
              data['offline_duration_seconds']!, _offlineDurationSecondsMeta));
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
          _recordedAtMeta,
          recordedAt.isAcceptableOrUnknown(
              data['recorded_at']!, _recordedAtMeta));
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConnectivityLogsTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConnectivityLogsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      connectionType: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}connection_type'])!,
      connectionQuality: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}connection_quality'])!,
      latencyMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}latency_ms']),
      bandwidthKbps: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}bandwidth_kbps']),
      wasOffline: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}was_offline'])!,
      offlineDurationSeconds: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}offline_duration_seconds']),
      recordedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}recorded_at'])!,
    );
  }

  @override
  $ConnectivityLogsTableTable createAlias(String alias) {
    return $ConnectivityLogsTableTable(attachedDatabase, alias);
  }
}

class ConnectivityLogsTableData extends DataClass
    implements Insertable<ConnectivityLogsTableData> {
  /// Unique identifier for the log entry.
  final String id;

  /// Connection type (wifi, mobile, ethernet, none).
  final String connectionType;

  /// Connection quality (excellent, good, poor, offline).
  final String connectionQuality;

  /// Latency in milliseconds.
  final int? latencyMs;

  /// Bandwidth in kilobits per second.
  final int? bandwidthKbps;

  /// Whether the device was offline at the time of recording.
  final bool wasOffline;

  /// Duration of the offline period in seconds (null if online).
  final int? offlineDurationSeconds;

  /// When the log was recorded.
  final DateTime recordedAt;
  const ConnectivityLogsTableData(
      {required this.id,
      required this.connectionType,
      required this.connectionQuality,
      this.latencyMs,
      this.bandwidthKbps,
      required this.wasOffline,
      this.offlineDurationSeconds,
      required this.recordedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['connection_type'] = Variable<String>(connectionType);
    map['connection_quality'] = Variable<String>(connectionQuality);
    if (!nullToAbsent || latencyMs != null) {
      map['latency_ms'] = Variable<int>(latencyMs);
    }
    if (!nullToAbsent || bandwidthKbps != null) {
      map['bandwidth_kbps'] = Variable<int>(bandwidthKbps);
    }
    map['was_offline'] = Variable<bool>(wasOffline);
    if (!nullToAbsent || offlineDurationSeconds != null) {
      map['offline_duration_seconds'] = Variable<int>(offlineDurationSeconds);
    }
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    return map;
  }

  ConnectivityLogsTableCompanion toCompanion(bool nullToAbsent) {
    return ConnectivityLogsTableCompanion(
      id: Value(id),
      connectionType: Value(connectionType),
      connectionQuality: Value(connectionQuality),
      latencyMs: latencyMs == null && nullToAbsent
          ? const Value.absent()
          : Value(latencyMs),
      bandwidthKbps: bandwidthKbps == null && nullToAbsent
          ? const Value.absent()
          : Value(bandwidthKbps),
      wasOffline: Value(wasOffline),
      offlineDurationSeconds: offlineDurationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(offlineDurationSeconds),
      recordedAt: Value(recordedAt),
    );
  }

  factory ConnectivityLogsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConnectivityLogsTableData(
      id: serializer.fromJson<String>(json['id']),
      connectionType: serializer.fromJson<String>(json['connectionType']),
      connectionQuality: serializer.fromJson<String>(json['connectionQuality']),
      latencyMs: serializer.fromJson<int?>(json['latencyMs']),
      bandwidthKbps: serializer.fromJson<int?>(json['bandwidthKbps']),
      wasOffline: serializer.fromJson<bool>(json['wasOffline']),
      offlineDurationSeconds:
          serializer.fromJson<int?>(json['offlineDurationSeconds']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'connectionType': serializer.toJson<String>(connectionType),
      'connectionQuality': serializer.toJson<String>(connectionQuality),
      'latencyMs': serializer.toJson<int?>(latencyMs),
      'bandwidthKbps': serializer.toJson<int?>(bandwidthKbps),
      'wasOffline': serializer.toJson<bool>(wasOffline),
      'offlineDurationSeconds': serializer.toJson<int?>(offlineDurationSeconds),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
    };
  }

  ConnectivityLogsTableData copyWith(
          {String? id,
          String? connectionType,
          String? connectionQuality,
          Value<int?> latencyMs = const Value.absent(),
          Value<int?> bandwidthKbps = const Value.absent(),
          bool? wasOffline,
          Value<int?> offlineDurationSeconds = const Value.absent(),
          DateTime? recordedAt}) =>
      ConnectivityLogsTableData(
        id: id ?? this.id,
        connectionType: connectionType ?? this.connectionType,
        connectionQuality: connectionQuality ?? this.connectionQuality,
        latencyMs: latencyMs.present ? latencyMs.value : this.latencyMs,
        bandwidthKbps:
            bandwidthKbps.present ? bandwidthKbps.value : this.bandwidthKbps,
        wasOffline: wasOffline ?? this.wasOffline,
        offlineDurationSeconds: offlineDurationSeconds.present
            ? offlineDurationSeconds.value
            : this.offlineDurationSeconds,
        recordedAt: recordedAt ?? this.recordedAt,
      );
  ConnectivityLogsTableData copyWithCompanion(
      ConnectivityLogsTableCompanion data) {
    return ConnectivityLogsTableData(
      id: data.id.present ? data.id.value : this.id,
      connectionType: data.connectionType.present
          ? data.connectionType.value
          : this.connectionType,
      connectionQuality: data.connectionQuality.present
          ? data.connectionQuality.value
          : this.connectionQuality,
      latencyMs: data.latencyMs.present ? data.latencyMs.value : this.latencyMs,
      bandwidthKbps: data.bandwidthKbps.present
          ? data.bandwidthKbps.value
          : this.bandwidthKbps,
      wasOffline:
          data.wasOffline.present ? data.wasOffline.value : this.wasOffline,
      offlineDurationSeconds: data.offlineDurationSeconds.present
          ? data.offlineDurationSeconds.value
          : this.offlineDurationSeconds,
      recordedAt:
          data.recordedAt.present ? data.recordedAt.value : this.recordedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConnectivityLogsTableData(')
          ..write('id: $id, ')
          ..write('connectionType: $connectionType, ')
          ..write('connectionQuality: $connectionQuality, ')
          ..write('latencyMs: $latencyMs, ')
          ..write('bandwidthKbps: $bandwidthKbps, ')
          ..write('wasOffline: $wasOffline, ')
          ..write('offlineDurationSeconds: $offlineDurationSeconds, ')
          ..write('recordedAt: $recordedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, connectionType, connectionQuality,
      latencyMs, bandwidthKbps, wasOffline, offlineDurationSeconds, recordedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConnectivityLogsTableData &&
          other.id == this.id &&
          other.connectionType == this.connectionType &&
          other.connectionQuality == this.connectionQuality &&
          other.latencyMs == this.latencyMs &&
          other.bandwidthKbps == this.bandwidthKbps &&
          other.wasOffline == this.wasOffline &&
          other.offlineDurationSeconds == this.offlineDurationSeconds &&
          other.recordedAt == this.recordedAt);
}

class ConnectivityLogsTableCompanion
    extends UpdateCompanion<ConnectivityLogsTableData> {
  final Value<String> id;
  final Value<String> connectionType;
  final Value<String> connectionQuality;
  final Value<int?> latencyMs;
  final Value<int?> bandwidthKbps;
  final Value<bool> wasOffline;
  final Value<int?> offlineDurationSeconds;
  final Value<DateTime> recordedAt;
  final Value<int> rowid;
  const ConnectivityLogsTableCompanion({
    this.id = const Value.absent(),
    this.connectionType = const Value.absent(),
    this.connectionQuality = const Value.absent(),
    this.latencyMs = const Value.absent(),
    this.bandwidthKbps = const Value.absent(),
    this.wasOffline = const Value.absent(),
    this.offlineDurationSeconds = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConnectivityLogsTableCompanion.insert({
    required String id,
    required String connectionType,
    required String connectionQuality,
    this.latencyMs = const Value.absent(),
    this.bandwidthKbps = const Value.absent(),
    required bool wasOffline,
    this.offlineDurationSeconds = const Value.absent(),
    required DateTime recordedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        connectionType = Value(connectionType),
        connectionQuality = Value(connectionQuality),
        wasOffline = Value(wasOffline),
        recordedAt = Value(recordedAt);
  static Insertable<ConnectivityLogsTableData> custom({
    Expression<String>? id,
    Expression<String>? connectionType,
    Expression<String>? connectionQuality,
    Expression<int>? latencyMs,
    Expression<int>? bandwidthKbps,
    Expression<bool>? wasOffline,
    Expression<int>? offlineDurationSeconds,
    Expression<DateTime>? recordedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (connectionType != null) 'connection_type': connectionType,
      if (connectionQuality != null) 'connection_quality': connectionQuality,
      if (latencyMs != null) 'latency_ms': latencyMs,
      if (bandwidthKbps != null) 'bandwidth_kbps': bandwidthKbps,
      if (wasOffline != null) 'was_offline': wasOffline,
      if (offlineDurationSeconds != null)
        'offline_duration_seconds': offlineDurationSeconds,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConnectivityLogsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? connectionType,
      Value<String>? connectionQuality,
      Value<int?>? latencyMs,
      Value<int?>? bandwidthKbps,
      Value<bool>? wasOffline,
      Value<int?>? offlineDurationSeconds,
      Value<DateTime>? recordedAt,
      Value<int>? rowid}) {
    return ConnectivityLogsTableCompanion(
      id: id ?? this.id,
      connectionType: connectionType ?? this.connectionType,
      connectionQuality: connectionQuality ?? this.connectionQuality,
      latencyMs: latencyMs ?? this.latencyMs,
      bandwidthKbps: bandwidthKbps ?? this.bandwidthKbps,
      wasOffline: wasOffline ?? this.wasOffline,
      offlineDurationSeconds:
          offlineDurationSeconds ?? this.offlineDurationSeconds,
      recordedAt: recordedAt ?? this.recordedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (connectionType.present) {
      map['connection_type'] = Variable<String>(connectionType.value);
    }
    if (connectionQuality.present) {
      map['connection_quality'] = Variable<String>(connectionQuality.value);
    }
    if (latencyMs.present) {
      map['latency_ms'] = Variable<int>(latencyMs.value);
    }
    if (bandwidthKbps.present) {
      map['bandwidth_kbps'] = Variable<int>(bandwidthKbps.value);
    }
    if (wasOffline.present) {
      map['was_offline'] = Variable<bool>(wasOffline.value);
    }
    if (offlineDurationSeconds.present) {
      map['offline_duration_seconds'] =
          Variable<int>(offlineDurationSeconds.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConnectivityLogsTableCompanion(')
          ..write('id: $id, ')
          ..write('connectionType: $connectionType, ')
          ..write('connectionQuality: $connectionQuality, ')
          ..write('latencyMs: $latencyMs, ')
          ..write('bandwidthKbps: $bandwidthKbps, ')
          ..write('wasOffline: $wasOffline, ')
          ..write('offlineDurationSeconds: $offlineDurationSeconds, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalSyncMetadataTableTable extends LocalSyncMetadataTable
    with TableInfo<$LocalSyncMetadataTableTable, LocalSyncMetadataTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSyncMetadataTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _targetTableMeta =
      const VerificationMeta('targetTable');
  @override
  late final GeneratedColumn<String> targetTable = GeneratedColumn<String>(
      'target_table', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastSyncedAtMeta =
      const VerificationMeta('lastSyncedAt');
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
      'last_synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _syncCursorMeta =
      const VerificationMeta('syncCursor');
  @override
  late final GeneratedColumn<String> syncCursor = GeneratedColumn<String>(
      'sync_cursor', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _recordCountMeta =
      const VerificationMeta('recordCount');
  @override
  late final GeneratedColumn<int> recordCount = GeneratedColumn<int>(
      'record_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _checksumMeta =
      const VerificationMeta('checksum');
  @override
  late final GeneratedColumn<String> checksum = GeneratedColumn<String>(
      'checksum', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isFullSyncMeta =
      const VerificationMeta('isFullSync');
  @override
  late final GeneratedColumn<bool> isFullSync = GeneratedColumn<bool>(
      'is_full_sync', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_full_sync" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        targetTable,
        lastSyncedAt,
        syncCursor,
        recordCount,
        checksum,
        isFullSync,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_sync_metadata_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<LocalSyncMetadataTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('target_table')) {
      context.handle(
          _targetTableMeta,
          targetTable.isAcceptableOrUnknown(
              data['target_table']!, _targetTableMeta));
    } else if (isInserting) {
      context.missing(_targetTableMeta);
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
          _lastSyncedAtMeta,
          lastSyncedAt.isAcceptableOrUnknown(
              data['last_synced_at']!, _lastSyncedAtMeta));
    }
    if (data.containsKey('sync_cursor')) {
      context.handle(
          _syncCursorMeta,
          syncCursor.isAcceptableOrUnknown(
              data['sync_cursor']!, _syncCursorMeta));
    }
    if (data.containsKey('record_count')) {
      context.handle(
          _recordCountMeta,
          recordCount.isAcceptableOrUnknown(
              data['record_count']!, _recordCountMeta));
    }
    if (data.containsKey('checksum')) {
      context.handle(_checksumMeta,
          checksum.isAcceptableOrUnknown(data['checksum']!, _checksumMeta));
    }
    if (data.containsKey('is_full_sync')) {
      context.handle(
          _isFullSyncMeta,
          isFullSync.isAcceptableOrUnknown(
              data['is_full_sync']!, _isFullSyncMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalSyncMetadataTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSyncMetadataTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      targetTable: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}target_table'])!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_synced_at']),
      syncCursor: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_cursor']),
      recordCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}record_count'])!,
      checksum: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}checksum']),
      isFullSync: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_full_sync'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $LocalSyncMetadataTableTable createAlias(String alias) {
    return $LocalSyncMetadataTableTable(attachedDatabase, alias);
  }
}

class LocalSyncMetadataTableData extends DataClass
    implements Insertable<LocalSyncMetadataTableData> {
  /// Unique identifier for the metadata entry.
  final String id;

  /// User ID this metadata belongs to.
  final String userId;

  /// Table name this metadata tracks.
  final String targetTable;

  /// When the table was last fully synced.
  final DateTime? lastSyncedAt;

  /// Sync cursor for incremental syncs.
  final String? syncCursor;

  /// Number of records at the time of last sync.
  final int recordCount;

  /// Checksum of the table data at last sync.
  final String? checksum;

  /// Whether the last sync was a full sync.
  final bool isFullSync;

  /// When the metadata entry was created.
  final DateTime createdAt;

  /// When the metadata entry was last updated.
  final DateTime updatedAt;
  const LocalSyncMetadataTableData(
      {required this.id,
      required this.userId,
      required this.targetTable,
      this.lastSyncedAt,
      this.syncCursor,
      required this.recordCount,
      this.checksum,
      required this.isFullSync,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['target_table'] = Variable<String>(targetTable);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    if (!nullToAbsent || syncCursor != null) {
      map['sync_cursor'] = Variable<String>(syncCursor);
    }
    map['record_count'] = Variable<int>(recordCount);
    if (!nullToAbsent || checksum != null) {
      map['checksum'] = Variable<String>(checksum);
    }
    map['is_full_sync'] = Variable<bool>(isFullSync);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalSyncMetadataTableCompanion toCompanion(bool nullToAbsent) {
    return LocalSyncMetadataTableCompanion(
      id: Value(id),
      userId: Value(userId),
      targetTable: Value(targetTable),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      syncCursor: syncCursor == null && nullToAbsent
          ? const Value.absent()
          : Value(syncCursor),
      recordCount: Value(recordCount),
      checksum: checksum == null && nullToAbsent
          ? const Value.absent()
          : Value(checksum),
      isFullSync: Value(isFullSync),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalSyncMetadataTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSyncMetadataTableData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      targetTable: serializer.fromJson<String>(json['targetTable']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      syncCursor: serializer.fromJson<String?>(json['syncCursor']),
      recordCount: serializer.fromJson<int>(json['recordCount']),
      checksum: serializer.fromJson<String?>(json['checksum']),
      isFullSync: serializer.fromJson<bool>(json['isFullSync']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'targetTable': serializer.toJson<String>(targetTable),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'syncCursor': serializer.toJson<String?>(syncCursor),
      'recordCount': serializer.toJson<int>(recordCount),
      'checksum': serializer.toJson<String?>(checksum),
      'isFullSync': serializer.toJson<bool>(isFullSync),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalSyncMetadataTableData copyWith(
          {String? id,
          String? userId,
          String? targetTable,
          Value<DateTime?> lastSyncedAt = const Value.absent(),
          Value<String?> syncCursor = const Value.absent(),
          int? recordCount,
          Value<String?> checksum = const Value.absent(),
          bool? isFullSync,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      LocalSyncMetadataTableData(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        targetTable: targetTable ?? this.targetTable,
        lastSyncedAt:
            lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
        syncCursor: syncCursor.present ? syncCursor.value : this.syncCursor,
        recordCount: recordCount ?? this.recordCount,
        checksum: checksum.present ? checksum.value : this.checksum,
        isFullSync: isFullSync ?? this.isFullSync,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  LocalSyncMetadataTableData copyWithCompanion(
      LocalSyncMetadataTableCompanion data) {
    return LocalSyncMetadataTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      targetTable:
          data.targetTable.present ? data.targetTable.value : this.targetTable,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      syncCursor:
          data.syncCursor.present ? data.syncCursor.value : this.syncCursor,
      recordCount:
          data.recordCount.present ? data.recordCount.value : this.recordCount,
      checksum: data.checksum.present ? data.checksum.value : this.checksum,
      isFullSync:
          data.isFullSync.present ? data.isFullSync.value : this.isFullSync,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSyncMetadataTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('targetTable: $targetTable, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('syncCursor: $syncCursor, ')
          ..write('recordCount: $recordCount, ')
          ..write('checksum: $checksum, ')
          ..write('isFullSync: $isFullSync, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, targetTable, lastSyncedAt,
      syncCursor, recordCount, checksum, isFullSync, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSyncMetadataTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.targetTable == this.targetTable &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.syncCursor == this.syncCursor &&
          other.recordCount == this.recordCount &&
          other.checksum == this.checksum &&
          other.isFullSync == this.isFullSync &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalSyncMetadataTableCompanion
    extends UpdateCompanion<LocalSyncMetadataTableData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> targetTable;
  final Value<DateTime?> lastSyncedAt;
  final Value<String?> syncCursor;
  final Value<int> recordCount;
  final Value<String?> checksum;
  final Value<bool> isFullSync;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalSyncMetadataTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.targetTable = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.syncCursor = const Value.absent(),
    this.recordCount = const Value.absent(),
    this.checksum = const Value.absent(),
    this.isFullSync = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSyncMetadataTableCompanion.insert({
    required String id,
    required String userId,
    required String targetTable,
    this.lastSyncedAt = const Value.absent(),
    this.syncCursor = const Value.absent(),
    this.recordCount = const Value.absent(),
    this.checksum = const Value.absent(),
    this.isFullSync = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        targetTable = Value(targetTable),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<LocalSyncMetadataTableData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? targetTable,
    Expression<DateTime>? lastSyncedAt,
    Expression<String>? syncCursor,
    Expression<int>? recordCount,
    Expression<String>? checksum,
    Expression<bool>? isFullSync,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (targetTable != null) 'target_table': targetTable,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (syncCursor != null) 'sync_cursor': syncCursor,
      if (recordCount != null) 'record_count': recordCount,
      if (checksum != null) 'checksum': checksum,
      if (isFullSync != null) 'is_full_sync': isFullSync,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSyncMetadataTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? targetTable,
      Value<DateTime?>? lastSyncedAt,
      Value<String?>? syncCursor,
      Value<int>? recordCount,
      Value<String?>? checksum,
      Value<bool>? isFullSync,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return LocalSyncMetadataTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      targetTable: targetTable ?? this.targetTable,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      syncCursor: syncCursor ?? this.syncCursor,
      recordCount: recordCount ?? this.recordCount,
      checksum: checksum ?? this.checksum,
      isFullSync: isFullSync ?? this.isFullSync,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (targetTable.present) {
      map['target_table'] = Variable<String>(targetTable.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (syncCursor.present) {
      map['sync_cursor'] = Variable<String>(syncCursor.value);
    }
    if (recordCount.present) {
      map['record_count'] = Variable<int>(recordCount.value);
    }
    if (checksum.present) {
      map['checksum'] = Variable<String>(checksum.value);
    }
    if (isFullSync.present) {
      map['is_full_sync'] = Variable<bool>(isFullSync.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSyncMetadataTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('targetTable: $targetTable, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('syncCursor: $syncCursor, ')
          ..write('recordCount: $recordCount, ')
          ..write('checksum: $checksum, ')
          ..write('isFullSync: $isFullSync, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalSyncQueueTableTable localSyncQueueTable =
      $LocalSyncQueueTableTable(this);
  late final $LocalCacheTableTable localCacheTable =
      $LocalCacheTableTable(this);
  late final $LocalDraftsTableTable localDraftsTable =
      $LocalDraftsTableTable(this);
  late final $LocalUserDataTableTable localUserDataTable =
      $LocalUserDataTableTable(this);
  late final $LocalQuestionBankTableTable localQuestionBankTable =
      $LocalQuestionBankTableTable(this);
  late final $LocalResourcesTableTable localResourcesTable =
      $LocalResourcesTableTable(this);
  late final $LocalAnnouncementsTableTable localAnnouncementsTable =
      $LocalAnnouncementsTableTable(this);
  late final $LocalTimetableTableTable localTimetableTable =
      $LocalTimetableTableTable(this);
  late final $LocalExamAttemptsTableTable localExamAttemptsTable =
      $LocalExamAttemptsTableTable(this);
  late final $LocalNotificationsTableTable localNotificationsTable =
      $LocalNotificationsTableTable(this);
  late final $ConnectivityLogsTableTable connectivityLogsTable =
      $ConnectivityLogsTableTable(this);
  late final $LocalSyncMetadataTableTable localSyncMetadataTable =
      $LocalSyncMetadataTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        localSyncQueueTable,
        localCacheTable,
        localDraftsTable,
        localUserDataTable,
        localQuestionBankTable,
        localResourcesTable,
        localAnnouncementsTable,
        localTimetableTable,
        localExamAttemptsTable,
        localNotificationsTable,
        connectivityLogsTable,
        localSyncMetadataTable
      ];
}

typedef $$LocalSyncQueueTableTableCreateCompanionBuilder
    = LocalSyncQueueTableCompanion Function({
  required String id,
  required String userId,
  required String targetTable,
  Value<String?> recordId,
  required String operation,
  required String payload,
  Value<int> priority,
  Value<int> attempts,
  Value<int> maxAttempts,
  Value<DateTime?> lastAttemptAt,
  Value<DateTime?> nextRetryAt,
  Value<String> status,
  Value<String?> errorMessage,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$LocalSyncQueueTableTableUpdateCompanionBuilder
    = LocalSyncQueueTableCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> targetTable,
  Value<String?> recordId,
  Value<String> operation,
  Value<String> payload,
  Value<int> priority,
  Value<int> attempts,
  Value<int> maxAttempts,
  Value<DateTime?> lastAttemptAt,
  Value<DateTime?> nextRetryAt,
  Value<String> status,
  Value<String?> errorMessage,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$LocalSyncQueueTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalSyncQueueTableTable,
    LocalSyncQueueTableData,
    $$LocalSyncQueueTableTableFilterComposer,
    $$LocalSyncQueueTableTableOrderingComposer,
    $$LocalSyncQueueTableTableCreateCompanionBuilder,
    $$LocalSyncQueueTableTableUpdateCompanionBuilder> {
  $$LocalSyncQueueTableTableTableManager(
      _$AppDatabase db, $LocalSyncQueueTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer: $$LocalSyncQueueTableTableFilterComposer(
              ComposerState(db, table)),
          orderingComposer: $$LocalSyncQueueTableTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> targetTable = const Value.absent(),
            Value<String?> recordId = const Value.absent(),
            Value<String> operation = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<int> priority = const Value.absent(),
            Value<int> attempts = const Value.absent(),
            Value<int> maxAttempts = const Value.absent(),
            Value<DateTime?> lastAttemptAt = const Value.absent(),
            Value<DateTime?> nextRetryAt = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalSyncQueueTableCompanion(
            id: id,
            userId: userId,
            targetTable: targetTable,
            recordId: recordId,
            operation: operation,
            payload: payload,
            priority: priority,
            attempts: attempts,
            maxAttempts: maxAttempts,
            lastAttemptAt: lastAttemptAt,
            nextRetryAt: nextRetryAt,
            status: status,
            errorMessage: errorMessage,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String targetTable,
            Value<String?> recordId = const Value.absent(),
            required String operation,
            required String payload,
            Value<int> priority = const Value.absent(),
            Value<int> attempts = const Value.absent(),
            Value<int> maxAttempts = const Value.absent(),
            Value<DateTime?> lastAttemptAt = const Value.absent(),
            Value<DateTime?> nextRetryAt = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalSyncQueueTableCompanion.insert(
            id: id,
            userId: userId,
            targetTable: targetTable,
            recordId: recordId,
            operation: operation,
            payload: payload,
            priority: priority,
            attempts: attempts,
            maxAttempts: maxAttempts,
            lastAttemptAt: lastAttemptAt,
            nextRetryAt: nextRetryAt,
            status: status,
            errorMessage: errorMessage,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
        ));
}

class $$LocalSyncQueueTableTableFilterComposer
    extends FilterComposer<_$AppDatabase, $LocalSyncQueueTableTable> {
  $$LocalSyncQueueTableTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get userId => $state.composableBuilder(
      column: $state.table.userId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get targetTable => $state.composableBuilder(
      column: $state.table.targetTable,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get recordId => $state.composableBuilder(
      column: $state.table.recordId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get operation => $state.composableBuilder(
      column: $state.table.operation,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get payload => $state.composableBuilder(
      column: $state.table.payload,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get priority => $state.composableBuilder(
      column: $state.table.priority,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get attempts => $state.composableBuilder(
      column: $state.table.attempts,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get maxAttempts => $state.composableBuilder(
      column: $state.table.maxAttempts,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get lastAttemptAt => $state.composableBuilder(
      column: $state.table.lastAttemptAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get nextRetryAt => $state.composableBuilder(
      column: $state.table.nextRetryAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get errorMessage => $state.composableBuilder(
      column: $state.table.errorMessage,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$LocalSyncQueueTableTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $LocalSyncQueueTableTable> {
  $$LocalSyncQueueTableTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get userId => $state.composableBuilder(
      column: $state.table.userId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get targetTable => $state.composableBuilder(
      column: $state.table.targetTable,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get recordId => $state.composableBuilder(
      column: $state.table.recordId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get operation => $state.composableBuilder(
      column: $state.table.operation,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get payload => $state.composableBuilder(
      column: $state.table.payload,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get priority => $state.composableBuilder(
      column: $state.table.priority,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get attempts => $state.composableBuilder(
      column: $state.table.attempts,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get maxAttempts => $state.composableBuilder(
      column: $state.table.maxAttempts,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get lastAttemptAt => $state.composableBuilder(
      column: $state.table.lastAttemptAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get nextRetryAt => $state.composableBuilder(
      column: $state.table.nextRetryAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get errorMessage => $state.composableBuilder(
      column: $state.table.errorMessage,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$LocalCacheTableTableCreateCompanionBuilder = LocalCacheTableCompanion
    Function({
  required String id,
  required String userId,
  required String cacheKey,
  required String resourceType,
  required String resourceId,
  required String data,
  Value<int> version,
  Value<DateTime?> expiresAt,
  Value<int> fileSizeBytes,
  Value<String?> checksum,
  Value<bool> isEncrypted,
  Value<int> accessCount,
  Value<DateTime?> lastAccessedAt,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$LocalCacheTableTableUpdateCompanionBuilder = LocalCacheTableCompanion
    Function({
  Value<String> id,
  Value<String> userId,
  Value<String> cacheKey,
  Value<String> resourceType,
  Value<String> resourceId,
  Value<String> data,
  Value<int> version,
  Value<DateTime?> expiresAt,
  Value<int> fileSizeBytes,
  Value<String?> checksum,
  Value<bool> isEncrypted,
  Value<int> accessCount,
  Value<DateTime?> lastAccessedAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$LocalCacheTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalCacheTableTable,
    LocalCacheTableData,
    $$LocalCacheTableTableFilterComposer,
    $$LocalCacheTableTableOrderingComposer,
    $$LocalCacheTableTableCreateCompanionBuilder,
    $$LocalCacheTableTableUpdateCompanionBuilder> {
  $$LocalCacheTableTableTableManager(
      _$AppDatabase db, $LocalCacheTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$LocalCacheTableTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$LocalCacheTableTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> cacheKey = const Value.absent(),
            Value<String> resourceType = const Value.absent(),
            Value<String> resourceId = const Value.absent(),
            Value<String> data = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<DateTime?> expiresAt = const Value.absent(),
            Value<int> fileSizeBytes = const Value.absent(),
            Value<String?> checksum = const Value.absent(),
            Value<bool> isEncrypted = const Value.absent(),
            Value<int> accessCount = const Value.absent(),
            Value<DateTime?> lastAccessedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalCacheTableCompanion(
            id: id,
            userId: userId,
            cacheKey: cacheKey,
            resourceType: resourceType,
            resourceId: resourceId,
            data: data,
            version: version,
            expiresAt: expiresAt,
            fileSizeBytes: fileSizeBytes,
            checksum: checksum,
            isEncrypted: isEncrypted,
            accessCount: accessCount,
            lastAccessedAt: lastAccessedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String cacheKey,
            required String resourceType,
            required String resourceId,
            required String data,
            Value<int> version = const Value.absent(),
            Value<DateTime?> expiresAt = const Value.absent(),
            Value<int> fileSizeBytes = const Value.absent(),
            Value<String?> checksum = const Value.absent(),
            Value<bool> isEncrypted = const Value.absent(),
            Value<int> accessCount = const Value.absent(),
            Value<DateTime?> lastAccessedAt = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalCacheTableCompanion.insert(
            id: id,
            userId: userId,
            cacheKey: cacheKey,
            resourceType: resourceType,
            resourceId: resourceId,
            data: data,
            version: version,
            expiresAt: expiresAt,
            fileSizeBytes: fileSizeBytes,
            checksum: checksum,
            isEncrypted: isEncrypted,
            accessCount: accessCount,
            lastAccessedAt: lastAccessedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
        ));
}

class $$LocalCacheTableTableFilterComposer
    extends FilterComposer<_$AppDatabase, $LocalCacheTableTable> {
  $$LocalCacheTableTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get userId => $state.composableBuilder(
      column: $state.table.userId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get cacheKey => $state.composableBuilder(
      column: $state.table.cacheKey,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get resourceType => $state.composableBuilder(
      column: $state.table.resourceType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get resourceId => $state.composableBuilder(
      column: $state.table.resourceId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get data => $state.composableBuilder(
      column: $state.table.data,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get version => $state.composableBuilder(
      column: $state.table.version,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get expiresAt => $state.composableBuilder(
      column: $state.table.expiresAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get fileSizeBytes => $state.composableBuilder(
      column: $state.table.fileSizeBytes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get checksum => $state.composableBuilder(
      column: $state.table.checksum,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isEncrypted => $state.composableBuilder(
      column: $state.table.isEncrypted,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get accessCount => $state.composableBuilder(
      column: $state.table.accessCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get lastAccessedAt => $state.composableBuilder(
      column: $state.table.lastAccessedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$LocalCacheTableTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $LocalCacheTableTable> {
  $$LocalCacheTableTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get userId => $state.composableBuilder(
      column: $state.table.userId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get cacheKey => $state.composableBuilder(
      column: $state.table.cacheKey,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get resourceType => $state.composableBuilder(
      column: $state.table.resourceType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get resourceId => $state.composableBuilder(
      column: $state.table.resourceId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get data => $state.composableBuilder(
      column: $state.table.data,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get version => $state.composableBuilder(
      column: $state.table.version,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get expiresAt => $state.composableBuilder(
      column: $state.table.expiresAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get fileSizeBytes => $state.composableBuilder(
      column: $state.table.fileSizeBytes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get checksum => $state.composableBuilder(
      column: $state.table.checksum,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isEncrypted => $state.composableBuilder(
      column: $state.table.isEncrypted,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get accessCount => $state.composableBuilder(
      column: $state.table.accessCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get lastAccessedAt => $state.composableBuilder(
      column: $state.table.lastAccessedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$LocalDraftsTableTableCreateCompanionBuilder
    = LocalDraftsTableCompanion Function({
  required String id,
  required String userId,
  required String draftType,
  Value<String?> title,
  required String content,
  Value<String?> schoolId,
  Value<String?> subjectId,
  Value<bool> isSynced,
  required DateTime lastEditedAt,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$LocalDraftsTableTableUpdateCompanionBuilder
    = LocalDraftsTableCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> draftType,
  Value<String?> title,
  Value<String> content,
  Value<String?> schoolId,
  Value<String?> subjectId,
  Value<bool> isSynced,
  Value<DateTime> lastEditedAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$LocalDraftsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalDraftsTableTable,
    LocalDraftsTableData,
    $$LocalDraftsTableTableFilterComposer,
    $$LocalDraftsTableTableOrderingComposer,
    $$LocalDraftsTableTableCreateCompanionBuilder,
    $$LocalDraftsTableTableUpdateCompanionBuilder> {
  $$LocalDraftsTableTableTableManager(
      _$AppDatabase db, $LocalDraftsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$LocalDraftsTableTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$LocalDraftsTableTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> draftType = const Value.absent(),
            Value<String?> title = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<String?> schoolId = const Value.absent(),
            Value<String?> subjectId = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<DateTime> lastEditedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalDraftsTableCompanion(
            id: id,
            userId: userId,
            draftType: draftType,
            title: title,
            content: content,
            schoolId: schoolId,
            subjectId: subjectId,
            isSynced: isSynced,
            lastEditedAt: lastEditedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String draftType,
            Value<String?> title = const Value.absent(),
            required String content,
            Value<String?> schoolId = const Value.absent(),
            Value<String?> subjectId = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            required DateTime lastEditedAt,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalDraftsTableCompanion.insert(
            id: id,
            userId: userId,
            draftType: draftType,
            title: title,
            content: content,
            schoolId: schoolId,
            subjectId: subjectId,
            isSynced: isSynced,
            lastEditedAt: lastEditedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
        ));
}

class $$LocalDraftsTableTableFilterComposer
    extends FilterComposer<_$AppDatabase, $LocalDraftsTableTable> {
  $$LocalDraftsTableTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get userId => $state.composableBuilder(
      column: $state.table.userId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get draftType => $state.composableBuilder(
      column: $state.table.draftType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get content => $state.composableBuilder(
      column: $state.table.content,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get schoolId => $state.composableBuilder(
      column: $state.table.schoolId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get subjectId => $state.composableBuilder(
      column: $state.table.subjectId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isSynced => $state.composableBuilder(
      column: $state.table.isSynced,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get lastEditedAt => $state.composableBuilder(
      column: $state.table.lastEditedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$LocalDraftsTableTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $LocalDraftsTableTable> {
  $$LocalDraftsTableTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get userId => $state.composableBuilder(
      column: $state.table.userId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get draftType => $state.composableBuilder(
      column: $state.table.draftType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get content => $state.composableBuilder(
      column: $state.table.content,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get schoolId => $state.composableBuilder(
      column: $state.table.schoolId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get subjectId => $state.composableBuilder(
      column: $state.table.subjectId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isSynced => $state.composableBuilder(
      column: $state.table.isSynced,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get lastEditedAt => $state.composableBuilder(
      column: $state.table.lastEditedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$LocalUserDataTableTableCreateCompanionBuilder
    = LocalUserDataTableCompanion Function({
  required String id,
  required String userId,
  required String profileData,
  Value<String?> preferences,
  required String role,
  Value<String?> schoolId,
  required DateTime lastSyncedAt,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$LocalUserDataTableTableUpdateCompanionBuilder
    = LocalUserDataTableCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> profileData,
  Value<String?> preferences,
  Value<String> role,
  Value<String?> schoolId,
  Value<DateTime> lastSyncedAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$LocalUserDataTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalUserDataTableTable,
    LocalUserDataTableData,
    $$LocalUserDataTableTableFilterComposer,
    $$LocalUserDataTableTableOrderingComposer,
    $$LocalUserDataTableTableCreateCompanionBuilder,
    $$LocalUserDataTableTableUpdateCompanionBuilder> {
  $$LocalUserDataTableTableTableManager(
      _$AppDatabase db, $LocalUserDataTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$LocalUserDataTableTableFilterComposer(ComposerState(db, table)),
          orderingComposer: $$LocalUserDataTableTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> profileData = const Value.absent(),
            Value<String?> preferences = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<String?> schoolId = const Value.absent(),
            Value<DateTime> lastSyncedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalUserDataTableCompanion(
            id: id,
            userId: userId,
            profileData: profileData,
            preferences: preferences,
            role: role,
            schoolId: schoolId,
            lastSyncedAt: lastSyncedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String profileData,
            Value<String?> preferences = const Value.absent(),
            required String role,
            Value<String?> schoolId = const Value.absent(),
            required DateTime lastSyncedAt,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalUserDataTableCompanion.insert(
            id: id,
            userId: userId,
            profileData: profileData,
            preferences: preferences,
            role: role,
            schoolId: schoolId,
            lastSyncedAt: lastSyncedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
        ));
}

class $$LocalUserDataTableTableFilterComposer
    extends FilterComposer<_$AppDatabase, $LocalUserDataTableTable> {
  $$LocalUserDataTableTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get userId => $state.composableBuilder(
      column: $state.table.userId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get profileData => $state.composableBuilder(
      column: $state.table.profileData,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get preferences => $state.composableBuilder(
      column: $state.table.preferences,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get role => $state.composableBuilder(
      column: $state.table.role,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get schoolId => $state.composableBuilder(
      column: $state.table.schoolId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get lastSyncedAt => $state.composableBuilder(
      column: $state.table.lastSyncedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$LocalUserDataTableTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $LocalUserDataTableTable> {
  $$LocalUserDataTableTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get userId => $state.composableBuilder(
      column: $state.table.userId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get profileData => $state.composableBuilder(
      column: $state.table.profileData,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get preferences => $state.composableBuilder(
      column: $state.table.preferences,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get role => $state.composableBuilder(
      column: $state.table.role,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get schoolId => $state.composableBuilder(
      column: $state.table.schoolId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get lastSyncedAt => $state.composableBuilder(
      column: $state.table.lastSyncedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$LocalQuestionBankTableTableCreateCompanionBuilder
    = LocalQuestionBankTableCompanion Function({
  required String id,
  required String questionData,
  required String subjectId,
  required String classLevel,
  Value<String?> schoolId,
  Value<bool> isSynced,
  required DateTime lastModifiedAt,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$LocalQuestionBankTableTableUpdateCompanionBuilder
    = LocalQuestionBankTableCompanion Function({
  Value<String> id,
  Value<String> questionData,
  Value<String> subjectId,
  Value<String> classLevel,
  Value<String?> schoolId,
  Value<bool> isSynced,
  Value<DateTime> lastModifiedAt,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$LocalQuestionBankTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalQuestionBankTableTable,
    LocalQuestionBankTableData,
    $$LocalQuestionBankTableTableFilterComposer,
    $$LocalQuestionBankTableTableOrderingComposer,
    $$LocalQuestionBankTableTableCreateCompanionBuilder,
    $$LocalQuestionBankTableTableUpdateCompanionBuilder> {
  $$LocalQuestionBankTableTableTableManager(
      _$AppDatabase db, $LocalQuestionBankTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer: $$LocalQuestionBankTableTableFilterComposer(
              ComposerState(db, table)),
          orderingComposer: $$LocalQuestionBankTableTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> questionData = const Value.absent(),
            Value<String> subjectId = const Value.absent(),
            Value<String> classLevel = const Value.absent(),
            Value<String?> schoolId = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<DateTime> lastModifiedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalQuestionBankTableCompanion(
            id: id,
            questionData: questionData,
            subjectId: subjectId,
            classLevel: classLevel,
            schoolId: schoolId,
            isSynced: isSynced,
            lastModifiedAt: lastModifiedAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String questionData,
            required String subjectId,
            required String classLevel,
            Value<String?> schoolId = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            required DateTime lastModifiedAt,
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalQuestionBankTableCompanion.insert(
            id: id,
            questionData: questionData,
            subjectId: subjectId,
            classLevel: classLevel,
            schoolId: schoolId,
            isSynced: isSynced,
            lastModifiedAt: lastModifiedAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
        ));
}

class $$LocalQuestionBankTableTableFilterComposer
    extends FilterComposer<_$AppDatabase, $LocalQuestionBankTableTable> {
  $$LocalQuestionBankTableTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get questionData => $state.composableBuilder(
      column: $state.table.questionData,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get subjectId => $state.composableBuilder(
      column: $state.table.subjectId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get classLevel => $state.composableBuilder(
      column: $state.table.classLevel,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get schoolId => $state.composableBuilder(
      column: $state.table.schoolId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isSynced => $state.composableBuilder(
      column: $state.table.isSynced,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get lastModifiedAt => $state.composableBuilder(
      column: $state.table.lastModifiedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$LocalQuestionBankTableTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $LocalQuestionBankTableTable> {
  $$LocalQuestionBankTableTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get questionData => $state.composableBuilder(
      column: $state.table.questionData,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get subjectId => $state.composableBuilder(
      column: $state.table.subjectId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get classLevel => $state.composableBuilder(
      column: $state.table.classLevel,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get schoolId => $state.composableBuilder(
      column: $state.table.schoolId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isSynced => $state.composableBuilder(
      column: $state.table.isSynced,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get lastModifiedAt => $state.composableBuilder(
      column: $state.table.lastModifiedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$LocalResourcesTableTableCreateCompanionBuilder
    = LocalResourcesTableCompanion Function({
  required String id,
  required String userId,
  required String resourceType,
  required String resourceId,
  required String title,
  required String filePath,
  required int fileSizeBytes,
  Value<String?> mimeType,
  Value<String?> checksum,
  Value<DateTime?> licenseExpiresAt,
  Value<bool> isAvailable,
  Value<int> accessCount,
  Value<DateTime?> lastAccessedAt,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$LocalResourcesTableTableUpdateCompanionBuilder
    = LocalResourcesTableCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> resourceType,
  Value<String> resourceId,
  Value<String> title,
  Value<String> filePath,
  Value<int> fileSizeBytes,
  Value<String?> mimeType,
  Value<String?> checksum,
  Value<DateTime?> licenseExpiresAt,
  Value<bool> isAvailable,
  Value<int> accessCount,
  Value<DateTime?> lastAccessedAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$LocalResourcesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalResourcesTableTable,
    LocalResourcesTableData,
    $$LocalResourcesTableTableFilterComposer,
    $$LocalResourcesTableTableOrderingComposer,
    $$LocalResourcesTableTableCreateCompanionBuilder,
    $$LocalResourcesTableTableUpdateCompanionBuilder> {
  $$LocalResourcesTableTableTableManager(
      _$AppDatabase db, $LocalResourcesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer: $$LocalResourcesTableTableFilterComposer(
              ComposerState(db, table)),
          orderingComposer: $$LocalResourcesTableTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> resourceType = const Value.absent(),
            Value<String> resourceId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> filePath = const Value.absent(),
            Value<int> fileSizeBytes = const Value.absent(),
            Value<String?> mimeType = const Value.absent(),
            Value<String?> checksum = const Value.absent(),
            Value<DateTime?> licenseExpiresAt = const Value.absent(),
            Value<bool> isAvailable = const Value.absent(),
            Value<int> accessCount = const Value.absent(),
            Value<DateTime?> lastAccessedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalResourcesTableCompanion(
            id: id,
            userId: userId,
            resourceType: resourceType,
            resourceId: resourceId,
            title: title,
            filePath: filePath,
            fileSizeBytes: fileSizeBytes,
            mimeType: mimeType,
            checksum: checksum,
            licenseExpiresAt: licenseExpiresAt,
            isAvailable: isAvailable,
            accessCount: accessCount,
            lastAccessedAt: lastAccessedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String resourceType,
            required String resourceId,
            required String title,
            required String filePath,
            required int fileSizeBytes,
            Value<String?> mimeType = const Value.absent(),
            Value<String?> checksum = const Value.absent(),
            Value<DateTime?> licenseExpiresAt = const Value.absent(),
            Value<bool> isAvailable = const Value.absent(),
            Value<int> accessCount = const Value.absent(),
            Value<DateTime?> lastAccessedAt = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalResourcesTableCompanion.insert(
            id: id,
            userId: userId,
            resourceType: resourceType,
            resourceId: resourceId,
            title: title,
            filePath: filePath,
            fileSizeBytes: fileSizeBytes,
            mimeType: mimeType,
            checksum: checksum,
            licenseExpiresAt: licenseExpiresAt,
            isAvailable: isAvailable,
            accessCount: accessCount,
            lastAccessedAt: lastAccessedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
        ));
}

class $$LocalResourcesTableTableFilterComposer
    extends FilterComposer<_$AppDatabase, $LocalResourcesTableTable> {
  $$LocalResourcesTableTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get userId => $state.composableBuilder(
      column: $state.table.userId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get resourceType => $state.composableBuilder(
      column: $state.table.resourceType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get resourceId => $state.composableBuilder(
      column: $state.table.resourceId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get filePath => $state.composableBuilder(
      column: $state.table.filePath,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get fileSizeBytes => $state.composableBuilder(
      column: $state.table.fileSizeBytes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get mimeType => $state.composableBuilder(
      column: $state.table.mimeType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get checksum => $state.composableBuilder(
      column: $state.table.checksum,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get licenseExpiresAt => $state.composableBuilder(
      column: $state.table.licenseExpiresAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isAvailable => $state.composableBuilder(
      column: $state.table.isAvailable,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get accessCount => $state.composableBuilder(
      column: $state.table.accessCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get lastAccessedAt => $state.composableBuilder(
      column: $state.table.lastAccessedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$LocalResourcesTableTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $LocalResourcesTableTable> {
  $$LocalResourcesTableTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get userId => $state.composableBuilder(
      column: $state.table.userId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get resourceType => $state.composableBuilder(
      column: $state.table.resourceType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get resourceId => $state.composableBuilder(
      column: $state.table.resourceId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get filePath => $state.composableBuilder(
      column: $state.table.filePath,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get fileSizeBytes => $state.composableBuilder(
      column: $state.table.fileSizeBytes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get mimeType => $state.composableBuilder(
      column: $state.table.mimeType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get checksum => $state.composableBuilder(
      column: $state.table.checksum,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get licenseExpiresAt => $state.composableBuilder(
      column: $state.table.licenseExpiresAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isAvailable => $state.composableBuilder(
      column: $state.table.isAvailable,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get accessCount => $state.composableBuilder(
      column: $state.table.accessCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get lastAccessedAt => $state.composableBuilder(
      column: $state.table.lastAccessedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$LocalAnnouncementsTableTableCreateCompanionBuilder
    = LocalAnnouncementsTableCompanion Function({
  required String id,
  required String schoolId,
  required String announcementData,
  Value<bool> isRead,
  required DateTime createdAt,
  Value<DateTime?> expiresAt,
  Value<int> rowid,
});
typedef $$LocalAnnouncementsTableTableUpdateCompanionBuilder
    = LocalAnnouncementsTableCompanion Function({
  Value<String> id,
  Value<String> schoolId,
  Value<String> announcementData,
  Value<bool> isRead,
  Value<DateTime> createdAt,
  Value<DateTime?> expiresAt,
  Value<int> rowid,
});

class $$LocalAnnouncementsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalAnnouncementsTableTable,
    LocalAnnouncementsTableData,
    $$LocalAnnouncementsTableTableFilterComposer,
    $$LocalAnnouncementsTableTableOrderingComposer,
    $$LocalAnnouncementsTableTableCreateCompanionBuilder,
    $$LocalAnnouncementsTableTableUpdateCompanionBuilder> {
  $$LocalAnnouncementsTableTableTableManager(
      _$AppDatabase db, $LocalAnnouncementsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer: $$LocalAnnouncementsTableTableFilterComposer(
              ComposerState(db, table)),
          orderingComposer: $$LocalAnnouncementsTableTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> schoolId = const Value.absent(),
            Value<String> announcementData = const Value.absent(),
            Value<bool> isRead = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> expiresAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalAnnouncementsTableCompanion(
            id: id,
            schoolId: schoolId,
            announcementData: announcementData,
            isRead: isRead,
            createdAt: createdAt,
            expiresAt: expiresAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String schoolId,
            required String announcementData,
            Value<bool> isRead = const Value.absent(),
            required DateTime createdAt,
            Value<DateTime?> expiresAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalAnnouncementsTableCompanion.insert(
            id: id,
            schoolId: schoolId,
            announcementData: announcementData,
            isRead: isRead,
            createdAt: createdAt,
            expiresAt: expiresAt,
            rowid: rowid,
          ),
        ));
}

class $$LocalAnnouncementsTableTableFilterComposer
    extends FilterComposer<_$AppDatabase, $LocalAnnouncementsTableTable> {
  $$LocalAnnouncementsTableTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get schoolId => $state.composableBuilder(
      column: $state.table.schoolId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get announcementData => $state.composableBuilder(
      column: $state.table.announcementData,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isRead => $state.composableBuilder(
      column: $state.table.isRead,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get expiresAt => $state.composableBuilder(
      column: $state.table.expiresAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$LocalAnnouncementsTableTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $LocalAnnouncementsTableTable> {
  $$LocalAnnouncementsTableTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get schoolId => $state.composableBuilder(
      column: $state.table.schoolId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get announcementData => $state.composableBuilder(
      column: $state.table.announcementData,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isRead => $state.composableBuilder(
      column: $state.table.isRead,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get expiresAt => $state.composableBuilder(
      column: $state.table.expiresAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$LocalTimetableTableTableCreateCompanionBuilder
    = LocalTimetableTableCompanion Function({
  required String id,
  required String schoolId,
  Value<String?> classId,
  required String timetableData,
  required DateTime weekStart,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$LocalTimetableTableTableUpdateCompanionBuilder
    = LocalTimetableTableCompanion Function({
  Value<String> id,
  Value<String> schoolId,
  Value<String?> classId,
  Value<String> timetableData,
  Value<DateTime> weekStart,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$LocalTimetableTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalTimetableTableTable,
    LocalTimetableTableData,
    $$LocalTimetableTableTableFilterComposer,
    $$LocalTimetableTableTableOrderingComposer,
    $$LocalTimetableTableTableCreateCompanionBuilder,
    $$LocalTimetableTableTableUpdateCompanionBuilder> {
  $$LocalTimetableTableTableTableManager(
      _$AppDatabase db, $LocalTimetableTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer: $$LocalTimetableTableTableFilterComposer(
              ComposerState(db, table)),
          orderingComposer: $$LocalTimetableTableTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> schoolId = const Value.absent(),
            Value<String?> classId = const Value.absent(),
            Value<String> timetableData = const Value.absent(),
            Value<DateTime> weekStart = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalTimetableTableCompanion(
            id: id,
            schoolId: schoolId,
            classId: classId,
            timetableData: timetableData,
            weekStart: weekStart,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String schoolId,
            Value<String?> classId = const Value.absent(),
            required String timetableData,
            required DateTime weekStart,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalTimetableTableCompanion.insert(
            id: id,
            schoolId: schoolId,
            classId: classId,
            timetableData: timetableData,
            weekStart: weekStart,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
        ));
}

class $$LocalTimetableTableTableFilterComposer
    extends FilterComposer<_$AppDatabase, $LocalTimetableTableTable> {
  $$LocalTimetableTableTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get schoolId => $state.composableBuilder(
      column: $state.table.schoolId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get classId => $state.composableBuilder(
      column: $state.table.classId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get timetableData => $state.composableBuilder(
      column: $state.table.timetableData,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get weekStart => $state.composableBuilder(
      column: $state.table.weekStart,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$LocalTimetableTableTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $LocalTimetableTableTable> {
  $$LocalTimetableTableTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get schoolId => $state.composableBuilder(
      column: $state.table.schoolId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get classId => $state.composableBuilder(
      column: $state.table.classId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get timetableData => $state.composableBuilder(
      column: $state.table.timetableData,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get weekStart => $state.composableBuilder(
      column: $state.table.weekStart,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$LocalExamAttemptsTableTableCreateCompanionBuilder
    = LocalExamAttemptsTableCompanion Function({
  required String id,
  required String examId,
  required String studentId,
  Value<String?> schoolId,
  required String attemptData,
  required String answers,
  Value<bool> isEncrypted,
  required DateTime startedAt,
  Value<DateTime?> completedAt,
  Value<int> timeTakenSeconds,
  Value<String?> integrityHash,
  Value<String> syncStatus,
  Value<int> syncAttempts,
  Value<DateTime?> syncedAt,
  Value<String?> validationErrors,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$LocalExamAttemptsTableTableUpdateCompanionBuilder
    = LocalExamAttemptsTableCompanion Function({
  Value<String> id,
  Value<String> examId,
  Value<String> studentId,
  Value<String?> schoolId,
  Value<String> attemptData,
  Value<String> answers,
  Value<bool> isEncrypted,
  Value<DateTime> startedAt,
  Value<DateTime?> completedAt,
  Value<int> timeTakenSeconds,
  Value<String?> integrityHash,
  Value<String> syncStatus,
  Value<int> syncAttempts,
  Value<DateTime?> syncedAt,
  Value<String?> validationErrors,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$LocalExamAttemptsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalExamAttemptsTableTable,
    LocalExamAttemptsTableData,
    $$LocalExamAttemptsTableTableFilterComposer,
    $$LocalExamAttemptsTableTableOrderingComposer,
    $$LocalExamAttemptsTableTableCreateCompanionBuilder,
    $$LocalExamAttemptsTableTableUpdateCompanionBuilder> {
  $$LocalExamAttemptsTableTableTableManager(
      _$AppDatabase db, $LocalExamAttemptsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer: $$LocalExamAttemptsTableTableFilterComposer(
              ComposerState(db, table)),
          orderingComposer: $$LocalExamAttemptsTableTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> examId = const Value.absent(),
            Value<String> studentId = const Value.absent(),
            Value<String?> schoolId = const Value.absent(),
            Value<String> attemptData = const Value.absent(),
            Value<String> answers = const Value.absent(),
            Value<bool> isEncrypted = const Value.absent(),
            Value<DateTime> startedAt = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<int> timeTakenSeconds = const Value.absent(),
            Value<String?> integrityHash = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<int> syncAttempts = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<String?> validationErrors = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalExamAttemptsTableCompanion(
            id: id,
            examId: examId,
            studentId: studentId,
            schoolId: schoolId,
            attemptData: attemptData,
            answers: answers,
            isEncrypted: isEncrypted,
            startedAt: startedAt,
            completedAt: completedAt,
            timeTakenSeconds: timeTakenSeconds,
            integrityHash: integrityHash,
            syncStatus: syncStatus,
            syncAttempts: syncAttempts,
            syncedAt: syncedAt,
            validationErrors: validationErrors,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String examId,
            required String studentId,
            Value<String?> schoolId = const Value.absent(),
            required String attemptData,
            required String answers,
            Value<bool> isEncrypted = const Value.absent(),
            required DateTime startedAt,
            Value<DateTime?> completedAt = const Value.absent(),
            Value<int> timeTakenSeconds = const Value.absent(),
            Value<String?> integrityHash = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<int> syncAttempts = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<String?> validationErrors = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalExamAttemptsTableCompanion.insert(
            id: id,
            examId: examId,
            studentId: studentId,
            schoolId: schoolId,
            attemptData: attemptData,
            answers: answers,
            isEncrypted: isEncrypted,
            startedAt: startedAt,
            completedAt: completedAt,
            timeTakenSeconds: timeTakenSeconds,
            integrityHash: integrityHash,
            syncStatus: syncStatus,
            syncAttempts: syncAttempts,
            syncedAt: syncedAt,
            validationErrors: validationErrors,
            createdAt: createdAt,
            rowid: rowid,
          ),
        ));
}

class $$LocalExamAttemptsTableTableFilterComposer
    extends FilterComposer<_$AppDatabase, $LocalExamAttemptsTableTable> {
  $$LocalExamAttemptsTableTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get examId => $state.composableBuilder(
      column: $state.table.examId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get studentId => $state.composableBuilder(
      column: $state.table.studentId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get schoolId => $state.composableBuilder(
      column: $state.table.schoolId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get attemptData => $state.composableBuilder(
      column: $state.table.attemptData,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get answers => $state.composableBuilder(
      column: $state.table.answers,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isEncrypted => $state.composableBuilder(
      column: $state.table.isEncrypted,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get startedAt => $state.composableBuilder(
      column: $state.table.startedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get completedAt => $state.composableBuilder(
      column: $state.table.completedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get timeTakenSeconds => $state.composableBuilder(
      column: $state.table.timeTakenSeconds,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get integrityHash => $state.composableBuilder(
      column: $state.table.integrityHash,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get syncStatus => $state.composableBuilder(
      column: $state.table.syncStatus,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get syncAttempts => $state.composableBuilder(
      column: $state.table.syncAttempts,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get syncedAt => $state.composableBuilder(
      column: $state.table.syncedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get validationErrors => $state.composableBuilder(
      column: $state.table.validationErrors,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$LocalExamAttemptsTableTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $LocalExamAttemptsTableTable> {
  $$LocalExamAttemptsTableTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get examId => $state.composableBuilder(
      column: $state.table.examId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get studentId => $state.composableBuilder(
      column: $state.table.studentId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get schoolId => $state.composableBuilder(
      column: $state.table.schoolId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get attemptData => $state.composableBuilder(
      column: $state.table.attemptData,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get answers => $state.composableBuilder(
      column: $state.table.answers,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isEncrypted => $state.composableBuilder(
      column: $state.table.isEncrypted,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get startedAt => $state.composableBuilder(
      column: $state.table.startedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get completedAt => $state.composableBuilder(
      column: $state.table.completedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get timeTakenSeconds => $state.composableBuilder(
      column: $state.table.timeTakenSeconds,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get integrityHash => $state.composableBuilder(
      column: $state.table.integrityHash,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get syncStatus => $state.composableBuilder(
      column: $state.table.syncStatus,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get syncAttempts => $state.composableBuilder(
      column: $state.table.syncAttempts,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get syncedAt => $state.composableBuilder(
      column: $state.table.syncedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get validationErrors => $state.composableBuilder(
      column: $state.table.validationErrors,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$LocalNotificationsTableTableCreateCompanionBuilder
    = LocalNotificationsTableCompanion Function({
  required String id,
  required String userId,
  required String notificationData,
  required String type,
  required String title,
  Value<bool> isRead,
  required DateTime receivedAt,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$LocalNotificationsTableTableUpdateCompanionBuilder
    = LocalNotificationsTableCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> notificationData,
  Value<String> type,
  Value<String> title,
  Value<bool> isRead,
  Value<DateTime> receivedAt,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$LocalNotificationsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalNotificationsTableTable,
    LocalNotificationsTableData,
    $$LocalNotificationsTableTableFilterComposer,
    $$LocalNotificationsTableTableOrderingComposer,
    $$LocalNotificationsTableTableCreateCompanionBuilder,
    $$LocalNotificationsTableTableUpdateCompanionBuilder> {
  $$LocalNotificationsTableTableTableManager(
      _$AppDatabase db, $LocalNotificationsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer: $$LocalNotificationsTableTableFilterComposer(
              ComposerState(db, table)),
          orderingComposer: $$LocalNotificationsTableTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> notificationData = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<bool> isRead = const Value.absent(),
            Value<DateTime> receivedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalNotificationsTableCompanion(
            id: id,
            userId: userId,
            notificationData: notificationData,
            type: type,
            title: title,
            isRead: isRead,
            receivedAt: receivedAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String notificationData,
            required String type,
            required String title,
            Value<bool> isRead = const Value.absent(),
            required DateTime receivedAt,
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalNotificationsTableCompanion.insert(
            id: id,
            userId: userId,
            notificationData: notificationData,
            type: type,
            title: title,
            isRead: isRead,
            receivedAt: receivedAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
        ));
}

class $$LocalNotificationsTableTableFilterComposer
    extends FilterComposer<_$AppDatabase, $LocalNotificationsTableTable> {
  $$LocalNotificationsTableTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get userId => $state.composableBuilder(
      column: $state.table.userId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get notificationData => $state.composableBuilder(
      column: $state.table.notificationData,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isRead => $state.composableBuilder(
      column: $state.table.isRead,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get receivedAt => $state.composableBuilder(
      column: $state.table.receivedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$LocalNotificationsTableTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $LocalNotificationsTableTable> {
  $$LocalNotificationsTableTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get userId => $state.composableBuilder(
      column: $state.table.userId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get notificationData => $state.composableBuilder(
      column: $state.table.notificationData,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isRead => $state.composableBuilder(
      column: $state.table.isRead,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get receivedAt => $state.composableBuilder(
      column: $state.table.receivedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$ConnectivityLogsTableTableCreateCompanionBuilder
    = ConnectivityLogsTableCompanion Function({
  required String id,
  required String connectionType,
  required String connectionQuality,
  Value<int?> latencyMs,
  Value<int?> bandwidthKbps,
  required bool wasOffline,
  Value<int?> offlineDurationSeconds,
  required DateTime recordedAt,
  Value<int> rowid,
});
typedef $$ConnectivityLogsTableTableUpdateCompanionBuilder
    = ConnectivityLogsTableCompanion Function({
  Value<String> id,
  Value<String> connectionType,
  Value<String> connectionQuality,
  Value<int?> latencyMs,
  Value<int?> bandwidthKbps,
  Value<bool> wasOffline,
  Value<int?> offlineDurationSeconds,
  Value<DateTime> recordedAt,
  Value<int> rowid,
});

class $$ConnectivityLogsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ConnectivityLogsTableTable,
    ConnectivityLogsTableData,
    $$ConnectivityLogsTableTableFilterComposer,
    $$ConnectivityLogsTableTableOrderingComposer,
    $$ConnectivityLogsTableTableCreateCompanionBuilder,
    $$ConnectivityLogsTableTableUpdateCompanionBuilder> {
  $$ConnectivityLogsTableTableTableManager(
      _$AppDatabase db, $ConnectivityLogsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer: $$ConnectivityLogsTableTableFilterComposer(
              ComposerState(db, table)),
          orderingComposer: $$ConnectivityLogsTableTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> connectionType = const Value.absent(),
            Value<String> connectionQuality = const Value.absent(),
            Value<int?> latencyMs = const Value.absent(),
            Value<int?> bandwidthKbps = const Value.absent(),
            Value<bool> wasOffline = const Value.absent(),
            Value<int?> offlineDurationSeconds = const Value.absent(),
            Value<DateTime> recordedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ConnectivityLogsTableCompanion(
            id: id,
            connectionType: connectionType,
            connectionQuality: connectionQuality,
            latencyMs: latencyMs,
            bandwidthKbps: bandwidthKbps,
            wasOffline: wasOffline,
            offlineDurationSeconds: offlineDurationSeconds,
            recordedAt: recordedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String connectionType,
            required String connectionQuality,
            Value<int?> latencyMs = const Value.absent(),
            Value<int?> bandwidthKbps = const Value.absent(),
            required bool wasOffline,
            Value<int?> offlineDurationSeconds = const Value.absent(),
            required DateTime recordedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ConnectivityLogsTableCompanion.insert(
            id: id,
            connectionType: connectionType,
            connectionQuality: connectionQuality,
            latencyMs: latencyMs,
            bandwidthKbps: bandwidthKbps,
            wasOffline: wasOffline,
            offlineDurationSeconds: offlineDurationSeconds,
            recordedAt: recordedAt,
            rowid: rowid,
          ),
        ));
}

class $$ConnectivityLogsTableTableFilterComposer
    extends FilterComposer<_$AppDatabase, $ConnectivityLogsTableTable> {
  $$ConnectivityLogsTableTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get connectionType => $state.composableBuilder(
      column: $state.table.connectionType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get connectionQuality => $state.composableBuilder(
      column: $state.table.connectionQuality,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get latencyMs => $state.composableBuilder(
      column: $state.table.latencyMs,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get bandwidthKbps => $state.composableBuilder(
      column: $state.table.bandwidthKbps,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get wasOffline => $state.composableBuilder(
      column: $state.table.wasOffline,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get offlineDurationSeconds => $state.composableBuilder(
      column: $state.table.offlineDurationSeconds,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get recordedAt => $state.composableBuilder(
      column: $state.table.recordedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$ConnectivityLogsTableTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $ConnectivityLogsTableTable> {
  $$ConnectivityLogsTableTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get connectionType => $state.composableBuilder(
      column: $state.table.connectionType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get connectionQuality => $state.composableBuilder(
      column: $state.table.connectionQuality,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get latencyMs => $state.composableBuilder(
      column: $state.table.latencyMs,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get bandwidthKbps => $state.composableBuilder(
      column: $state.table.bandwidthKbps,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get wasOffline => $state.composableBuilder(
      column: $state.table.wasOffline,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get offlineDurationSeconds => $state.composableBuilder(
      column: $state.table.offlineDurationSeconds,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get recordedAt => $state.composableBuilder(
      column: $state.table.recordedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$LocalSyncMetadataTableTableCreateCompanionBuilder
    = LocalSyncMetadataTableCompanion Function({
  required String id,
  required String userId,
  required String targetTable,
  Value<DateTime?> lastSyncedAt,
  Value<String?> syncCursor,
  Value<int> recordCount,
  Value<String?> checksum,
  Value<bool> isFullSync,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$LocalSyncMetadataTableTableUpdateCompanionBuilder
    = LocalSyncMetadataTableCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> targetTable,
  Value<DateTime?> lastSyncedAt,
  Value<String?> syncCursor,
  Value<int> recordCount,
  Value<String?> checksum,
  Value<bool> isFullSync,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$LocalSyncMetadataTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalSyncMetadataTableTable,
    LocalSyncMetadataTableData,
    $$LocalSyncMetadataTableTableFilterComposer,
    $$LocalSyncMetadataTableTableOrderingComposer,
    $$LocalSyncMetadataTableTableCreateCompanionBuilder,
    $$LocalSyncMetadataTableTableUpdateCompanionBuilder> {
  $$LocalSyncMetadataTableTableTableManager(
      _$AppDatabase db, $LocalSyncMetadataTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer: $$LocalSyncMetadataTableTableFilterComposer(
              ComposerState(db, table)),
          orderingComposer: $$LocalSyncMetadataTableTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> targetTable = const Value.absent(),
            Value<DateTime?> lastSyncedAt = const Value.absent(),
            Value<String?> syncCursor = const Value.absent(),
            Value<int> recordCount = const Value.absent(),
            Value<String?> checksum = const Value.absent(),
            Value<bool> isFullSync = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalSyncMetadataTableCompanion(
            id: id,
            userId: userId,
            targetTable: targetTable,
            lastSyncedAt: lastSyncedAt,
            syncCursor: syncCursor,
            recordCount: recordCount,
            checksum: checksum,
            isFullSync: isFullSync,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String targetTable,
            Value<DateTime?> lastSyncedAt = const Value.absent(),
            Value<String?> syncCursor = const Value.absent(),
            Value<int> recordCount = const Value.absent(),
            Value<String?> checksum = const Value.absent(),
            Value<bool> isFullSync = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalSyncMetadataTableCompanion.insert(
            id: id,
            userId: userId,
            targetTable: targetTable,
            lastSyncedAt: lastSyncedAt,
            syncCursor: syncCursor,
            recordCount: recordCount,
            checksum: checksum,
            isFullSync: isFullSync,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
        ));
}

class $$LocalSyncMetadataTableTableFilterComposer
    extends FilterComposer<_$AppDatabase, $LocalSyncMetadataTableTable> {
  $$LocalSyncMetadataTableTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get userId => $state.composableBuilder(
      column: $state.table.userId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get targetTable => $state.composableBuilder(
      column: $state.table.targetTable,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get lastSyncedAt => $state.composableBuilder(
      column: $state.table.lastSyncedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get syncCursor => $state.composableBuilder(
      column: $state.table.syncCursor,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get recordCount => $state.composableBuilder(
      column: $state.table.recordCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get checksum => $state.composableBuilder(
      column: $state.table.checksum,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isFullSync => $state.composableBuilder(
      column: $state.table.isFullSync,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$LocalSyncMetadataTableTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $LocalSyncMetadataTableTable> {
  $$LocalSyncMetadataTableTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get userId => $state.composableBuilder(
      column: $state.table.userId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get targetTable => $state.composableBuilder(
      column: $state.table.targetTable,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get lastSyncedAt => $state.composableBuilder(
      column: $state.table.lastSyncedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get syncCursor => $state.composableBuilder(
      column: $state.table.syncCursor,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get recordCount => $state.composableBuilder(
      column: $state.table.recordCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get checksum => $state.composableBuilder(
      column: $state.table.checksum,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isFullSync => $state.composableBuilder(
      column: $state.table.isFullSync,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalSyncQueueTableTableTableManager get localSyncQueueTable =>
      $$LocalSyncQueueTableTableTableManager(_db, _db.localSyncQueueTable);
  $$LocalCacheTableTableTableManager get localCacheTable =>
      $$LocalCacheTableTableTableManager(_db, _db.localCacheTable);
  $$LocalDraftsTableTableTableManager get localDraftsTable =>
      $$LocalDraftsTableTableTableManager(_db, _db.localDraftsTable);
  $$LocalUserDataTableTableTableManager get localUserDataTable =>
      $$LocalUserDataTableTableTableManager(_db, _db.localUserDataTable);
  $$LocalQuestionBankTableTableTableManager get localQuestionBankTable =>
      $$LocalQuestionBankTableTableTableManager(
          _db, _db.localQuestionBankTable);
  $$LocalResourcesTableTableTableManager get localResourcesTable =>
      $$LocalResourcesTableTableTableManager(_db, _db.localResourcesTable);
  $$LocalAnnouncementsTableTableTableManager get localAnnouncementsTable =>
      $$LocalAnnouncementsTableTableTableManager(
          _db, _db.localAnnouncementsTable);
  $$LocalTimetableTableTableTableManager get localTimetableTable =>
      $$LocalTimetableTableTableTableManager(_db, _db.localTimetableTable);
  $$LocalExamAttemptsTableTableTableManager get localExamAttemptsTable =>
      $$LocalExamAttemptsTableTableTableManager(
          _db, _db.localExamAttemptsTable);
  $$LocalNotificationsTableTableTableManager get localNotificationsTable =>
      $$LocalNotificationsTableTableTableManager(
          _db, _db.localNotificationsTable);
  $$ConnectivityLogsTableTableTableManager get connectivityLogsTable =>
      $$ConnectivityLogsTableTableTableManager(_db, _db.connectivityLogsTable);
  $$LocalSyncMetadataTableTableTableManager get localSyncMetadataTable =>
      $$LocalSyncMetadataTableTableTableManager(
          _db, _db.localSyncMetadataTable);
}
