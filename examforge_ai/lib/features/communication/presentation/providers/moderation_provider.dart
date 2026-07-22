import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/communication_entities.dart';
import '../../domain/usecases/archive_conversation_usecase.dart';
import '../../domain/usecases/get_audit_logs_usecase.dart';
import '../../domain/usecases/mute_conversation_usecase.dart';
import '../../domain/usecases/report_message_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// MODERATION STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the moderation feature.
///
/// Tracks audit logs, loading and reporting flags, error message,
/// and success message.
class ModerationState {
  const ModerationState({
    this.auditLogs = const [],
    this.isLoading = false,
    this.isReporting = false,
    this.error,
    this.successMessage,
  });

  /// The list of communication audit logs.
  final List<CommunicationAuditLogEntity> auditLogs;

  /// Whether a load operation is in progress.
  final bool isLoading;

  /// Whether a report operation is in progress.
  final bool isReporting;

  /// The most recent error message, or `null`.
  final String? error;

  /// A transient success message (e.g. "Message reported"), or `null`.
  final String? successMessage;

  /// Creates a copy of this state with the given fields replaced.
  ModerationState copyWith({
    List<CommunicationAuditLogEntity>? auditLogs,
    bool? isLoading,
    bool? isReporting,
    String? error,
    String? successMessage,
  }) {
    return ModerationState(
      auditLogs: auditLogs ?? this.auditLogs,
      isLoading: isLoading ?? this.isLoading,
      isReporting: isReporting ?? this.isReporting,
      error: error,
      successMessage: successMessage,
    );
  }

  /// Clears the current error message.
  ModerationState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// MODERATION NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the moderation feature's state.
///
/// All moderation operations flow through this notifier, which:
/// 1. Sets the appropriate loading flag before each async operation
/// 2. Delegates to the relevant use case
/// 3. Updates audit logs and metadata on success
/// 4. Sets [error] on failure
class ModerationNotifier extends StateNotifier<ModerationState> {
  ModerationNotifier({
    required ReportMessageUseCase reportMessageUseCase,
    required MuteConversationUseCase muteConversationUseCase,
    required ArchiveConversationUseCase archiveConversationUseCase,
    required GetAuditLogsUseCase getAuditLogsUseCase,
  })  : _reportMessageUseCase = reportMessageUseCase,
        _muteConversationUseCase = muteConversationUseCase,
        _archiveConversationUseCase = archiveConversationUseCase,
        _getAuditLogsUseCase = getAuditLogsUseCase,
        super(const ModerationState());

  final ReportMessageUseCase _reportMessageUseCase;
  final MuteConversationUseCase _muteConversationUseCase;
  final ArchiveConversationUseCase _archiveConversationUseCase;
  final GetAuditLogsUseCase _getAuditLogsUseCase;

  // ─── Report Message ─────────────────────────────────────────────────

  /// Reports a message with the provided [params].
  Future<void> reportMessage(ReportMessageParams params) async {
    state = state.copyWith(isReporting: true, error: null);

    final result = await _reportMessageUseCase(params);

    result.fold(
      onSuccess: (_) {
        state = state.copyWith(
          isReporting: false,
          successMessage: 'Message reported successfully',
          error: null,
        );
        AppLogger.info('Message reported: ${params.messageId}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isReporting: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to report message: $failure');
      },
    );
  }

  // ─── Mute Conversation ─────────────────────────────────────────────

  /// Mutes the conversation with the given [id].
  Future<void> muteConversation(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _muteConversationUseCase(
      MuteConversationParams(conversationId: id),
    );

    result.fold(
      onSuccess: (_) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Conversation muted successfully',
          error: null,
        );
        AppLogger.info('Conversation muted: $id');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to mute conversation: $failure');
      },
    );
  }

  // ─── Archive Conversation ──────────────────────────────────────────

  /// Archives the conversation with the given [id].
  Future<void> archiveConversation(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _archiveConversationUseCase(
      ArchiveConversationParams(conversationId: id),
    );

    result.fold(
      onSuccess: (_) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Conversation archived successfully',
          error: null,
        );
        AppLogger.info('Conversation archived: $id');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to archive conversation: $failure');
      },
    );
  }

  // ─── Load Audit Logs ───────────────────────────────────────────────

  /// Loads the audit logs with the provided [params].
  Future<void> loadAuditLogs(GetAuditLogsParams params) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getAuditLogsUseCase(params);

    result.fold(
      onSuccess: (logs) {
        state = state.copyWith(
          isLoading: false,
          auditLogs: logs,
          error: null,
        );
        AppLogger.info('Audit logs loaded (${logs.length} entries)');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load audit logs: $failure');
      },
    );
  }

  // ─── Clear Error ───────────────────────────────────────────────────

  /// Clears the current error message from the state.
  void clearError() {
    state = state.clearError();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Maps a [Failure] to a user-friendly error message.
  String _mapFailureToMessage(Failure failure) {
    return failure.when(
      server: (message, _, __) => message,
      cache: (message) => message,
      auth: (message, _) => message,
      network: (message) => message,
      validation: (message, _) => message,
      notFound: (message) => message,
      unauthorized: (message) => message,
      forbidden: (message) => message,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// MODERATION PROVIDER
// ═══════════════════════════════════════════════════════════════════════

final moderationProvider =
    StateNotifierProvider<ModerationNotifier, ModerationState>((ref) {
  return ModerationNotifier(
    reportMessageUseCase: ref.watch(reportMessageUseCaseProvider),
    muteConversationUseCase: ref.watch(muteConversationUseCaseProvider),
    archiveConversationUseCase: ref.watch(archiveConversationUseCaseProvider),
    getAuditLogsUseCase: ref.watch(communicationGetAuditLogsUseCaseProvider),
  );
});
