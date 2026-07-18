import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/logger.dart';
import '../../domain/entities/workspace_expansion_entities.dart';

// ═══════════════════════════════════════════════════════════════════════
// COMMUNICATION STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the communication feature.
class CommunicationState {
  const CommunicationState({
    this.communications = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isCreating = false,
    this.isUpdating = false,
    this.isDeleting = false,
    this.isGenerating = false,
    this.error,
    this.currentCommunication,
    this.totalCount = 0,
    this.currentPage = 1,
    this.hasMore = true,
    this.successMessage,
  });

  /// The current page of communications.
  final List<CommunicationEntity> communications;

  /// Whether the initial page load is in progress.
  final bool isLoading;

  /// Whether a pagination (load-more) request is in progress.
  final bool isLoadingMore;

  /// Whether a create operation is in progress.
  final bool isCreating;

  /// Whether an update operation is in progress.
  final bool isUpdating;

  /// Whether a delete operation is in progress.
  final bool isDeleting;

  /// Whether an AI generation operation is in progress.
  final bool isGenerating;

  /// The most recent error message, or `null`.
  final String? error;

  /// The currently selected communication with full details, or `null`.
  final CommunicationEntity? currentCommunication;

  /// Total number of communications matching the current filter.
  final int totalCount;

  /// The current page number (1-based).
  final int currentPage;

  /// Whether there are more pages to load.
  final bool hasMore;

  /// A transient success message, or `null`.
  final String? successMessage;

  /// Whether any async operation is in progress.
  bool get isBusy =>
      isLoading || isLoadingMore || isCreating || isUpdating || isDeleting || isGenerating;

  /// Creates a copy of this state with the given fields replaced.
  CommunicationState copyWith({
    List<CommunicationEntity>? communications,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isCreating,
    bool? isUpdating,
    bool? isDeleting,
    bool? isGenerating,
    String? error,
    CommunicationEntity? currentCommunication,
    int? totalCount,
    int? currentPage,
    bool? hasMore,
    String? successMessage,
  }) {
    return CommunicationState(
      communications: communications ?? this.communications,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isCreating: isCreating ?? this.isCreating,
      isUpdating: isUpdating ?? this.isUpdating,
      isDeleting: isDeleting ?? this.isDeleting,
      isGenerating: isGenerating ?? this.isGenerating,
      error: error,
      currentCommunication: currentCommunication ?? this.currentCommunication,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      successMessage: successMessage,
    );
  }

  /// Clears the current error message.
  CommunicationState clearError() => copyWith(error: null);

  /// Clears the current success message.
  CommunicationState clearSuccessMessage() => copyWith(successMessage: null);
}

// ═══════════════════════════════════════════════════════════════════════
// COMMUNICATION NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the communication feature's state.
class CommunicationNotifier extends StateNotifier<CommunicationState> {
  CommunicationNotifier() : super(const CommunicationState());

  // ─── Load Communications ────────────────────────────────────────────

  /// Loads the first page of communications.
  Future<void> loadCommunications() async {
    state = state.copyWith(isLoading: true, error: null);

    // TODO: Replace with actual use case call
    await Future.delayed(const Duration(milliseconds: 500));

    state = state.copyWith(
      isLoading: false,
      communications: [],
      currentPage: 1,
      hasMore: false,
      error: null,
    );
    AppLogger.info('Loaded communications (page 1)');
  }

  // ─── Generate Communication (AI) ────────────────────────────────────

  /// Generates a communication using AI with the provided parameters.
  Future<void> generateCommunication({
    required CommunicationType communicationType,
    required CommunicationTone tone,
    required String recipientType,
    String? subject,
    String? className,
    required String purpose,
    String? customInstructions,
  }) async {
    state = state.copyWith(isGenerating: true, error: null);

    // TODO: Replace with actual AI generation use case call
    await Future.delayed(const Duration(seconds: 3));

    final now = DateTime.now();
    final title = _generateTitle(communicationType, purpose);
    final content = _generateContent(communicationType, tone, recipientType, purpose);

    final communication = CommunicationEntity(
      id: 'gen_${now.millisecondsSinceEpoch}',
      teacherId: 'current_teacher',
      title: title,
      content: content,
      communicationType: communicationType,
      tone: tone,
      recipientType: recipientType,
      purpose: purpose,
      customInstructions: customInstructions,
      isAiGenerated: true,
      isDraft: true,
      isSent: false,
      createdAt: now,
      updatedAt: now,
    );

    state = state.copyWith(
      isGenerating: false,
      currentCommunication: communication,
      successMessage: 'Communication generated successfully',
      error: null,
    );
    AppLogger.info('Communication generated: ${communication.id}');
  }

  // ─── Save Communication ─────────────────────────────────────────────

  /// Saves a communication (as draft).
  Future<void> saveCommunication(CommunicationEntity communication, {required bool isDraft}) async {
    state = state.copyWith(isCreating: true, error: null);

    // TODO: Replace with actual create use case call
    await Future.delayed(const Duration(milliseconds: 300));

    final savedCommunication = communication.copyWith(
      isDraft: isDraft,
      isSent: !isDraft,
    );

    final updatedList = [savedCommunication, ...state.communications];

    state = state.copyWith(
      isCreating: false,
      communications: updatedList,
      currentCommunication: savedCommunication,
      successMessage: isDraft ? 'Communication saved as draft' : 'Communication saved',
      error: null,
    );
    AppLogger.info('Communication saved: ${communication.id}');
  }

  // ─── Send Communication ─────────────────────────────────────────────

  /// Sends a communication.
  Future<void> sendCommunication(CommunicationEntity communication) async {
    state = state.copyWith(isUpdating: true, error: null);

    // TODO: Replace with actual send use case call
    await Future.delayed(const Duration(milliseconds: 500));

    final sentCommunication = communication.copyWith(
      isDraft: false,
      isSent: true,
      sentAt: DateTime.now(),
    );

    state = state.copyWith(
      isUpdating: false,
      currentCommunication: sentCommunication,
      successMessage: 'Communication sent successfully',
      error: null,
    );
    AppLogger.info('Communication sent: ${communication.id}');
  }

  // ─── Delete Communication ───────────────────────────────────────────

  /// Deletes a communication by [communicationId].
  Future<void> deleteCommunication(String communicationId) async {
    state = state.copyWith(isDeleting: true, error: null);

    // TODO: Replace with actual delete use case call
    await Future.delayed(const Duration(milliseconds: 300));

    final updatedList = state.communications
        .where((c) => c.id != communicationId)
        .toList();

    state = state.copyWith(
      isDeleting: false,
      communications: updatedList,
      currentCommunication: state.currentCommunication?.id == communicationId
          ? null
          : state.currentCommunication,
      successMessage: 'Communication deleted successfully',
      error: null,
    );
    AppLogger.info('Communication deleted: $communicationId');
  }

  // ─── Set Current Communication ──────────────────────────────────────

  /// Sets the currently selected communication.
  void setCurrentCommunication(CommunicationEntity? communication) {
    state = state.copyWith(currentCommunication: communication);
  }

  // ─── Clear Error / Success ──────────────────────────────────────────

  void clearError() => state = state.clearError();
  void clearSuccessMessage() => state = state.clearSuccessMessage();

  // ─── Private Helpers ────────────────────────────────────────────────

  String _generateTitle(CommunicationType type, String purpose) {
    switch (type) {
      case CommunicationType.parentLetter:
        return 'Parent Letter: $purpose';
      case CommunicationType.studentFeedback:
        return 'Student Feedback: $purpose';
      case CommunicationType.email:
        return 'Email: $purpose';
      case CommunicationType.sms:
        return 'SMS: $purpose';
      case CommunicationType.announcement:
        return 'Announcement: $purpose';
      case CommunicationType.meetingInvitation:
        return 'Meeting Invitation: $purpose';
      case CommunicationType.permissionLetter:
        return 'Permission Letter: $purpose';
      case CommunicationType.certificate:
        return 'Certificate: $purpose';
    }
  }

  String _generateContent(
    CommunicationType type,
    CommunicationTone tone,
    String recipientType,
    String purpose,
  ) {
    final greeting = _getGreeting(tone, recipientType);
    final closing = _getClosing(tone);

    return '$greeting\n\n'
        'This communication is regarding $purpose. '
        'The content has been generated by AI with a ${tone.label.toLowerCase()} tone '
        'for $recipientType recipients.\n\n'
        'Please review and customize this content before sending.\n\n'
        '$closing';
  }

  String _getGreeting(CommunicationTone tone, String recipientType) {
    switch (tone) {
      case CommunicationTone.formal:
        return 'Dear $recipientType,';
      case CommunicationTone.friendly:
        return 'Hello $recipientType!';
      case CommunicationTone.encouraging:
        return 'Dear wonderful $recipientType,';
      case CommunicationTone.professional:
        return 'Good day $recipientType,';
    }
  }

  String _getClosing(CommunicationTone tone) {
    switch (tone) {
      case CommunicationTone.formal:
        return 'Yours sincerely,\n[Teacher Name]';
      case CommunicationTone.friendly:
        return 'Best wishes,\n[Teacher Name]';
      case CommunicationTone.encouraging:
        return 'Warm regards,\n[Teacher Name]';
      case CommunicationTone.professional:
        return 'Kind regards,\n[Teacher Name]';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// COMMUNICATION PROVIDER
// ═══════════════════════════════════════════════════════════════════════

final communicationProvider =
    StateNotifierProvider<CommunicationNotifier, CommunicationState>((ref) {
  return CommunicationNotifier();
});
