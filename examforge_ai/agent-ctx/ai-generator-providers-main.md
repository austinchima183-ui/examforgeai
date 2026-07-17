# AI Generator Providers — Work Record

**Task ID**: ai-generator-providers-main  
**Agent**: Main  
**Date**: 2026-03-05

## Summary

Created the complete AI Question Generation Engine provider layer for ExamForge AI, following the project's established StateNotifier + immutable State + StateNotifierProvider pattern.

## Files Created

### 1. `lib/features/ai_generator/presentation/providers/ai_generator_provider.dart`
- **AiGeneratorState**: Immutable state tracking generated questions, current generation request, streaming progress, input form data, generation history, and transient messages
- **AiGeneratorNotifier**: Main generation state management with methods for:
  - `generateQuestions()` — standard generation via repository
  - `generateQuestionsStreaming()` — streaming generation via AiService
  - `startStreamingGeneration()` — imperative streaming with StreamSubscription
  - `cancelGeneration()` — cancels active streaming
  - `setInput()` / `updateInputField()` — form state management
  - `approveQuestion()` / `rejectQuestion()` / `requestRevision()` — review actions
  - `improveQuestion()` — AI-powered improvement
  - `validateQuestion()` — quality validation
  - `saveToQuestionBank()` — save to QB module
  - `loadGenerationHistory()` — paginated history
  - `clearError()` / `clearSuccessMessage()` / `clearGeneratedQuestions()`

### 2. `lib/features/ai_generator/presentation/providers/ai_review_provider.dart`
- **AiReviewState**: Tracks pending questions, current question detail, validation results, improvement previews, filter state
- **AiReviewNotifier**: Review workflow with:
  - `loadPendingQuestions()` — filtered by ReviewStatus
  - `loadQuestionDetail()` — single question detail
  - `loadValidationResults()` — validation for a question
  - `approve()` / `reject()` / `requestRevision()` — review actions
  - `improveAndPreview()` — AI improvement preview
  - `acceptImprovement()` — apply improvement
  - `saveApprovedToQuestionBank()` — save to QB
  - `setFilter()` / `clearError()`

### 3. `lib/features/ai_generator/presentation/providers/ai_document_provider.dart`
- **AiDocumentState**: Tracks uploaded documents, current document, upload/processing flags, extracted text, topics, objectives
- **AiDocumentNotifier**: Document operations with:
  - `uploadDocument()` — upload with validation
  - `processDocument()` — extract text, topics, objectives
  - `generateFromDocument()` — generate questions from document content
  - `loadDocuments()` — placeholder for listing
  - `clearError()`

### 4. `lib/features/ai_generator/presentation/providers/prompt_template_provider.dart`
- **PromptTemplateState**: Tracks templates list, current template, loading/saving flags, PromptType filter
- **PromptTemplateNotifier**: CRUD operations:
  - `loadTemplates()` — filtered by type and subject
  - `loadTemplate()` — single template
  - `createTemplate()` / `updateTemplate()` / `deleteTemplate()`
  - `setFilter()` / `clearError()`

### 5. `lib/features/ai_generator/presentation/providers/ai_stats_provider.dart`
- **AiStatsState**: Tracks dashboard stats, usage history, loading state
- **AiStatsNotifier**: Stats loading with:
  - `loadStats()` — aggregated dashboard stats
  - `loadUsageHistory()` — with date range filtering
  - `refreshStats()` — refresh both stats and history

## Files Updated

### 6. `lib/config/dependency_injection.dart`
Added AI module providers:
- **Service infrastructure**: `aiProviderRegistryProvider`, `promptEngineProvider`, `validationEngineProvider`, `aiServiceProvider`, `openaiProvider`, `geminiProvider`
- **Data layer**: `aiGeneratorRemoteDataSourceProvider`, `aiGeneratorRepositoryProvider`
- **9 use case providers**: All AI generator use cases
- **5 StateNotifierProvider instances**: All AI feature notifiers

### 7. `lib/routing/route_names.dart`
Added AI Generator routes:
- `aiGenerator`, `aiGeneratorGenerate`, `aiGeneratorReview`, `aiGeneratorImprove`
- `aiGeneratorDocument`, `aiGeneratorHistory`, `aiGeneratorPrompts`, `aiGeneratorStats`
- Added `aiGeneratorRoutes` helper set
- Added all AI routes to `protectedRoutes`

## Design Decisions

1. **Nullable input**: `GenerationInputEntity?` in AiGeneratorState (rather than a default) because the entity has required fields
2. **clearCurrentGeneration/clearGenerationProgress flags**: Used in copyWith to properly clear nullable reference fields while keeping the `??` safety for non-clearing updates
3. **AiService injection**: The generator notifier takes AiService directly for streaming, while using use cases for standard operations
4. **Conditional AI providers**: OpenAI and Gemini providers are conditionally registered based on env config API keys
5. **Consistent error mapping**: All notifiers use the same `_mapFailureToMessage` pattern matching all Failure variants
