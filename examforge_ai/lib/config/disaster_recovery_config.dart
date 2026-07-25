// ============================================================================
// ExamForge AI — Disaster Recovery Configuration
// ============================================================================
//
// Defines RPO (Recovery Point Objective), RTO (Recovery Time Objective),
// backup strategies, restore procedures, and incident response playbooks
// as code-level constants and structured data. This is the application-side
// companion to the infra/terraform and scripts/backup_dr.sh infrastructure.
//
// ROOT CAUSE: The project has shell scripts for backup and DR (backup.sh,
// backup_dr.sh) and Terraform for infrastructure, but NO application-level
// disaster recovery configuration. The app doesn't know its own RPO/RTO
// targets, doesn't track backup status, and has no automated recovery
// triggers. If a disaster occurs, the app will just fail without
// understanding what recovery steps are available or expected.
//
// This module provides:
//   - RPO/RTO targets as typed constants (not scattered in docs)
//   - Backup strategy definitions with schedule and retention
//   - Recovery priority order (which services restore first)
//   - Incident severity classification
//   - Escalation timelines
//   - Recovery verification checklist
//
// SECURITY: No secrets or credentials in this file. Only targets,
// schedules, and procedure references.
// ============================================================================

import '../core/logging/structured_logger.dart';

// ═══════════════════════════════════════════════════════════════════════════
// RPO / RTO TARGETS
// ═══════════════════════════════════════════════════════════════════════════

/// Recovery Point Objective — maximum tolerable data loss duration.
///
/// Evidence from scripts/backup_dr.sh: The DR script targets RPO of 1 hour
/// (hourly automated backups with S3 upload). This means in a worst-case
/// disaster, at most 1 hour of data could be lost.
class RecoveryPointObjective {
  RecoveryPointObjective._();

  /// Primary database: hourly backups → max 1 hour data loss.
  static const Duration database = Duration(hours: 1);

  /// Storage (images, documents): daily backups → max 24 hours data loss.
  /// Images and documents are less critical than transaction data.
  static const Duration storage = Duration(hours: 24);

  /// Configuration (RLS policies, edge functions): daily backups.
  static const Duration configuration = Duration(hours: 24);

  /// Sync queue (offline mutations): max 1 hour of queued changes.
  /// Sync queue items have persistent storage via Drift + AES-256-GCM.
  static const Duration syncQueue = Duration(hours: 1);

  /// Exam sessions in progress: 0 data loss target (local encrypted backup).
  /// SessionRecoveryService saves state every 30s to encrypted local storage.
  static const Duration examSessions = Duration.zero;
}

/// Recovery Time Objective — maximum tolerable downtime duration.
///
/// Evidence from scripts/backup_dr.sh: RTO target is 4 hours, which
/// includes: detection (15min), assessment (30min), restore (1-2hr),
/// verification (30min), and cleanup (30min).
class RecoveryTimeObjective {
  RecoveryTimeObjective._();

  /// Full system recovery: 4 hours from detection to full service.
  static const Duration fullSystem = Duration(hours: 4);

  /// Database-only recovery: 2 hours (fastest path).
  static const Duration databaseOnly = Duration(hours: 2);

  /// Authentication recovery: 1 hour (Supabase Auth has built-in HA).
  static const Duration authOnly = Duration(hours: 1);

  /// Storage recovery: 3 hours (S3 restore + CDN cache warm).
  static const Duration storageOnly = Duration(hours: 3);

  /// Read-only mode: 30 minutes (restore DB in read-only first).
  static const Duration readOnlyMode = Duration(minutes: 30);
}

// ═══════════════════════════════════════════════════════════════════════════
// BACKUP STRATEGY
// ═══════════════════════════════════════════════════════════════════════════

/// Backup strategy definition for a specific data tier.
class BackupStrategy {
  const BackupStrategy({
    required this.tierName,
    required this.schedule,
    required this.retentionDays,
    required this.storageLocation,
    required this.encryption,
    required this.crossRegionReplication,
    required this.verificationFrequency,
    required this.rpo,
  });

  /// Name of the data tier (e.g. 'database', 'storage', 'configuration').
  final String tierName;

  /// Backup schedule (e.g. 'hourly', 'daily', 'weekly').
  final String schedule;

  /// How many days to retain backups.
  final int retentionDays;

  /// Where backups are stored (e.g. 'S3 af-south-1', 'S3 eu-west-1 DR').
  final String storageLocation;

  /// Whether backups are encrypted (AES-256-GCM via GPG in backup_dr.sh).
  final bool encryption;

  /// Whether backups are replicated to the DR region (eu-west-1).
  final bool crossRegionReplication;

  /// How often backup integrity is verified (SHA256 checksum validation).
  final String verificationFrequency;

  /// Recovery Point Objective for this tier.
  final Duration rpo;

  Map<String, dynamic> toJson() => {
    'tier': tierName,
    'schedule': schedule,
    'retention_days': retentionDays,
    'location': storageLocation,
    'encrypted': encryption,
    'cross_region': crossRegionReplication,
    'verification': verificationFrequency,
    'rpo_hours': rpo.inHours,
  };
}

/// All backup strategies for ExamForge AI.
///
/// Evidence: These strategies are implemented by scripts/backup_dr.sh
/// which performs pg_dump with GPG encryption and S3 upload, plus
/// Terraform configures cross-region replication to eu-west-1.
class ProductionBackupStrategies {
  ProductionBackupStrategies._();

  static const database = BackupStrategy(
    tierName: 'database',
    schedule: 'hourly',
    retentionDays: 30,
    storageLocation: 'S3 af-south-1 examforge-backups-production',
    encryption: true,
    crossRegionReplication: true,
    verificationFrequency: 'daily',
    rpo: RecoveryPointObjective.database,
  );

  static const storage = BackupStrategy(
    tierName: 'storage',
    schedule: 'daily',
    retentionDays: 90,
    storageLocation: 'S3 af-south-1 examforge-backups-production',
    encryption: true,
    crossRegionReplication: true,
    verificationFrequency: 'weekly',
    rpo: RecoveryPointObjective.storage,
  );

  static const configuration = BackupStrategy(
    tierName: 'configuration',
    schedule: 'daily',
    retentionDays: 365,
    storageLocation: 'S3 af-south-1 examforge-backups-production',
    encryption: true,
    crossRegionReplication: true,
    verificationFrequency: 'weekly',
    rpo: RecoveryPointObjective.configuration,
  );

  static const syncQueue = BackupStrategy(
    tierName: 'sync_queue',
    schedule: 'continuous',
    retentionDays: 30,
    storageLocation: 'Local Drift + AES-256-GCM',
    encryption: true,
    crossRegionReplication: false,
    verificationFrequency: 'on_reconnect',
    rpo: RecoveryPointObjective.syncQueue,
  );

  static const examSessions = BackupStrategy(
    tierName: 'exam_sessions',
    schedule: 'continuous_30s',
    retentionDays: 7,
    storageLocation: 'SharedPreferences + AES-256-GCM',
    encryption: true,
    crossRegionReplication: false,
    verificationFrequency: 'on_recovery',
    rpo: RecoveryPointObjective.examSessions,
  );

  static List<BackupStrategy> get all => [
    database,
    storage,
    configuration,
    syncQueue,
    examSessions,
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
// INCIDENT SEVERITY
// ═══════════════════════════════════════════════════════════════════════════

/// Incident severity classification.
enum IncidentSeverity {
  /// Minor disruption, non-critical service affected.
  /// Examples: AI hints unavailable, push notifications delayed.
  minor('minor', Duration(minutes: 15), Duration(hours: 4)),

  /// Significant disruption, critical service degraded.
  /// Examples: Database slow queries, auth latency spike.
  major('major', Duration(minutes: 5), Duration(hours: 2)),

  /// Critical outage, core service unavailable.
  /// Examples: Database down, auth service down, payment processing failed.
  critical('critical', Duration(minutes: 2), Duration(hours: 1)),

  /// Complete system failure, all critical services down.
  /// Examples: Regional outage, data center failure, security breach.
  catastrophic('catastrophic', Duration(minutes: 1), Duration(minutes: 30));

  const IncidentSeverity(
    this.label,
    this.notificationLatency,
    this.rtoOverride,
  );

  final String label;
  /// Maximum time before the on-call team must be notified.
  final Duration notificationLatency;
  /// Override RTO for this severity (shorter than default).
  final Duration rtoOverride;
}

// ═══════════════════════════════════════════════════════════════════════════
// RECOVERY PRIORITY ORDER
// ═══════════════════════════════════════════════════════════════════════════

/// Defines the order in which services should be restored during recovery.
///
/// Evidence: Exam sessions are highest priority because in-progress exams
/// have time limits and students cannot wait. Auth must come before any
/// other service because all API calls require valid tokens. Database
/// comes next because all reads depend on it.
class RecoveryPriority {
  RecoveryPriority._();

  /// Recovery priority order from highest (restore first) to lowest.
  static const List<String> order = [
    'supabase_auth',       // 1st: Must restore auth before anything works
    'supabase_database',   // 2nd: All reads need DB access
    'cbt_exam_engine',     // 3rd: In-progress exams must continue
    'supabase_realtime',   // 4th: Live updates for monitoring
    'supabase_edge_functions', // 5th: Payment processing, AI calls
    'supabase_storage',    // 6th: File uploads/downloads
    'ai_provider',         // 7th: AI hints (non-critical)
    'notification_service', // 8th: Push notifications (non-critical)
  ];

  /// Gets the priority rank of a service (1 = highest priority).
  static int rank(String serviceName) {
    final index = order.indexOf(serviceName);
    return index >= 0 ? index + 1 : order.length + 1;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// INCIDENT RESPONSE PLAYBOOK
// ═══════════════════════════════════════════════════════════════════════════

/// A step-by-step incident response playbook for a specific scenario.
class IncidentPlaybook {
  const IncidentPlaybook({
    required this.scenario,
    required this.severity,
    required this.steps,
    required this.communicationTemplate,
    required this.verificationChecklist,
  });

  /// Name of the incident scenario.
  final String scenario;

  /// Default severity for this scenario.
  final IncidentSeverity severity;

  /// Ordered list of response steps.
  final List<PlaybookStep> steps;

  /// Template for user-facing communication.
  final String communicationTemplate;

  /// Checklist to verify recovery is complete.
  final List<String> verificationChecklist;
}

/// A single step in an incident response playbook.
class PlaybookStep {
  const PlaybookStep({
    required this.order,
    required this.action,
    required this.responsible,
    required this.maxDuration,
    required this.escalationTrigger,
  });

  final int order;
  final String action;
  final String responsible;
  final Duration maxDuration;
  final String escalationTrigger;
}

/// All incident response playbooks.
///
/// Evidence: These playbooks align with the existing operational_test.sh
/// which tests 8 scenarios: database outage, AI provider outage, payment
/// outage, storage outage, edge function failure, network interruption,
/// failed deployment, and backup restoration.
class IncidentPlaybooks {
  IncidentPlaybooks._();

  static const databaseOutage = IncidentPlaybook(
    scenario: 'Database Outage',
    severity: IncidentSeverity.critical,
    steps: [
      PlaybookStep(
        order: 1,
        action: 'Detect outage via health monitoring alert',
        responsible: 'Automated monitoring',
        maxDuration: Duration(minutes: 2),
        escalationTrigger: 'No alert received within 2 minutes',
      ),
      PlaybookStep(
        order: 2,
        action: 'Activate circuit breaker (supabase_database)',
        responsible: 'CircuitBreakerManager (automated)',
        maxDuration: Duration(seconds: 1),
        escalationTrigger: 'Circuit breaker not registered',
      ),
      PlaybookStep(
        order: 3,
        action: 'Switch to read-only mode using local Drift cache',
        responsible: 'GracefulDegradationService (automated)',
        maxDuration: Duration(seconds: 5),
        escalationTrigger: 'No local cache available',
      ),
      PlaybookStep(
        order: 4,
        action: 'Notify on-call SRE team',
        responsible: 'AlertEngine (automated)',
        maxDuration: Duration(minutes: 2),
        escalationTrigger: 'Notification delivery fails',
      ),
      PlaybookStep(
        order: 5,
        action: 'Assess: is this regional outage or application-level?',
        responsible: 'SRE team',
        maxDuration: Duration(minutes: 15),
        escalationTrigger: 'Unable to determine root cause',
      ),
      PlaybookStep(
        order: 6,
        action: 'Restore: restore from latest backup via backup_dr.sh',
        responsible: 'SRE team',
        maxDuration: Duration(hours: 1),
        escalationTrigger: 'Restore fails or checksum verification fails',
      ),
      PlaybookStep(
        order: 7,
        action: 'Verify: run health checks on restored DB',
        responsible: 'SRE team',
        maxDuration: Duration(minutes: 15),
        escalationTrigger: 'Health check fails after restore',
      ),
      PlaybookStep(
        order: 8,
        action: 'Resume normal operations, close circuit breaker',
        responsible: 'SRE team + CircuitBreakerManager',
        maxDuration: Duration(minutes: 5),
        escalationTrigger: 'Circuit does not close after 3 probe successes',
      ),
    ],
    communicationTemplate: 'ExamForge AI is experiencing a temporary database issue. '
        'Your data is safe. In-progress exams continue locally. '
        'We expect full service restoration within 2 hours.',
    verificationChecklist: [
      'Database health check returns healthy',
      'All RLS policies verified active',
      'Recent data integrity verified (last backup comparison)',
      'Circuit breaker for supabase_database is closed',
      'Health monitoring shows all components healthy',
      'Operational test suite passes',
    ],
  );

  static const authOutage = IncidentPlaybook(
    scenario: 'Authentication Service Outage',
    severity: IncidentSeverity.critical,
    steps: [
      PlaybookStep(
        order: 1,
        action: 'Detect outage via health monitoring or login failures spike',
        responsible: 'Automated monitoring + AlertEngine',
        maxDuration: Duration(minutes: 2),
        escalationTrigger: 'Alert threshold not met',
      ),
      PlaybookStep(
        order: 2,
        action: 'Activate auth circuit breaker, block new logins',
        responsible: 'CircuitBreakerManager + GracefulDegradationService',
        maxDuration: Duration(seconds: 1),
        escalationTrigger: 'Degradation service not triggered',
      ),
      PlaybookStep(
        order: 3,
        action: 'Continue existing sessions using cached JWT tokens',
        responsible: 'ApiClient (token refresh mutex)',
        maxDuration: Duration(minutes: 30),
        escalationTrigger: 'Cached tokens expire before auth recovery',
      ),
      PlaybookStep(
        order: 4,
        action: 'Notify on-call team via AlertEngine escalation',
        responsible: 'AlertEngine',
        maxDuration: Duration(minutes: 2),
        escalationTrigger: 'Escalation fails',
      ),
      PlaybookStep(
        order: 5,
        action: 'Assess Supabase Auth service status via dashboard',
        responsible: 'SRE team',
        maxDuration: Duration(minutes: 10),
        escalationTrigger: 'Cannot access Supabase dashboard',
      ),
      PlaybookStep(
        order: 6,
        action: 'Restore: Supabase Auth has built-in HA, wait for auto-recovery',
        responsible: 'Supabase infrastructure (auto)',
        maxDuration: Duration(minutes: 30),
        escalationTrigger: 'No recovery after 30 minutes',
      ),
      PlaybookStep(
        order: 7,
        action: 'Verify: test login, token refresh, session persistence',
        responsible: 'SRE team',
        maxDuration: Duration(minutes: 10),
        escalationTrigger: 'Any auth operation fails',
      ),
    ],
    communicationTemplate: 'ExamForge AI login is temporarily unavailable. '
        'If you are already logged in, your session will continue working. '
        'New logins will be available shortly.',
    verificationChecklist: [
      'Login succeeds for all 4 user roles',
      'Token refresh works for existing sessions',
      'Supabase Auth health check returns healthy',
      'Auth circuit breaker is closed',
      'Rate limiting is active and functional',
    ],
  );

  static const combinedOutage = IncidentPlaybook(
    scenario: 'Combined Database + Auth Outage',
    severity: IncidentSeverity.catastrophic,
    steps: [
      PlaybookStep(
        order: 1,
        action: 'Detect combined outage via health monitoring',
        responsible: 'HealthMonitoringService (automated)',
        maxDuration: Duration(minutes: 1),
        escalationTrigger: 'Monitoring service itself is down',
      ),
      PlaybookStep(
        order: 2,
        action: 'Activate emergency degradation level (Level 4)',
        responsible: 'GracefulDegradationService (automated)',
        maxDuration: Duration(seconds: 1),
        escalationTrigger: 'Degradation service fails',
      ),
      PlaybookStep(
        order: 3,
        action: 'Continue ONLY in-progress exams locally (encrypted session state)',
        responsible: 'SessionRecoveryService + AutoSaveService',
        maxDuration: Duration(minutes: 30),
        escalationTrigger: 'Local session data corrupted',
      ),
      PlaybookStep(
        order: 4,
        action: 'Escalate: VP Engineering notified within 30 minutes',
        responsible: 'AlertEngine (Tier 3 escalation)',
        maxDuration: Duration(minutes: 30),
        escalationTrigger: 'Escalation delivery fails',
      ),
      PlaybookStep(
        order: 5,
        action: 'Restore auth first (priority 1 per RecoveryPriority)',
        responsible: 'SRE team + Supabase',
        maxDuration: Duration(hours: 1),
        escalationTrigger: 'Auth not restored in 1 hour',
      ),
      PlaybookStep(
        order: 6,
        action: 'Restore database from latest backup (priority 2)',
        responsible: 'SRE team + backup_dr.sh',
        maxDuration: Duration(hours: 2),
        escalationTrigger: 'Database restore fails',
      ),
      PlaybookStep(
        order: 7,
        action: 'Sync queued mutations from offline clients',
        responsible: 'SyncEngine (automated on reconnect)',
        maxDuration: Duration(minutes: 30),
        escalationTrigger: 'Sync queue exceeds 10,000 items',
      ),
      PlaybookStep(
        order: 8,
        action: 'Full verification: all services operational',
        responsible: 'SRE team',
        maxDuration: Duration(minutes: 15),
        escalationTrigger: 'Any verification check fails',
      ),
    ],
    communicationTemplate: 'ExamForge AI is experiencing a major service disruption. '
        'In-progress exams will continue locally and your answers are being '
        'saved securely. We are working on restoration and expect service '
        'to resume within 4 hours. Your data is safe.',
    verificationChecklist: [
      'Both auth and database health checks return healthy',
      'Login succeeds for all roles',
      'Database queries return expected data',
      'Sync queue is empty (all mutations synced)',
      'All circuit breakers are closed',
      'Operational test suite passes',
      'Monitoring dashboard shows all services healthy',
    ],
  );

  /// All playbooks indexed by scenario name.
  static Map<String, IncidentPlaybook> get all => {
    'database_outage': databaseOutage,
    'auth_outage': authOutage,
    'combined_outage': combinedOutage,
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// DISASTER RECOVERY SERVICE
// ═══════════════════════════════════════════════════════════════════════════

/// Application-level disaster recovery coordinator.
///
/// Provides access to DR configuration, playbook retrieval, and
/// recovery verification status. Does NOT execute recovery actions
/// directly — those are handled by infrastructure scripts and the
/// circuit breaker/degradation modules.
class DisasterRecoveryService {
  DisasterRecoveryService._();
  static final DisasterRecoveryService instance = DisasterRecoveryService._();

  /// Gets all backup strategies.
  List<BackupStrategy> get backupStrategies => ProductionBackupStrategies.all;

  /// Gets the playbook for a given scenario.
  IncidentPlaybook? getPlaybook(String scenario) => IncidentPlaybooks.all[scenario];

  /// Gets all available playbooks.
  Map<String, IncidentPlaybook> get allPlaybooks => IncidentPlaybooks.all;

  /// Gets recovery priority rank for a service.
  int getRecoveryPriority(String serviceName) => RecoveryPriority.rank(serviceName);

  /// Logs DR configuration summary for observability.
  void logConfigurationSummary() {
    StructuredLogger.info(
      'DisasterRecoveryService: DR config loaded '
          'RPO=${RecoveryPointObjective.database.inHours}h '
          'RTO=${RecoveryTimeObjective.fullSystem.inHours}h '
          '${ProductionBackupStrategies.all.length} backup tiers '
          '${IncidentPlaybooks.all.length} playbooks',
      metadata: {'rpo_hours': RecoveryPointObjective.database.inHours, 'rto_hours': RecoveryTimeObjective.fullSystem.inHours},
    );

    for (final strategy in ProductionBackupStrategies.all) {
      StructuredLogger.info(
        'DisasterRecovery: Tier ${strategy.tierName} schedule=${strategy.schedule} retention=${strategy.retentionDays}d encrypted=${strategy.encryption}',
        metadata: strategy.toJson(),
      );
    }
  }
}
