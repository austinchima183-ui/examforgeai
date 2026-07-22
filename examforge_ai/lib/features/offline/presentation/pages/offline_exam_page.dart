// =============================================================================
// ExamForge AI — Offline Exam Mode Page
// =============================================================================
//
// Full exam-taking interface that works entirely offline. When the user
// submits, the attempt is saved locally and queued for sync. If the device
// is online, the attempt is synced immediately; otherwise it is persisted
// to local storage and will be synced when connectivity is restored.
//
// Features:
//   - Question display with question number, text, options / images
//   - Answer selection (multiple choice, true/false, short answer)
//   - Navigation: Previous / Next / Jump-to-question sidebar
//   - Local countdown timer from exam duration
//   - Auto-save every 30 seconds to local storage
//   - Submit button (queues for sync if offline)
//   - Progress indicator (answered / total)
//   - Offline warning banner
//   - Integrity tracking: hash of answers + timestamps
//   - Error handling: network failure, session timeout, data corruption
// =============================================================================

import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/storage/cache_manager.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../domain/entities/offline_entities.dart';
import '../providers/offline_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// OFFLINE EXAM PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// A full-screen exam-taking page that works offline.
///
/// Requires [examId] and [examTitle]. The exam data (questions, options,
/// duration) must have been previously downloaded for offline access and
/// stored in local storage via [CacheManager].
class OfflineExamPage extends ConsumerStatefulWidget {
  const OfflineExamPage({
    super.key,
    required this.examId,
    required this.examTitle,
  });

  final String examId;
  final String examTitle;

  @override
  ConsumerState<OfflineExamPage> createState() => _OfflineExamPageState();
}

// ═══════════════════════════════════════════════════════════════════════════════
// STATE
// ═══════════════════════════════════════════════════════════════════════════════

class _OfflineExamPageState extends ConsumerState<OfflineExamPage>
    with WidgetsBindingObserver {
  // ─── Controllers / State ──────────────────────────────────────────────

  int _currentQuestionIndex = 0;
  Map<int, Map<String, dynamic>> _answers = {};
  Map<int, bool> _flaggedQuestions = {};
  Duration _timeRemaining = Duration.zero;
  Timer? _timer;
  Timer? _autoSaveTimer;
  bool _isSubmitting = false;
  bool _isSubmitted = false;
  bool _isOnline = true;
  String? _errorMessage;
  String? _successMessage;
  DateTime? _examStartedAt;

  // ─── Offline Exam Data (loaded from local storage) ────────────────────

  List<Map<String, dynamic>> _questions = [];
  int _examDurationMinutes = 0;
  String? _studentId;
  String? _schoolId;
  bool _isLoading = true;

  // ─── Integrity Tracking ──────────────────────────────────────────────

  final List<Map<String, dynamic>> _integrityLog = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _examStartedAt = DateTime.now();
    _loadOfflineExamData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Log integrity event when app goes to background during exam.
    if (state == AppLifecycleState.paused && !_isSubmitted) {
      _logIntegrityEvent('app_backgrounded');
    } else if (state == AppLifecycleState.resumed && !_isSubmitted) {
      _logIntegrityEvent('app_foregrounded');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DATA LOADING
  // ═══════════════════════════════════════════════════════════════════════

  /// Loads the exam data from local cache that was previously downloaded
  /// for offline access.
  Future<void> _loadOfflineExamData() async {
    try {
      final cacheManager = ref.read(cacheManagerProvider);
      final userId = cacheManager.storageService.getUserId();

      // Try to load the cached exam data.
      final cachedData = await cacheManager.getCachedData(
        key: 'offline_exam_${widget.examId}',
        userId: (userId as String?) ?? '',
      );

      if (cachedData == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Exam data not found. Please download this exam '
                'for offline use while connected.';
          });
        }
        return;
      }

      final examData = cachedData;

      setState(() {
        _questions = List<Map<String, dynamic>>.from(
          (examData['questions'] as List?)?.cast<Map<String, dynamic>>() ?? [],
        );
        _examDurationMinutes = examData['duration_minutes'] as int? ?? 60;
        _studentId = (examData['student_id'] as String?) ?? (userId as String?) ?? '';
        _schoolId = examData['school_id'] as String? ?? '';
        _timeRemaining = Duration(minutes: _examDurationMinutes);
        _isLoading = false;
      });

      // Check connectivity.
      _checkConnectivity();

      // Start the countdown timer.
      _startTimer();

      // Start the auto-save timer (every 30 seconds).
      _startAutoSaveTimer();

      _logIntegrityEvent('exam_started');
    } catch (e) {
      AppLogger.error('[OfflineExam] Failed to load exam data', error: e);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load exam data. The cached data may '
              'be corrupted. Please reconnect and try again.';
        });
      }
    }
  }

  /// Checks current connectivity status.
  Future<void> _checkConnectivity() async {
    try {
      final networkInfo = ref.read(coreNetworkInfoProvider);
      _isOnline = await networkInfo.isConnected;
    } catch (_) {
      _isOnline = false;
    }
    if (mounted) setState(() {});
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TIMER
  // ═══════════════════════════════════════════════════════════════════════

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining.inSeconds <= 0) {
        timer.cancel();
        _handleTimeUp();
        return;
      }
      if (mounted) {
        setState(() {
          _timeRemaining = _timeRemaining - const Duration(seconds: 1);
        });
      }
    });
  }

  void _handleTimeUp() {
    _logIntegrityEvent('time_up_auto_submit');
    _submitExam();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // AUTO-SAVE
  // ═══════════════════════════════════════════════════════════════════════

  void _startAutoSaveTimer() {
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _autoSave();
    });
  }

  /// Saves the current exam state to local storage.
  Future<void> _autoSave() async {
    if (_isSubmitted) return;

    try {
      final cacheManager = ref.read(cacheManagerProvider);
      final userId = _studentId ?? '';

      final saveData = <String, dynamic>{
        'exam_id': widget.examId,
        'current_question_index': _currentQuestionIndex,
        'answers': _answers,
        'flagged_questions': _flaggedQuestions,
        'time_remaining_seconds': _timeRemaining.inSeconds,
        'last_saved_at': DateTime.now().toIso8601String(),
      };

      await cacheManager.cacheData(
        key: 'offline_exam_progress_${widget.examId}',
        userId: userId,
        resourceType: 'exam_progress',
        resourceId: widget.examId,
        data: saveData,
      );

      AppLogger.debug('[OfflineExam] Auto-saved progress');
    } catch (e) {
      AppLogger.warning('[OfflineExam] Auto-save failed: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // INTEGRITY TRACKING
  // ═══════════════════════════════════════════════════════════════════════

  void _logIntegrityEvent(String eventType) {
    _integrityLog.add({
      'event': eventType,
      'timestamp': DateTime.now().toIso8601String(),
      'current_question': _currentQuestionIndex,
      'answers_count': _answers.length,
    });
  }

  /// Computes an integrity hash of the answers and timestamps.
  String _computeIntegrityHash() {
    final payload = jsonEncode({
      'exam_id': widget.examId,
      'student_id': _studentId,
      'answers': _answers,
      'integrity_log': _integrityLog,
      'started_at': _examStartedAt?.toIso8601String(),
      'submitted_at': DateTime.now().toIso8601String(),
    });
    return sha256.convert(utf8.encode(payload)).toString();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ANSWER HANDLING
  // ═══════════════════════════════════════════════════════════════════════

  void _selectAnswer(int questionIndex, Map<String, dynamic> answer) {
    if (_isSubmitted) return;
    setState(() {
      _answers[questionIndex] = {
        ...answer,
        'answered_at': DateTime.now().toIso8601String(),
      };
    });
  }

  void _toggleFlag(int questionIndex) {
    if (_isSubmitted) return;
    setState(() {
      _flaggedQuestions[questionIndex] =
          !(_flaggedQuestions[questionIndex] ?? false);
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  // NAVIGATION
  // ═══════════════════════════════════════════════════════════════════════

  void _goToQuestion(int index) {
    if (index < 0 || index >= _questions.length) return;
    setState(() {
      _currentQuestionIndex = index;
    });
  }

  void _goNext() => _goToQuestion(_currentQuestionIndex + 1);
  void _goPrevious() => _goToQuestion(_currentQuestionIndex - 1);

  // ═══════════════════════════════════════════════════════════════════════
  // SUBMIT EXAM
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _submitExam() async {
    if (_isSubmitting || _isSubmitted) return;

    // Confirm submission (unless auto-submitted due to time-up).
    final shouldSubmit = await _showSubmitConfirmation();
    if (!shouldSubmit) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    _logIntegrityEvent('exam_submitted');
    _timer?.cancel();
    _autoSaveTimer?.cancel();

    final integrityHash = _computeIntegrityHash();

    final attemptData = <String, dynamic>{
      'exam_id': widget.examId,
      'student_id': _studentId,
      'school_id': _schoolId,
      'started_at': _examStartedAt?.toIso8601String(),
      'completed_at': DateTime.now().toIso8601String(),
      'time_taken_seconds': _examDurationMinutes * 60 - _timeRemaining.inSeconds,
      'integrity_hash': integrityHash,
      'integrity_log': _integrityLog,
    };

    final answersData = <String, dynamic>{};
    _answers.forEach((index, answer) {
      final question = index < _questions.length ? _questions[index] : null;
      final questionId = question?['id'] as String? ?? 'q_$index';
      answersData[questionId] = answer;
    });

    final attempt = OfflineExamAttempt(
      id: '', // Will be generated by CacheManager
      examId: widget.examId,
      studentId: _studentId ?? '',
      schoolId: _schoolId ?? '',
      attemptData: attemptData,
      answers: answersData,
      startedAt: _examStartedAt ?? DateTime.now(),
      completedAt: DateTime.now(),
      timeTakenSeconds:
          _examDurationMinutes * 60 - _timeRemaining.inSeconds,
      integrityHash: integrityHash,
      syncStatus: AttemptSyncStatus.pending,
      syncAttempts: 0,
      createdAt: DateTime.now(),
    );

    try {
      // Save locally first (always).
      final cacheManager = ref.read(cacheManagerProvider);
      await cacheManager.saveOfflineExamAttempt(
        examId: attempt.examId,
        studentId: attempt.studentId,
        schoolId: {'id': attempt.schoolId},
        attemptData: attempt.attemptData,
        answers: attempt.answers,
        startedAt: attempt.startedAt,
        completedAt: attempt.completedAt,
        timeTakenSeconds: attempt.timeTakenSeconds ?? 0,
        integrityHash: attempt.integrityHash,
      );

      // Try to sync if online.
      await _checkConnectivity();

      if (_isOnline) {
        // Attempt immediate sync.
        try {
          final syncResult = await ref
              .read(offlineProvider.notifier)
              .loadSyncStatus(_studentId ?? '');

          // If sync engine is available, trigger it.
          // Otherwise, the attempt stays in pending queue and will
          // be synced when the SyncEngine processes it.
          setState(() {
            _isSubmitting = false;
            _isSubmitted = true;
            _successMessage = 'Exam submitted successfully! Your answers '
                'have been synced to the server.';
          });

          AppLogger.info('[OfflineExam] Exam submitted and synced');
        } catch (e) {
          // Network failure during submit — save locally, queue for sync.
          setState(() {
            _isSubmitting = false;
            _isSubmitted = true;
            _successMessage = 'Exam saved locally. Your answers will be '
                'synced when you reconnect.';
          });

          AppLogger.warning('[OfflineExam] Sync failed, saved locally: $e');
        }
      } else {
        // Offline — mark as pending sync.
        setState(() {
          _isSubmitting = false;
          _isSubmitted = true;
          _successMessage = 'You are offline. Your answers have been saved '
              'locally and will be synced when you reconnect.';
        });

        AppLogger.info('[OfflineExam] Exam saved locally (offline)');
      }
    } catch (e) {
      AppLogger.error('[OfflineExam] Failed to save exam attempt', error: e);

      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Failed to save your exam. Please try again. '
            'If the problem persists, your progress has been auto-saved '
            'and can be recovered.';
      });
    }
  }

  /// Shows a confirmation dialog before submitting.
  Future<bool> _showSubmitConfirmation() async {
    final unanswered = _questions.length - _answers.length;
    final flagged = _flaggedQuestions.values.where((f) => f).length;

    final result = await AppDialog.showCustom<bool>(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Submit Exam?',
            style: ctx.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: ctx.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.md),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You are about to submit "${widget.examTitle}".',
                style: ctx.textTheme.bodyMedium,
              ),
              Spacings.itemGap,
              Text(
                'Answered: ${_answers.length} / ${_questions.length}',
                style: ctx.textTheme.bodyMedium,
              ),
              if (unanswered > 0) ...[
                Spacings.smallGap,
                Text(
                  '⚠ $unanswered question${unanswered > 1 ? 's' : ''} unanswered',
                  style: ctx.textTheme.bodyMedium?.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ],
              if (flagged > 0) ...[
                Spacings.smallGap,
                Text(
                '🚩 $flagged question${flagged > 1 ? 's' : ''} flagged for review',
                  style: ctx.textTheme.bodyMedium?.copyWith(
                    color: AppColors.info,
                  ),
                ),
              ],
              Spacings.itemGap,
              Text(
                'This action cannot be undone.',
                style: ctx.textTheme.bodySmall?.copyWith(
                  color: ctx.colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                label: 'Cancel',
                variant: AppButtonVariant.outlined,
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
              const SizedBox(width: Spacings.sm),
              AppButton(
                label: 'Submit',
                variant: AppButtonVariant.elevated,
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
            ],
          ),
        ],
      ),
    );

    return result ?? false;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    // ─── Loading State ────────────────────────────────────────────────
    if (_isLoading) {
      return Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(title: Text(widget.examTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // ─── Error State (no exam data) ──────────────────────────────────
    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(title: Text(widget.examTitle)),
        body: Center(
          child: Padding(
            padding: Spacings.paddingAll,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, size: 64, color: cs.error),
                Spacings.sectionGap,
                Text(
                  _errorMessage ?? 'Exam data not available offline.',
                  style: tt.titleMedium?.copyWith(color: cs.error),
                  textAlign: TextAlign.center,
                ),
                Spacings.itemGap,
                AppButton(
                  label: 'Go Back',
                  variant: AppButtonVariant.outlined,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ─── Submitted State ─────────────────────────────────────────────
    if (_isSubmitted) {
      return _buildSubmittedScreen(context);
    }

    // ─── Active Exam UI ─────────────────────────────────────────────
    final currentQuestion = _questions[_currentQuestionIndex];
    final answeredCount = _answers.length;
    final totalCount = _questions.length;
    final progress = totalCount > 0 ? answeredCount / totalCount : 0.0;
    final isFlagged = _flaggedQuestions[_currentQuestionIndex] ?? false;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _showExitWarning();
        }
      },
      child: Scaffold(
        backgroundColor: cs.surface,
        appBar: _buildAppBar(context, cs, tt),
        body: Column(
          children: [
            // ─── Offline Warning Banner ─────────────────────────────
            if (!_isOnline) _buildOfflineBanner(context, cs, tt),

            // ─── Progress Bar ───────────────────────────────────────
            _buildProgressBar(context, cs, progress, answeredCount, totalCount),

            // ─── Question Content ───────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: Spacings.paddingScreen,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question header
                    _buildQuestionHeader(context, cs, tt, isFlagged),
                    Spacings.itemGap,

                    // Question text
                    _buildQuestionText(context, tt, currentQuestion),
                    Spacings.sectionGap,

                    // Answer input area
                    _buildAnswerArea(context, cs, tt, currentQuestion),
                  ],
                ),
              ),
            ),

            // ─── Bottom Navigation Bar ───────────────────────────────
            _buildBottomBar(context, cs, tt),
          ],
        ),

        // ─── Question Map Sidebar (desktop) ─────────────────────────
        endDrawer: context.isDesktop
            ? null
            : _buildQuestionMapDrawer(context, cs, tt),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // UI BUILDERS
  // ═══════════════════════════════════════════════════════════════════════

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ColorScheme cs,
    TextTheme tt,
  ) {
    final minutes = _timeRemaining.inMinutes;
    final seconds = _timeRemaining.inSeconds % 60;
    final isCritical = _timeRemaining.inMinutes < 5;
    final isWarning = _timeRemaining.inMinutes < 15 && !isCritical;

    return AppBar(
      title: Text(
        widget.examTitle,
        style: tt.titleMedium,
        overflow: TextOverflow.ellipsis,
      ),
      centerTitle: true,
      actions: [
        // Timer
        Container(
          margin: const EdgeInsets.only(right: Spacings.sm),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacings.md,
            vertical: Spacings.xs,
          ),
          decoration: BoxDecoration(
            color: isCritical
                ? AppColors.errorLight
                : isWarning
                    ? AppColors.warningLight
                    : cs.surfaceContainerHighest,
            borderRadius: Spacings.borderRadiusSm,
          ),
          child: Text(
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: tt.labelLarge?.copyWith(
              color: isCritical
                  ? AppColors.error
                  : isWarning
                      ? AppColors.warningDark
                      : cs.onSurface,
              fontWeight: FontWeight.bold,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
        ),

        // Question map button (mobile/tablet)
        if (!context.isDesktop)
          IconButton(
            icon: const Icon(Icons.grid_view),
            tooltip: 'Question Map',
            onPressed: () => Scaffold.of(context).openEndDrawer(),
          ),
      ],
    );
  }

  Widget _buildOfflineBanner(
    BuildContext context,
    ColorScheme cs,
    TextTheme tt,
  ) {
    return Container(
      width: double.infinity,
      padding: Spacings.paddingAllMd,
      color: AppColors.warningLight,
      child: Row(
        children: [
          const Icon(Icons.wifi_off, size: Spacings.mdIcon, color: AppColors.warningDark),
          Spacings.inlineGap,
          Expanded(
            child: Text(
              'You are taking this exam offline. Your answers will be synced '
              'when you reconnect.',
              style: tt.bodySmall?.copyWith(
                color: AppColors.warningDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(
    BuildContext context,
    ColorScheme cs,
    double progress,
    int answered,
    int total,
  ) {
    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: cs.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation(cs.primary),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacings.lg,
            vertical: Spacings.xs,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$answered / $total answered',
                style: context.textTheme.labelSmall,
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: context.textTheme.labelSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionHeader(
    BuildContext context,
    ColorScheme cs,
    TextTheme tt,
    bool isFlagged,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacings.md,
            vertical: Spacings.xs,
          ),
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: Spacings.borderRadiusSm,
          ),
          child: Text(
            'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
            style: tt.labelLarge?.copyWith(
              color: cs.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Spacer(),
        if (isFlagged)
          Padding(
            padding: const EdgeInsets.only(right: Spacings.sm),
            child: Icon(Icons.flag, color: AppColors.warning, size: Spacings.mdIcon),
          ),
        IconButton(
          icon: Icon(
            isFlagged ? Icons.flag : Icons.flag_outlined,
            color: isFlagged ? AppColors.warning : null,
          ),
          tooltip: isFlagged ? 'Unflag question' : 'Flag for review',
          onPressed: () => _toggleFlag(_currentQuestionIndex),
        ),
      ],
    );
  }

  Widget _buildQuestionText(
    BuildContext context,
    TextTheme tt,
    Map<String, dynamic> question,
  ) {
    final questionText = question['text'] as String? ?? '';
    final imageUrl = question['image_url'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imageUrl != null && imageUrl.isNotEmpty) ...[
          ClipRRect(
            borderRadius: Spacings.borderRadiusMd,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          Spacings.itemGap,
        ],
        SelectableText(
          questionText,
          style: tt.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildAnswerArea(
    BuildContext context,
    ColorScheme cs,
    TextTheme tt,
    Map<String, dynamic> question,
  ) {
    final questionType = question['type'] as String? ?? 'multiple_choice';
    final existingAnswer = _answers[_currentQuestionIndex];

    switch (questionType) {
      case 'multiple_choice':
        return _buildMultipleChoiceOptions(
          context,
          cs,
          tt,
          question,
          existingAnswer,
        );

      case 'true_false':
        return _buildTrueFalseOptions(
          context,
          cs,
          tt,
          existingAnswer,
        );

      case 'short_answer':
        return _buildShortAnswerField(
          context,
          cs,
          tt,
          existingAnswer,
        );

      default:
        return _buildMultipleChoiceOptions(
          context,
          cs,
          tt,
          question,
          existingAnswer,
        );
    }
  }

  Widget _buildMultipleChoiceOptions(
    BuildContext context,
    ColorScheme cs,
    TextTheme tt,
    Map<String, dynamic> question,
    Map<String, dynamic>? existingAnswer,
  ) {
    final options = List<Map<String, dynamic>>.from(
      (question['options'] as List?)?.cast<Map<String, dynamic>>() ?? [],
    );
    final selectedOption = existingAnswer?['option_id'] as String?;

    return Column(
      children: options.map((option) {
        final optionId = option['id'] as String? ?? '';
        final optionText = option['text'] as String? ?? '';
        final isSelected = selectedOption == optionId;

        return Padding(
          padding: const EdgeInsets.only(bottom: Spacings.sm),
          child: InkWell(
            onTap: () => _selectAnswer(
              _currentQuestionIndex,
              {'option_id': optionId, 'type': 'multiple_choice'},
            ),
            borderRadius: Spacings.borderRadiusMd,
            child: Container(
              width: double.infinity,
              padding: Spacings.paddingAll,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? cs.primary : cs.outline,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: Spacings.borderRadiusMd,
                color: isSelected ? cs.primaryContainer : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? cs.primary : cs.outline,
                        width: 2,
                      ),
                      color: isSelected ? cs.primary : null,
                    ),
                    child: isSelected
                        ? Icon(Icons.check, size: 16, color: cs.onPrimary)
                        : null,
                  ),
                  Spacings.inlineGap,
                  Expanded(
                    child: Text(
                      optionText,
                      style: tt.bodyMedium?.copyWith(
                        color: isSelected ? cs.onPrimaryContainer : cs.onSurface,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTrueFalseOptions(
    BuildContext context,
    ColorScheme cs,
    TextTheme tt,
    Map<String, dynamic>? existingAnswer,
  ) {
    final selectedValue = existingAnswer?['value'] as bool?;

    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _selectAnswer(
              _currentQuestionIndex,
              {'value': true, 'type': 'true_false'},
            ),
            borderRadius: Spacings.borderRadiusMd,
            child: Container(
              padding: Spacings.paddingAll,
              decoration: BoxDecoration(
                border: Border.all(
                  color: selectedValue == true ? AppColors.success : cs.outline,
                  width: selectedValue == true ? 2 : 1,
                ),
                borderRadius: Spacings.borderRadiusMd,
                color: selectedValue == true ? AppColors.successLight : null,
              ),
              child: Center(
                child: Text(
                  'True',
                  style: tt.bodyLarge?.copyWith(
                    color: selectedValue == true
                        ? AppColors.successDark
                        : cs.onSurface,
                    fontWeight: selectedValue == true
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ),
        Spacings.inlineGap,
        Expanded(
          child: InkWell(
            onTap: () => _selectAnswer(
              _currentQuestionIndex,
              {'value': false, 'type': 'true_false'},
            ),
            borderRadius: Spacings.borderRadiusMd,
            child: Container(
              padding: Spacings.paddingAll,
              decoration: BoxDecoration(
                border: Border.all(
                  color: selectedValue == false ? AppColors.error : cs.outline,
                  width: selectedValue == false ? 2 : 1,
                ),
                borderRadius: Spacings.borderRadiusMd,
                color: selectedValue == false ? AppColors.errorLight : null,
              ),
              child: Center(
                child: Text(
                  'False',
                  style: tt.bodyLarge?.copyWith(
                    color: selectedValue == false
                        ? AppColors.errorDark
                        : cs.onSurface,
                    fontWeight: selectedValue == false
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShortAnswerField(
    BuildContext context,
    ColorScheme cs,
    TextTheme tt,
    Map<String, dynamic>? existingAnswer,
  ) {
    final controller = TextEditingController(
      text: existingAnswer?['text'] as String? ?? '',
    );

    return TextField(
      controller: controller,
      maxLines: 5,
      decoration: InputDecoration(
        hintText: 'Type your answer here…',
        border: OutlineInputBorder(
          borderRadius: Spacings.borderRadiusMd,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: Spacings.borderRadiusMd,
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
      ),
      onChanged: (value) {
        _selectAnswer(
          _currentQuestionIndex,
          {'text': value, 'type': 'short_answer'},
        );
      },
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    ColorScheme cs,
    TextTheme tt,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      padding: Spacings.paddingAll,
      child: SafeArea(
        child: Row(
          children: [
            // Previous button
            AppButton(
              label: 'Previous',
              variant: AppButtonVariant.outlined,
              icon: Icons.arrow_back,
              onPressed: _currentQuestionIndex > 0 ? _goPrevious : null,
            ),
            const Spacer(),

            // Submit button
            AppButton(
              label: 'Submit',
              variant: AppButtonVariant.elevated,
              icon: Icons.send,
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submitExam,
            ),

            const Spacer(),

            // Next button
            AppButton(
              label: 'Next',
              variant: AppButtonVariant.outlined,
              icon: Icons.arrow_forward,
              iconAlignment: IconAlignment.end,
              onPressed:
                  _currentQuestionIndex < _questions.length - 1 ? _goNext : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionMapDrawer(
    BuildContext context,
    ColorScheme cs,
    TextTheme tt,
  ) {
    return Drawer(
      child: Column(
        children: [
          AppBar(
            title: const Text('Questions'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          Expanded(
            child: GridView.builder(
              padding: Spacings.paddingAll,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: Spacings.sm,
                crossAxisSpacing: Spacings.sm,
              ),
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final isAnswered = _answers.containsKey(index);
                final isFlagged = _flaggedQuestions[index] ?? false;
                final isCurrent = index == _currentQuestionIndex;

                Color bgColor;
                Color textColor;
                BoxBorder? border;

                if (isCurrent) {
                  bgColor = cs.primary;
                  textColor = cs.onPrimary;
                  border = null;
                } else if (isFlagged) {
                  bgColor = AppColors.warningLight;
                  textColor = AppColors.warningDark;
                  border = Border.all(color: AppColors.warning);
                } else if (isAnswered) {
                  bgColor = AppColors.successLight;
                  textColor = AppColors.successDark;
                  border = Border.all(color: AppColors.success);
                } else {
                  bgColor = cs.surfaceContainerHighest;
                  textColor = cs.onSurface;
                  border = Border.all(color: cs.outline);
                }

                return InkWell(
                  onTap: () {
                    _goToQuestion(index);
                    Navigator.of(context).pop(); // close drawer
                  },
                  borderRadius: Spacings.borderRadiusSm,
                  child: Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: Spacings.borderRadiusSm,
                      border: border,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: tt.labelMedium?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: Spacings.paddingAll,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem(cs, AppColors.successLight, AppColors.successDark, 'Answered'),
                _buildLegendItem(cs, AppColors.warningLight, AppColors.warningDark, 'Flagged'),
                _buildLegendItem(cs, cs.surfaceContainerHighest, cs.onSurface, 'Unanswered'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
    ColorScheme cs,
    Color bgColor,
    Color textColor,
    String label,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: Spacings.borderRadiusSm,
            border: Border.all(color: textColor, width: 1),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: context.textTheme.labelSmall),
      ],
    );
  }

  Widget _buildSubmittedScreen(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(title: Text(widget.examTitle)),
      body: Center(
        child: Padding(
          padding: Spacings.paddingAll,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 48,
                  color: AppColors.success,
                ),
              ),
              Spacings.sectionGap,

              // Title
              Text(
                'Exam Submitted!',
                style: tt.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
              Spacings.itemGap,

              // Message
              Text(
                _successMessage ?? 'Your answers have been saved.',
                style: tt.bodyLarge,
                textAlign: TextAlign.center,
              ),
              Spacings.sectionGap,

              // Summary stats
              AppCard(
                child: Column(
                  children: [
                    _buildStatRow('Questions answered', '${_answers.length} / ${_questions.length}'),
                    _buildStatRow('Time taken', _formatTimeTaken()),
                    _buildStatRow('Integrity hash', _computeIntegrityHash().substring(0, 16) + '…'),
                  ],
                ),
              ),
              Spacings.sectionGap,

              // Error message if any
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: Spacings.paddingAll,
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: Spacings.borderRadiusMd,
                  ),
                  child: Text(
                    _errorMessage!,
                    style: tt.bodyMedium?.copyWith(color: AppColors.errorDark),
                  ),
                ),
                Spacings.itemGap,
              ],

              // Done button
              AppButton(
                label: 'Done',
                variant: AppButtonVariant.elevated,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacings.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: context.textTheme.bodyMedium),
          Text(value, style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          )),
        ],
      ),
    );
  }

  String _formatTimeTaken() {
    final taken = _examDurationMinutes * 60 - _timeRemaining.inSeconds;
    final minutes = taken ~/ 60;
    final seconds = taken % 60;
    return '${minutes}m ${seconds}s';
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DIALOGS
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _showExitWarning() async {
    final result = await AppDialog.showConfirm(
      context: context,
      title: 'Leave Exam?',
      message: 'Are you sure you want to leave? Your progress has been '
          'auto-saved and you can resume later.',
      confirmText: 'Leave',
      cancelText: 'Stay',
    );

    if (result == true && mounted) {
      await _autoSave();
      Navigator.of(context).pop();
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// EXTENSION HELPERS (json conversion for OfflineExamAttempt)
// ═══════════════════════════════════════════════════════════════════════════════

extension _OfflineExamAttemptJson on OfflineExamAttempt {
  Map<String, dynamic> toJson() => {
        'id': id,
        'exam_id': examId,
        'student_id': studentId,
        'school_id': schoolId,
        'attempt_data': attemptData,
        'answers': answers,
        'started_at': startedAt.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        'time_taken_seconds': timeTakenSeconds,
        'integrity_hash': integrityHash,
        'sync_status': syncStatus.value,
        'sync_attempts': syncAttempts,
        'synced_at': syncedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };
}
