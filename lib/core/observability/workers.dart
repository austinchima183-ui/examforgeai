// ============================================================================
// ExamForge AI — Background Worker Monitoring
// ============================================================================
//
// Monitors background workers for:
//   - Queue size
//   - Worker status (idle, running, errored, dead)
//   - Retry count
//   - Failures
//   - Dead-letter queue
//   - Long-running jobs
//   - Cancelled jobs
//   - Average execution time
//
// ROOT CAUSE: The project has a sync engine with a persistent queue but
// no worker monitoring. Failed background operations are invisible in
// production. This module provides full worker observability.
// ============================================================================

import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/structured_logger.dart';

// ═══════════════════════════════════════════════════════════════════════════
// WORKER STATUS
// ═══════════════════════════════════════════════════════════════════════════

/// Status of a background worker.
enum WorkerStatus {
  idle('idle'),
  running('running'),
  errored('errored'),
  dead('dead');

  const WorkerStatus(this.label);
  final String label;
}

// ═════────────────────────────────────────────────────────────────────────────
// JOB STATUS
// ═════────────────────────────────────────────────────────────────────────────

/// Status of a background job.
enum JobStatus {
  queued('queued'),
  running('running'),
  completed('completed'),
  failed('failed'),
  cancelled('cancelled'),
  deadLetter('dead_letter');

  const JobStatus(this.label);
  final String label;
}

// ═══════════════════════════════════════════════════════════════════════════
// JOB INFO
// ═══════════════════════════════════════════════════════════════════════════

/// Information about a background job.
class JobInfo {
  JobInfo({
    required this.id,
    required this.type,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.retryCount,
    this.error,
    this.durationMs,
    this.metadata,
  });

  final String id;
  final String type;
  JobStatus status;
  final DateTime createdAt;
  DateTime? startedAt;
  DateTime? completedAt;
  int? retryCount;
  String? error;
  double? durationMs;
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'status': status.label,
    'created_at': createdAt.toUtc().toIso8601String(),
    if (startedAt != null) 'started_at': startedAt!.toUtc().toIso8601String(),
    if (completedAt != null) 'completed_at': completedAt!.toUtc().toIso8601String(),
    if (retryCount != null) 'retry_count': retryCount,
    if (error != null) 'error': error,
    if (durationMs != null) 'duration_ms': durationMs!.round(),
    if (metadata != null) 'metadata': metadata,
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// WORKER STATUS INFO
// ═══════════════════════════════════════════════════════════════════════════

/// Status information for a background worker.
class WorkerStatusInfo {
  WorkerStatusInfo({
    required this.workerId,
    required this.status,
    this.currentJobId,
    this.jobsCompleted,
    this.jobsFailed,
    this.averageExecutionTimeMs,
    this.lastError,
    this.uptimeMinutes,
  });

  final String workerId;
  final WorkerStatus status;
  final String? currentJobId;
  final int? jobsCompleted;
  final int? jobsFailed;
  final double? averageExecutionTimeMs;
  final String? lastError;
  final int? uptimeMinutes;

  Map<String, dynamic> toJson() => {
    'worker_id': workerId,
    'status': status.label,
    if (currentJobId != null) 'current_job': currentJobId,
    if (jobsCompleted != null) 'jobs_completed': jobsCompleted,
    if (jobsFailed != null) 'jobs_failed': jobsFailed,
    if (averageExecutionTimeMs != null) 'avg_execution_ms': averageExecutionTimeMs!.round(),
    if (lastError != null) 'last_error': lastError,
    if (uptimeMinutes != null) 'uptime_minutes': uptimeMinutes,
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// BACKGROUND WORKER MONITOR
// ═══════════════════════════════════════════════════════════════════════════

/// Enterprise background worker monitoring service.
class BackgroundWorkerMonitor {
  BackgroundWorkerMonitor._();
  static final BackgroundWorkerMonitor instance = BackgroundWorkerMonitor._();

  final Map<String, WorkerStatusInfo> _workers = {};
  final Queue<JobInfo> _jobQueue = Queue();
  final Queue<JobInfo> _deadLetterQueue = Queue();
  final Queue<JobInfo> _longRunningJobs = Queue();
  final Map<String, int> _cancelledJobCounts = {};
  int _totalFailures = 0;
  double _averageExecutionTimeMs = 0;
  int _executionTimeSamples = 0;

  /// Register a worker.
  void registerWorker(String workerId, {WorkerStatus initialStatus = WorkerStatus.idle}) {
    _workers[workerId] = WorkerStatusInfo(
      workerId: workerId,
      status: initialStatus,
      jobsCompleted: 0,
      jobsFailed: 0,
      averageExecutionTimeMs: 0,
    );
    StructuredLogger.info('Worker registered: $workerId', metadata: {
      'status': initialStatus.label,
    });
  }

  /// Update worker status.
  void updateWorkerStatus(String workerId, WorkerStatus status, {String? currentJobId}) {
    final existing = _workers[workerId];
    if (existing != null) {
      _workers[workerId] = WorkerStatusInfo(
        workerId: workerId,
        status: status,
        currentJobId: currentJobId ?? existing.currentJobId,
        jobsCompleted: existing.jobsCompleted,
        jobsFailed: existing.jobsFailed,
        averageExecutionTimeMs: existing.averageExecutionTimeMs,
        lastError: existing.lastError,
        uptimeMinutes: existing.uptimeMinutes,
      );
    }
  }

  /// Record a job completion.
  void recordJobCompletion(String workerId, JobInfo job) {
    job.status = JobStatus.completed;
    job.completedAt = DateTime.now();
    if (job.startedAt != null) {
      job.durationMs = job.completedAt!.difference(job.startedAt!).inMilliseconds.toDouble();
      _updateAverageExecutionTime(job.durationMs!);
    }

    final worker = _workers[workerId];
    if (worker != null) {
      _workers[workerId] = WorkerStatusInfo(
        workerId: workerId,
        status: worker.status,
        jobsCompleted: (worker.jobsCompleted ?? 0) + 1,
        jobsFailed: worker.jobsFailed,
        averageExecutionTimeMs: _averageExecutionTimeMs,
        lastError: worker.lastError,
        uptimeMinutes: worker.uptimeMinutes,
      );
    }
  }

  /// Record a job failure.
  void recordJobFailure(String workerId, JobInfo job, String error) {
    job.status = JobStatus.failed;
    job.completedAt = DateTime.now();
    job.error = error;
    if (job.retryCount != null) job.retryCount = job.retryCount! + 1;
    _totalFailures++;

    // If retry count exceeds max, move to dead letter queue
    if (job.retryCount != null && job.retryCount! >= 3) {
      job.status = JobStatus.deadLetter;
      _deadLetterQueue.add(job);
      StructuredLogger.error(
        'Job moved to dead letter queue: ${job.id}',
        metadata: job.toJson(),
      );
    }

    final worker = _workers[workerId];
    if (worker != null) {
      _workers[workerId] = WorkerStatusInfo(
        workerId: workerId,
        status: WorkerStatus.errored,
        currentJobId: worker.currentJobId,
        jobsCompleted: worker.jobsCompleted,
        jobsFailed: (worker.jobsFailed ?? 0) + 1,
        averageExecutionTimeMs: worker.averageExecutionTimeMs,
        lastError: error,
        uptimeMinutes: worker.uptimeMinutes,
      );
    }
  }

  /// Record a job cancellation.
  void recordJobCancellation(String type) {
    _cancelledJobCounts[type] = (_cancelledJobCounts[type] ?? 0) + 1;
  }

  /// Record a long-running job.
  void recordLongRunningJob(JobInfo job) {
    _longRunningJobs.add(job);
    StructuredLogger.warning(
      'Long-running job detected: ${job.id} (${job.type})',
      metadata: {'duration_ms': job.durationMs?.round() ?? 0},
    );
  }

  // ─── Status Access ───────────────────────────────────────────────────

  /// Get current queue size.
  int get queueSize => _jobQueue.length;

  /// Get all registered workers.
  Map<String, WorkerStatusInfo> get workers => Map.unmodifiable(_workers);

  /// Get total retry count across all jobs.
  int get totalRetryCount => _jobQueue.fold(0, (sum, job) => sum + (job.retryCount ?? 0));

  /// Get total failures.
  int get totalFailures => _totalFailures;

  /// Get dead letter queue size.
  int get deadLetterQueueSize => _deadLetterQueue.length;

  /// Get long-running jobs.
  List<JobInfo> get longRunningJobs => List.unmodifiable(_longRunningJobs);

  /// Get cancelled job counts by type.
  Map<String, int> get cancelledJobCounts => Map.unmodifiable(_cancelledJobCounts);

  /// Get average execution time.
  double get averageExecutionTimeMs => _averageExecutionTimeMs;

  /// Get dead letter queue entries.
  List<JobInfo> get deadLetterEntries => List.unmodifiable(_deadLetterQueue);

  // ─── Private Helpers ─────────────────────────────────────────────────

  void _updateAverageExecutionTime(double durationMs) {
    _executionTimeSamples++;
    _averageExecutionTimeMs = _averageExecutionTimeMs +
        (durationMs - _averageExecutionTimeMs) / _executionTimeSamples;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// RIVERPOD PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Provider for background worker monitor instance.
final backgroundWorkerMonitorProvider = Provider<BackgroundWorkerMonitor>((ref) {
  return BackgroundWorkerMonitor.instance;
});

/// Provider for worker status summary.
final workerStatusSummaryProvider = Provider<Map<String, dynamic>>((ref) {
  final monitor = ref.watch(backgroundWorkerMonitorProvider);
  return {
    'worker_count': monitor.workers.length,
    'queue_size': monitor.queueSize,
    'total_failures': monitor.totalFailures,
    'dead_letter_count': monitor.deadLetterQueueSize,
    'avg_execution_ms': monitor.averageExecutionTimeMs.round(),
    'workers': monitor.workers.map((k, v) => MapEntry(k, v.toJson())),
  };
});
