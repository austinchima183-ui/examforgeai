# Task: CCMS Feature Module - Presentation Providers

## Summary
Created 6 complete Riverpod provider files for the CCMS feature module at `/home/z/my-project/examforge_ai/lib/features/ccms/presentation/providers/`. Also updated `ccms_providers.dart` to wire up the new provider signatures with use case dependencies.

## Files Created/Updated

### 1. `educational_level_provider.dart`
- **State**: `EducationalLevelState` with `levels`, `schoolLevels`, `selectedLevelId` (String?), `isLoading`, `error`
- **Notifier**: `EducationalLevelNotifier` with 5 methods: `loadEducationalLevels()`, `loadSchoolLevels(schoolId)`, `configureSchoolLevel(schoolId, levelId, isEnabled, customName)`, `updateSchoolLevelConfiguration(configuration)`, `selectLevel(levelId)`
- **Key changes**: `selectedLevel` (entity) → `selectedLevelId` (String); added `updateSchoolLevelConfiguration` method using `UpdateSchoolLevelConfigurationUseCase`

### 2. `curriculum_provider.dart`
- **State**: `CurriculumState` with `curricula`, `selectedCurriculumId` (String?), `versions`, `levelMappings`, `isLoading`, `error`
- **Notifier**: `CurriculumNotifier` with 6 methods: `loadCurricula()`, `selectCurriculum(id)`, `loadVersions(curriculumId)`, `loadLevelMappings(curriculumId)`, `createCurriculum(data)`, `updateCurriculum(id, data)`
- **Key changes**: `selectedCurriculum` (entity) → `selectedCurriculumId` (String); added `GetCurriculumByIdUseCase` dependency; `updateCurriculum` now takes `(id, data)` params

### 3. `subject_provider.dart`
- **State**: `SubjectState` with `subjects`, `selectedSubjectId` (String?), `levelSubjects`, `isLoading`, `error`
- **Notifier**: `SubjectNotifier` with 6 methods: `loadSubjects(schoolId, levelId)`, `loadLevelSubjects(schoolId, levelId)`, `createSubject(data)`, `updateSubject(id, data)`, `deleteSubject(id)`, `selectSubject(id)`
- **Key changes**: `selectedSubject` (entity) → `selectedSubjectId` (String); added `GetSubjectByIdUseCase` dependency; `loadLevelSubjects` takes `(schoolId, levelId)`; `updateSubject` takes `(id, data)` params

### 4. `content_provider.dart`
- **State**: `ContentState` with `contentItems`, `selectedContent`, `versions`, `stats` (CcmsStats?), `filters`, `isLoading`, `error`
- **Filter**: `ContentFilterState` with `subjectId`, `educucationalLevelId`, `topicId`, `contentType`, `difficultyLevel`, `status`, `searchTerm`
- **Notifier**: `ContentNotifier` with 11 methods: `loadContentItems(filters)`, `loadContentById(id)`, `createContent(data)`, `updateContent(id, data)`, `deleteContent(id)`, `publishContent(id)`, `archiveContent(id)`, `loadVersions(contentItemId)`, `loadStats(schoolId)`, `setFilters(filters)`, `clearFilters()`
- **Key changes**: Added `stats` field, `searchTerm` in filters, `GetCcmsStatsUseCase` dependency, `loadStats()` method; replaced `GetContentWithDetailsUseCase` with `GetCcmsStatsUseCase`

### 5. `ai_curriculum_provider.dart`
- **State**: `AiCurriculumState` with `configs` (List<AiCurriculumConfig>), `generationRules`, `selectedConfig`, `isLoading`, `error`
- **Notifier**: `AiCurriculumNotifier` with 5 methods: `loadConfig(schoolId, subjectId, levelId)`, `upsertConfig(data)`, `loadGenerationRules(levelId)`, `createGenerationRule(data)`, `updateGenerationRule(id, data)`
- **Key changes**: `config` (single) → `configs` (List); `updateGenerationRule` takes `(id, data)` params

### 6. `enterprise_provider.dart`
- **State**: `EnterpriseState` with 14 fields: `auditTrail`, `mfaConfig`, `apiKeys`, `securityEvents`, `userSessions`, `ccmsStats`, `alertRules`, `alertIncidents`, `metrics`, `performanceLogs`, `errorReports`, `rateLimitResult`, `isLoading`, `error`
- **Notifier**: `EnterpriseNotifier` with 27 methods across audit, MFA, API keys, security, rate limiting, sessions, stats, alerts, metrics, performance, and error reporting
- **Key changes**: Massively expanded from 14 to 27 use case dependencies; added all monitoring-related state and methods (previously split between enterprise and monitoring providers)

### 7. `ccms_providers.dart` (Updated)
- Added `_getCurriculumByIdUseCaseProvider` and `_getSubjectByIdUseCaseProvider`
- Updated `curriculumProvider` to include `getCurriculumByIdUseCase`
- Updated `subjectProvider` to include `getSubjectByIdUseCase`
- Updated `contentProvider` to use `getCcmsStatsUseCase` instead of `getContentWithDetailsUseCase`
- Updated `enterpriseProvider` to inject all 27 use cases (14 original + 13 monitoring)

## Pattern Used
All providers follow the same consistent pattern:
- Immutable `State` class extending `Equatable` with `copyWith`
- `StateNotifier<State>` with use case dependencies injected via constructor
- `_mapFailureToMessage(Failure)` helper using exhaustive `failure.when()` pattern matching
- `Result<T>.fold()` for handling success/failure from use cases
- `StateNotifierProvider` defined in `ccms_providers.dart`
