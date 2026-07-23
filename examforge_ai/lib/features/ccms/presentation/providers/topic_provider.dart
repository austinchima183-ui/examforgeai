import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/core.dart';
import '../../domain/entities/ccms_entities.dart';
import '../../domain/usecases/topic_usecases.dart';

class TopicState extends Equatable {
  final List<Topic> topics;
  final List<Subtopic> subtopics;
  final Topic? selectedTopic;
  final List<Topic> curriculumTree;
  final List<LearningObjective> learningObjectives;
  final bool isLoading;
  final String? error;

  const TopicState({
    this.topics = const [],
    this.subtopics = const [],
    this.selectedTopic,
    this.curriculumTree = const [],
    this.learningObjectives = const [],
    this.isLoading = false,
    this.error,
  });

  TopicState copyWith({
    List<Topic>? topics,
    List<Subtopic>? subtopics,
    Topic? selectedTopic,
    List<Topic>? curriculumTree,
    List<LearningObjective>? learningObjectives,
    bool? isLoading,
    String? error,
  }) {
    return TopicState(
      topics: topics ?? this.topics,
      subtopics: subtopics ?? this.subtopics,
      selectedTopic: selectedTopic ?? this.selectedTopic,
      curriculumTree: curriculumTree ?? this.curriculumTree,
      learningObjectives: learningObjectives ?? this.learningObjectives,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [topics, subtopics, selectedTopic, curriculumTree, learningObjectives, isLoading, error];
}

class TopicNotifier extends StateNotifier<TopicState> {
  final GetTopicsUseCase _getTopicsUseCase;
  final CreateTopicUseCase _createTopicUseCase;
  final UpdateTopicUseCase _updateTopicUseCase;
  final DeleteTopicUseCase _deleteTopicUseCase;
  final GetSubtopicsUseCase _getSubtopicsUseCase;
  final CreateSubtopicUseCase _createSubtopicUseCase;
  final UpdateSubtopicUseCase _updateSubtopicUseCase;
  final DeleteSubtopicUseCase _deleteSubtopicUseCase;
  final GetCurriculumTreeUseCase _getCurriculumTreeUseCase;

  TopicNotifier({
    required GetTopicsUseCase getTopicsUseCase,
    required CreateTopicUseCase createTopicUseCase,
    required UpdateTopicUseCase updateTopicUseCase,
    required DeleteTopicUseCase deleteTopicUseCase,
    required GetSubtopicsUseCase getSubtopicsUseCase,
    required CreateSubtopicUseCase createSubtopicUseCase,
    required UpdateSubtopicUseCase updateSubtopicUseCase,
    required DeleteSubtopicUseCase deleteSubtopicUseCase,
    required GetCurriculumTreeUseCase getCurriculumTreeUseCase,
  })  : _getTopicsUseCase = getTopicsUseCase,
        _createTopicUseCase = createTopicUseCase,
        _updateTopicUseCase = updateTopicUseCase,
        _deleteTopicUseCase = deleteTopicUseCase,
        _getSubtopicsUseCase = getSubtopicsUseCase,
        _createSubtopicUseCase = createSubtopicUseCase,
        _updateSubtopicUseCase = updateSubtopicUseCase,
        _deleteSubtopicUseCase = deleteSubtopicUseCase,
        _getCurriculumTreeUseCase = getCurriculumTreeUseCase,
        super(const TopicState());

  Future<void> loadTopics({String? subjectId, String? educationalLevelId, String? curriculumId}) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getTopicsUseCase(GetTopicsParams(
      subjectId: subjectId,
      educationalLevelId: educationalLevelId,
      curriculumId: curriculumId,
    ),);
    result.fold(
      onSuccess: (topics) => state = state.copyWith(topics: topics, isLoading: false),
      onFailure: (failure) => state = state.copyWith(isLoading: false, error: _mapFailureToMessage(failure)),
    );
  }

  Future<void> loadSubtopics(String topicId) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getSubtopicsUseCase(GetSubtopicsParams(topicId: topicId));
    result.fold(
      onSuccess: (subtopics) => state = state.copyWith(subtopics: subtopics, isLoading: false),
      onFailure: (failure) => state = state.copyWith(isLoading: false, error: _mapFailureToMessage(failure)),
    );
  }

  Future<void> loadCurriculumTree(String subjectId) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getCurriculumTreeUseCase(GetCurriculumTreeParams(subjectId: subjectId));
    result.fold(
      onSuccess: (tree) => state = state.copyWith(curriculumTree: tree, isLoading: false),
      onFailure: (failure) => state = state.copyWith(isLoading: false, error: _mapFailureToMessage(failure)),
    );
  }

  Future<void> createTopic(Topic topic) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _createTopicUseCase(CreateTopicParams(topic: topic));
    result.fold(
      onSuccess: (created) => state = state.copyWith(topics: [...state.topics, created], isLoading: false),
      onFailure: (failure) => state = state.copyWith(isLoading: false, error: _mapFailureToMessage(failure)),
    );
  }

  Future<void> updateTopic(Topic topic) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _updateTopicUseCase(UpdateTopicParams(topic: topic));
    result.fold(
      onSuccess: (updated) {
        final list = state.topics.map((t) => t.id == updated.id ? updated : t).toList();
        state = state.copyWith(topics: list, isLoading: false);
      },
      onFailure: (failure) => state = state.copyWith(isLoading: false, error: _mapFailureToMessage(failure)),
    );
  }

  Future<void> deleteTopic(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _deleteTopicUseCase(DeleteTopicParams(id: id));
    result.fold(
      onSuccess: (_) => state = state.copyWith(topics: state.topics.where((t) => t.id != id).toList(), isLoading: false),
      onFailure: (failure) => state = state.copyWith(isLoading: false, error: _mapFailureToMessage(failure)),
    );
  }

  Future<void> createSubtopic(Subtopic subtopic) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _createSubtopicUseCase(CreateSubtopicParams(subtopic: subtopic));
    result.fold(
      onSuccess: (created) => state = state.copyWith(subtopics: [...state.subtopics, created], isLoading: false),
      onFailure: (failure) => state = state.copyWith(isLoading: false, error: _mapFailureToMessage(failure)),
    );
  }

  Future<void> updateSubtopic(Subtopic subtopic) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _updateSubtopicUseCase(UpdateSubtopicParams(subtopic: subtopic));
    result.fold(
      onSuccess: (updated) {
        final list = state.subtopics.map((s) => s.id == updated.id ? updated : s).toList();
        state = state.copyWith(subtopics: list, isLoading: false);
      },
      onFailure: (failure) => state = state.copyWith(isLoading: false, error: _mapFailureToMessage(failure)),
    );
  }

  Future<void> deleteSubtopic(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _deleteSubtopicUseCase(DeleteSubtopicParams(id: id));
    result.fold(
      onSuccess: (_) => state = state.copyWith(subtopics: state.subtopics.where((s) => s.id != id).toList(), isLoading: false),
      onFailure: (failure) => state = state.copyWith(isLoading: false, error: _mapFailureToMessage(failure)),
    );
  }

  void selectTopic(Topic topic) {
    state = state.copyWith(selectedTopic: topic);
  }

  Future<void> loadLearningObjectives() async {
    // Learning objectives are loaded alongside topics in this simplified version
  }
}

String _mapFailureToMessage(Failure failure) {
  return failure.when(
    server: (message, statusCode, data) => 'Server error: $message',
    cache: (message) => 'Cache error: $message',
    auth: (message, code) => 'Auth error: $message',
    network: (message) => 'Network error: $message',
    validation: (message, fieldErrors) => 'Validation error: $message',
    notFound: (message) => 'Not found: $message',
    unauthorized: (message) => 'Unauthorized: $message',
    forbidden: (message) => 'Forbidden: $message',
  );
}
