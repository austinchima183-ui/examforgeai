// ============================================================================
// ExamForge AI — Production Deployment Checklist
// ============================================================================
// This file serves as the definitive pre-deployment checklist.
// Every item MUST be verified before deploying to production.
// ============================================================================

/// Production deployment checklist for ExamForge AI.
///
/// Run through every item before deploying. Any CRITICAL item that
/// is not checked must be resolved before deployment can proceed.
class DeploymentChecklist {
  DeploymentChecklist._();

  // ═══════════════════════════════════════════════════════════════════
  // CRITICAL — Must pass before ANY production deployment
  // ═══════════════════════════════════════════════════════════════════

  static const List<ChecklistItem> critical = [
    ChecklistItem(
      id: 'SEC-001',
      category: 'Security',
      description: 'All Flutterwave webhook signatures use constant-time comparison',
      verification: 'Verify FlutterwaveDataSourceImpl.verifyWebhookSignature uses _constantTimeEquals',
    ),
    ChecklistItem(
      id: 'SEC-002',
      category: 'Security',
      description: 'Payment amount verification is enabled',
      verification: 'Verify verifyTransaction() receives expectedAmount from DB',
    ),
    ChecklistItem(
      id: 'SEC-003',
      category: 'Security',
      description: 'Webhook idempotency is enabled',
      verification: 'Verify WebhookIdempotencyTracker is active in processWebhookEvent',
    ),
    ChecklistItem(
      id: 'SEC-004',
      category: 'Security',
      description: 'ApiClient auth tokens are read from secure storage',
      verification: 'Verify ApiClient is constructed with StorageService in DI',
    ),
    ChecklistItem(
      id: 'SEC-005',
      category: 'Security',
      description: 'Exam answers are encrypted at rest',
      verification: 'Verify SessionRecoveryService uses LocalEncryptionService',
    ),
    ChecklistItem(
      id: 'SEC-006',
      category: 'Security',
      description: 'Marketplace downloads use signed URLs (not direct storage paths)',
      verification: 'Verify download flow goes through Edge Function',
    ),
    ChecklistItem(
      id: 'SEC-007',
      category: 'Security',
      description: 'All RLS policies use correct role references',
      verification: 'Run rls_role_fix.sql migration and verify with SELECT * FROM pg_policies',
    ),
    ChecklistItem(
      id: 'SEC-008',
      category: 'Security',
      description: 'AI prompt injection detection is active',
      verification: 'Verify AiSecurityService.checkInput is called in PromptEngine',
    ),
    ChecklistItem(
      id: 'DB-001',
      category: 'Database',
      description: 'All SQL migrations have been applied',
      verification: 'Compare applied migrations with supabase/migrations/ directory',
    ),
    ChecklistItem(
      id: 'DB-002',
      category: 'Database',
      description: 'RLS is enabled on ALL tables',
      verification: "SELECT tablename FROM pg_tables WHERE schemaname='public' AND rowsecurity=false",
    ),
    ChecklistItem(
      id: 'PAY-001',
      category: 'Payment',
      description: 'Flutterwave webhook URL is configured to Edge Function',
      verification: 'Check Flutterwave dashboard webhook settings',
    ),
    ChecklistItem(
      id: 'PAY-002',
      category: 'Payment',
      description: 'Flutterwave webhook secret is set in environment',
      verification: 'Verify FLUTTERWAVE_WEBHOOK_SECRET_HASH is configured',
    ),
    ChecklistItem(
      id: 'PAY-003',
      category: 'Payment',
      description: 'Commission calculations are server-side only',
      verification: 'Verify marketplace_commission_rates table is populated',
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════
  // HIGH PRIORITY — Should pass before customer onboarding
  // ═══════════════════════════════════════════════════════════════════

  static const List<ChecklistItem> highPriority = [
    ChecklistItem(
      id: 'TEST-001',
      category: 'Testing',
      description: 'Security tests pass (payment, AI, encryption, auth)',
      verification: 'Run: flutter test test/security/ test/features/billing/ test/core/',
    ),
    ChecklistItem(
      id: 'TEST-002',
      category: 'Testing',
      description: 'CI/CD pipeline passes end-to-end',
      verification: 'Verify GitHub Actions workflow completes without errors',
    ),
    ChecklistItem(
      id: 'PERF-001',
      category: 'Performance',
      description: 'Dashboard loads in < 3 seconds',
      verification: 'Use Chrome DevTools Lighthouse on production build',
    ),
    ChecklistItem(
      id: 'PERF-002',
      category: 'Performance',
      description: 'CBT exam page loads in < 2 seconds',
      verification: 'Time exam start page load on 3G connection',
    ),
    ChecklistItem(
      id: 'MON-001',
      category: 'Monitoring',
      description: 'Health check endpoint is configured',
      verification: 'curl https://api.examforge.ai/health returns 200',
    ),
    ChecklistItem(
      id: 'MON-002',
      category: 'Monitoring',
      description: 'Error tracking is configured (Sentry or equivalent)',
      verification: 'Trigger a test error and verify it appears in dashboard',
    ),
    ChecklistItem(
      id: 'ENV-001',
      category: 'Environment',
      description: 'All secrets are in production environment (not .env files)',
      verification: 'Check Supabase Edge Function secrets and CI/CD variables',
    ),
    ChecklistItem(
      id: 'ENV-002',
      category: 'Environment',
      description: 'FLUTTERWAVE_SECRET_KEY is not in source code',
      verification: 'Run: gitleaks detect --source .',
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════
  // RECOMMENDED — Should be addressed for production quality
  // ═══════════════════════════════════════════════════════════════════

  static const List<ChecklistItem> recommended = [
    ChecklistItem(
      id: 'A11Y-001',
      category: 'Accessibility',
      description: 'All interactive elements have semantic labels',
      verification: 'Run Flutter accessibility checker',
    ),
    ChecklistItem(
      id: 'A11Y-002',
      category: 'Accessibility',
      description: 'Color contrast meets WCAG 2.1 AA (4.5:1 ratio)',
      verification: 'Test with accessibility scanner',
    ),
    ChecklistItem(
      id: 'BACKUP-001',
      category: 'Backup',
      description: 'Database backup schedule is configured',
      verification: 'Check Supabase dashboard for automated backups',
    ),
    ChecklistItem(
      id: 'BACKUP-002',
      category: 'Backup',
      description: 'Backup restore has been tested',
      verification: 'Restore a backup to a test environment',
    ),
    ChecklistItem(
      id: 'SCALE-001',
      category: 'Scalability',
      description: 'Load test with 1,000 concurrent users completed',
      verification: 'Run k6 or Artillery load test',
    ),
    ChecklistItem(
      id: 'DOC-001',
      category: 'Documentation',
      description: 'API documentation is up to date',
      verification: 'Review Swagger/OpenAPI spec',
    ),
  ];
}

/// A single deployment checklist item.
class ChecklistItem {
  const ChecklistItem({
    required this.id,
    required this.category,
    required this.description,
    required this.verification,
  });

  final String id;
  final String category;
  final String description;
  final String verification;
}
