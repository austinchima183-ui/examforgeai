import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/cbt_entities.dart';
import '../repositories/cbt_repository.dart';

/// Parameters for the [GetExamStatisticsUseCase].
class GetStatsParams {
  const GetStatsParams({
    required this.examId,
  });

  /// The ID of the exam to compute statistics for.
  final String examId;
}

/// Use case that retrieves aggregated statistics for an exam.
///
/// Validates that the exam exists before computing statistics.
/// The [ExamStatistics] entity includes score distributions,
/// pass rates, per-question correct rates, and grading progress.
class GetExamStatisticsUseCase {
  GetExamStatisticsUseCase(this._repository);

  final CbtRepository _repository;

  Future<Result<ExamStatistics>> call(GetStatsParams params) async {
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

    // ── Validate exam has been attempted ──────────────────────────────
    if (exam.status == ExamStatus.draft) {
      return const FailureResult(
        Failure.validation(
          message: 'Cannot compute statistics for a draft exam',
          fieldErrors: {
            'status': 'Exam must be published or further along to have statistics',
          },
        ),
      );
    }

    // ── Delegate to repository ────────────────────────────────────────
    return _repository.getExamStatistics(params.examId);
  }
}
