# Task: Question Bank Module - Presentation Providers

## Summary
Created 6 new provider files and updated 2 existing files for the ExamForge AI Question Bank module, following the project's StateNotifier + immutable State + StateNotifierProvider pattern.

## Files Created

### 1. `lib/features/question_bank/presentation/providers/question_provider.dart`
- **QuestionBankState**: Immutable state with questions list, pagination (currentPage, hasMore, totalCount), loading flags (isLoading, isLoadingMore, isCreating, isUpdating, isDeleting), error/success messages, currentQuestion, and filter.
- **QuestionBankNotifier**: Main state management with all 14 methods: loadQuestions, loadMoreQuestions, refreshQuestions, createQuestion, updateQuestion, deleteQuestion, getQuestionDetail, searchQuestions, setFilter, clearFilter, publishQuestion, archiveQuestion, restoreQuestion, duplicateQuestion, plus clearError/clearSuccessMessage.

### 2. `lib/features/question_bank/presentation/providers/question_filter_provider.dart`
- **QuestionFilterState**: Tracks active filter + available metadata (subjects, topics, subtopics, categories, tags, sessions).
- **QuestionFilterNotifier**: Manages filter state with cascading updates (subject→topics, topic→subtopics). Methods: loadFilterMetadata, updateSubject, updateTopic, updateDifficulty, updateQuestionType, updateExamType, updateSearchQuery, updateSortBy, addTag, removeTag, clearAllFilters. Includes `hasActiveFilters` getter.

### 3. `lib/features/question_bank/presentation/providers/collection_provider.dart`
- **CollectionState**: Tracks collections list, currentCollection, collectionQuestions, loading/creating/updating flags.
- **CollectionNotifier**: Full CRUD via ManageCollectionsUseCase. Methods: loadCollections, createCollection, updateCollection, deleteCollection, loadCollectionQuestions, addQuestionToCollection, removeQuestionFromCollection.

### 4. `lib/features/question_bank/presentation/providers/import_export_provider.dart`
- **ImportExportState**: Tracks import/export status with progress (0.0–1.0), job entities, computed properties (isImportComplete, isExportComplete, etc.).
- **ImportExportNotifier**: Handles async jobs with Timer-based polling. Methods: startImport, checkImportStatus, startExport, checkExportStatus, resetState. Properly disposes timers on dispose.

### 5. `lib/features/question_bank/presentation/providers/question_bank_stats_provider.dart`
- **QuestionBankStatsState**: Simple state with QuestionBankStatsEntity, isLoading, error.
- **QuestionBankStatsNotifier**: Loads aggregated stats. Methods: loadStats, refreshStats (with optional schoolId scoping).

### 6. `lib/features/question_bank/presentation/providers/question_editor_provider.dart`
- **QuestionEditorState**: Complete form state with all fields (content, explanation, teacherNotes, referenceMaterials, selectedQuestionType, selectedDifficulty, selectedExamType, subject/topic/subtopic/class/category IDs, marks, negativeMarks, timeAllowedSeconds), plus type-specific data (answerOptions, matchingPairs, orderingItems, fillInBlankAnswers, attachments, selectedTags), availableTopics/Subtopics, and computed helpers.
- **QuestionEditorNotifier**: Full form management with 30+ methods: loadQuestionForEdit, all setters, answer option management (add/remove/update/setCorrect), matching pair management, ordering item management (including reorder), fill-in-blank management, attachment/tag management, saveQuestion (create or update), saveAndPublish, togglePreviewMode, resetForm, validateForm.

## Files Updated

### 7. `lib/config/dependency_injection.dart`
Added 20 new providers following the exact auth provider pattern:
- questionBankRemoteDataSourceProvider
- questionBankRepositoryProvider
- 11 use case providers (getQuestions, createQuestion, updateQuestion, deleteQuestion, getQuestionDetail, searchQuestions, manageQuestionStatus, getQuestionStats, importQuestions, exportQuestions, manageCollections)
- 6 StateNotifierProvider entries (questionBankProvider, questionFilterProvider, collectionProvider, importExportProvider, questionBankStatsProvider, questionEditorProvider)

### 8. `lib/routing/route_names.dart`
Added 9 route constants:
- questionBank, questionBankList, questionBankCreate, questionBankDetail, questionBankEdit, questionBankImport, questionBankExport, questionBankCollections, questionBankStats
- Added `questionBankRoutes` helper set
- Updated `protectedRoutes` set to include all question bank routes

## Key Design Decisions
- All states are immutable with copyWith patterns (matching auth_provider.dart)
- All notifiers use Result.fold() for success/failure handling (matching project convention)
- Failure mapping uses the exhaustive `when` pattern on the sealed Failure class
- Question type changes in editor auto-reset type-specific fields to prevent stale data
- Import/export uses Timer-based polling with proper cleanup on dispose
- Filter metadata loading uses cascading updates (subject→topics→subtopics)
