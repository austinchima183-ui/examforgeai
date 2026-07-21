import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/cbt_entities.dart';
import '../repositories/cbt_repository.dart';
import '../../../../features/cbt_engine/domain/entities/cbt_entities.dart';


/// Parameters for the [GetLiveExamStatsUseCase].
class GetLiveStatsParams {
  const GetLiveStatsParams({
    required this.examId,
  });

  /// The ID of the exam to retrieve live stats for.
  final String examId;
}

/// Use case that retrieves live exam statistics for the real-time
/// monitoring dashboard.
///
/// Validates that the exam exists and is in a state where live
/// monitoring makes sense (published, active, or recently completed).
///
/// Returns a [LiveExamStats] entity containing:
/// - Counts of eligible, active, completed, and not-started students
/// - Average progress across active sessions
/// - Recent submissions
/// - Currently active sessions with real-time state
/// - Recent monitoring events for anti-cheat oversight
class GetLiveExamStatsUseCase {
  GetLiveExamStatsUseCase(this._repository);

  final CbtRepository _repository;

  Future<Result<LiveExamStats>> call(GetLiveStatsParams params) async {
    // ── Validate exam exists ──────────────────────────────────────────
    final examResult = await _repository.getExam(params.examId);
    if (examResult.isFailure) {
      return FailureResult(examResult.fold(
        onSuccess: (_) =>
            const Failure.server(message: 'Unknown error', statusCode: 500),
        onFailure: (failure) => failure,
      ));
    }

    final exam = examResult.getOrElse(
      const ExamEntity(
        id: '',
        schoolId: '',
        createdBy: '',
        title: '',
        subjectId: '',
        classId: '',
        academicSessionId: '',
        examType: ExamType.custom,
        status: ExamStatus.draft,
        startTime: DateTime(2000),
        endTime: DateTime(2000),
        timeLimitMinutes: 0,
        totalMarks: 0,
        passMark: 0,
        createdAt: DateTime(2000),
        updatedAt: DateTime(2000),
      ),
    );

    // ── Validate exam is in a monitorable state ───────────────────────
    final monitorableStatuses = {
      ExamStatus.published,
      ExamStatus.active,
      ExamStatus.completed,
    };

    if (!monitorableStatuses.contains(exam.status)) {
      return FailureResult(
        Failure.validation(
          message:
              'Live stats are not available for ${exam.status.label} exams',
          fieldErrors: {
            'status':
                'Exam must be published, active, or completed for live monitoring',
          },
        ),
      );
    }

    // ── Delegate to repository ────────────────────────────────────────
    return _repository.getLiveExamStats(params.examId);
  }
}
