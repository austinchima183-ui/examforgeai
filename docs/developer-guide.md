# ExamForge AI — Developer Guide

> **Curriculum Content Management System (CCMS) & Nigerian Curriculum Module**
> Complete technical reference for contributors and maintainers.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [CCMS Module Structure](#ccms-module-structure)
3. [Entity and Model Patterns](#entity-and-model-patterns)
4. [How to Add New Educational Levels](#how-to-add-new-educational-levels)
5. [How to Add New Subjects](#how-to-add-new-subjects)
6. [How to Extend the Content Type System](#how-to-extend-the-content-type-system)
7. [API Integration Patterns](#api-integration-patterns)
8. [Local Database Patterns](#local-database-patterns)
9. [Testing Guidelines](#testing-guidelines)
10. [Code Style Conventions](#code-style-conventions)
11. [Error Handling Patterns](#error-handling-patterns)

---

## Architecture Overview

ExamForge AI is built on **Clean Architecture** principles with a clear separation of concerns across three primary layers: Domain, Data, and Presentation. The application is a cross-platform Flutter project that targets web, Android, and iOS.

### Core Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| State Management | Riverpod 2.x | Reactive dependency injection and state |
| Navigation | GoRouter | Declarative routing with deep-link support |
| Backend | Supabase | Auth, database (PostgreSQL), storage, real-time |
| Local Storage | Hive / SQLite | Offline-first caching and persistence |
| Networking | Dio + Supabase Client | HTTP communication and type-safe API calls |
| PWA | flutter_pwa | Progressive web app capabilities |

### Architectural Diagram

```
┌──────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                     │
│  Pages  │  Widgets  │  Providers (Riverpod)  │  Router   │
├──────────────────────────────────────────────────────────┤
│                     DOMAIN LAYER                          │
│  Entities  │  Repository Interfaces  │  Use Cases         │
├──────────────────────────────────────────────────────────┤
│                      DATA LAYER                           │
│  Repository Impls  │  Data Sources (Remote/Local)  │  Models│
├──────────────────────────────────────────────────────────┤
│                       CORE                                │
│  Errors  │  Utils  │  Network  │  Storage  │  Themes      │
└──────────────────────────────────────────────────────────┘
```

### Key Design Principles

- **Dependency Inversion**: Domain layer defines repository interfaces; Data layer provides implementations.
- **Single Responsibility**: Each use case encapsulates exactly one business operation.
- **Immutable Entities**: Domain entities extend `Equatable` and are immutable value objects.
- **Result Type**: All asynchronous operations return `Result<T>` which is a sealed union of `Success<T>` and `Failure`.
- **Offline-First**: The Sync Engine queues mutations when offline and replays them when connectivity is restored.

---

## CCMS Module Structure

The CCMS module lives under `lib/features/ccms/` and follows the feature-first architecture:

```
lib/features/ccms/
├── data/
│   ├── datasources/
│   │   └── ccms_remote_datasource.dart    # Supabase RPC + REST calls
│   ├── models/
│   │   └── ccms_models.dart               # JSON ↔ Dart model conversion
│   └── repositories/
│       └── ccms_repository_impl.dart       # Implements domain repository
├── domain/
│   ├── entities/
│   │   └── ccms_entities.dart              # Pure Dart domain objects
│   ├── repositories/
│   │   └── ccms_repository.dart            # Abstract repository contract
│   └── usecases/
│       ├── content_usecases.dart
│       ├── subject_usecases.dart
│       ├── curriculum_usecases.dart
│       ├── topic_usecases.dart
│       ├── educational_level_usecases.dart
│       ├── content_review_usecases.dart
│       ├── content_collection_usecases.dart
│       ├── content_import_usecases.dart
│       ├── ai_curriculum_usecases.dart
│       ├── answer_repository_usecases.dart
│       ├── enterprise_security_usecases.dart
│       ├── monitoring_usecases.dart
│       └── deployment_usecases.dart
└── presentation/
    ├── pages/
    │   ├── content_library_page.dart
    │   ├── educational_levels_page.dart
    │   ├── subjects_management_page.dart
    │   ├── curricula_management_page.dart
    │   ├── topic_management_page.dart
    │   ├── content_import_page.dart
    │   ├── content_review_page.dart
    │   ├── content_editor_page.dart
    │   ├── ai_curriculum_config_page.dart
    │   ├── audit_trail_page.dart
    │   └── security_dashboard_page.dart
    ├── widgets/
    │   └── ccms_widgets.dart
    └── providers/
        └── ccms_provider.dart
```

### Layer Responsibilities

**Domain Layer** — Contains pure business logic with zero framework dependencies:
- **Entities**: Immutable value objects (`EducationalLevel`, `ContentItem`, `Subject`, etc.)
- **Repository Interfaces**: Abstract contracts that define what operations are possible
- **Use Cases**: Single-purpose classes that orchestrate repository calls with business rules

**Data Layer** — Handles all external communication:
- **Remote Data Source**: Calls Supabase RPC functions and table CRUD endpoints
- **Models**: Extend entities with `fromJson`/`toJson` serialization
- **Repository Implementation**: Converts data-source results into domain `Result<T>` types, catching exceptions and mapping them to `Failure` objects

**Presentation Layer** — Manages UI state and user interaction:
- **Pages**: Full-screen route destinations
- **Widgets**: Reusable UI components
- **Providers**: Riverpod `AsyncNotifier` classes that manage feature state, call use cases, and expose reactive UI state

---

## Entity and Model Patterns

### Entity Pattern

All domain entities extend `Equatable` and are immutable:

```dart
class ContentItem extends Equatable {
  final String? id;
  final String title;
  final ContentType contentType;
  final String subjectId;
  final String educationalLevelId;
  final String? topicId;
  final String? subtopicId;
  final String? curriculumId;
  final String? schoolId;
  final QuestionCategory? questionCategory;
  final DifficultyLevel difficultyLevel;
  final BloomTaxonomy bloomLevel;
  final String body;
  final Map<String, dynamic> bodyRich;
  final List<Map<String, dynamic>> options;
  final Map<String, dynamic> correctAnswer;
  final String? stepByStepExplanation;
  final Map<String, dynamic> markingScheme;
  final String? teacherNotes;
  final ContentStatus status;
  final int version;
  final int usageCount;
  final bool isAiGenerated;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ContentItem({
    this.id,
    required this.title,
    required this.contentType,
    required this.subjectId,
    required this.educationalLevelId,
    this.topicId,
    this.subtopicId,
    // ... all fields
  });

  @override
  List<Object?> get props => [id, title, contentType, subjectId, /* ... */];
}
```

### Model Pattern

Models extend entities and add JSON serialization:

```dart
class ContentItemModel extends ContentItem {
  const ContentItemModel({
    super.id,
    required super.title,
    required super.contentType,
    // ... all fields
  });

  factory ContentItemModel.fromJson(Map<String, dynamic> json) {
    return ContentItemModel(
      id: json['id'] as String?,
      title: json['title'] as String,
      contentType: ContentType.fromString(json['content_type']),
      subjectId: json['subject_id'] as String,
      educationalLevelId: json['educational_level_id'] as String,
      difficultyLevel: DifficultyLevel.fromString(json['difficulty_level']),
      bloomLevel: BloomTaxonomy.fromString(json['bloom_level']),
      body: json['body'] as String,
      status: ContentStatus.fromString(json['status']),
      version: json['version'] as int,
      // ... parse all fields
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content_type': contentType.value,
      'subject_id': subjectId,
      'educational_level_id': educationalLevelId,
      'difficulty_level': difficultyLevel.value,
      'bloom_level': bloomLevel.value,
      'body': body,
      'status': status.value,
      'version': version,
      // ... serialize all fields
    };
  }
}
```

### Enum Pattern

All enums follow a consistent pattern with `value` and `label` properties and a `fromString` factory:

```dart
enum ContentType {
  question(value: 'question', label: 'Question'),
  explanation(value: 'explanation', label: 'Explanation'),
  markingScheme(value: 'marking_scheme', label: 'Marking Scheme'),
  teacherNote(value: 'teacher_note', label: 'Teacher Note'),
  lessonNote(value: 'lesson_note', label: 'Lesson Note'),
  worksheet(value: 'worksheet', label: 'Worksheet'),
  practicalGuide(value: 'practical_guide', label: 'Practical Guide'),
  readingMaterial(value: 'reading_material', label: 'Reading Material'),
  videoScript(value: 'video_script', label: 'Video Script'),
  assessmentRubric(value: 'assessment_rubric', label: 'Assessment Rubric');

  const ContentType({required this.value, required this.label});
  final String value;
  final String label;

  static ContentType? fromString(String? value) {
    if (value == null) return null;
    return ContentType.values.cast<ContentType?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}
```

---

## How to Add New Educational Levels

### Step 1: Add to the PostgreSQL Enum

Edit `supabase/migrations/ccms_enterprise_schema.sql` and add the new level value to the `educational_level_type` enum:

```sql
-- Example: Adding a "pre_primary" level
ALTER TYPE public.educational_level_type ADD VALUE IF NOT EXISTS 'pre_primary';
```

### Step 2: Seed the Level

Insert a new row into `public.educational_levels`:

```sql
INSERT INTO public.educational_levels (code, name, level_category, level_order, min_age, max_age, description)
VALUES ('pre_primary', 'Pre-Primary', 'early_childhood', 0, 3, 5, 'Pre-primary bridge year')
ON CONFLICT (code) DO NOTHING;
```

### Step 3: Add to the Dart Enum

In `lib/features/ccms/domain/entities/ccms_entities.dart`, update the `EducationalLevelCategory` enum if a new category is needed, and add the corresponding code value to the mapping.

### Step 4: Add Default Subjects for the Level

Insert subject records associated with the new level:

```sql
INSERT INTO public.subjects (name, code, educational_level_id, subject_group, is_core, is_elective, is_vocational, sort_order, is_custom, description)
SELECT 'Pre-Primary Literacy', 'PP-LIT', el.id, 'language', true, false, false, 1, false, 'Pre-primary literacy fundamentals'
FROM public.educational_levels el WHERE el.code = 'pre_primary';
```

### Step 5: Create School-Level Configuration

Schools can enable the new level via the `school_level_configurations` table or the UI on the Educational Levels management page.

---

## How to Add New Subjects

### Step 1: Insert the Subject Record

```sql
INSERT INTO public.subjects (
  name, code, educational_level_id, curriculum_id, school_id,
  subject_group, is_core, is_elective, is_vocational,
  language_of_instruction, description, sort_order, is_custom
) VALUES (
  'Data Science', 'SS-DSCI',
  (SELECT id FROM public.educational_levels WHERE code = 'ss_2'),
  NULL, NULL,
  'technology', false, true, false,
  'English', 'Introduction to Data Science and Analytics', 35, true
);
```

### Step 2: Create Topics and Subtopics

```sql
-- Create topic
INSERT INTO public.topics (subject_id, educational_level_id, title, code, description, sort_order, estimated_duration_minutes)
SELECT id, educational_level_id, 'Introduction to Data', 'DS-01', 'Understanding data types and sources', 1, 45
FROM public.subjects WHERE code = 'SS-DSCI';

-- Create subtopic
INSERT INTO public.subtopics (topic_id, title, code, description, sort_order, estimated_duration_minutes)
SELECT id, 'Qualitative vs Quantitative Data', 'DS-01-01', 'Distinguishing data types', 1, 20
FROM public.topics WHERE code = 'DS-01';
```

### Step 3: Define Learning Objectives

```sql
INSERT INTO public.learning_objectives (
  topic_id, subject_id, educational_level_id, code, description, bloom_level, is_assessable, sort_order
)
SELECT t.id, t.subject_id, t.educational_level_id,
  'DS-LO-01', 'Students can differentiate between qualitative and quantitative data',
  'understand', true, 1
FROM public.topics t WHERE t.code = 'DS-01';
```

### Step 4: Add AI Generation Rules (Optional)

```sql
INSERT INTO public.ai_generation_rules (educational_level_id, subject_id, rule_name, rule_type, conditions, actions, priority, is_active)
SELECT el.id, s.id, 'Data Science Vocab', 'vocabulary_level',
  '{"max_syllables": 4}'::jsonb,
  '{"use_simple_language": true}'::jsonb,
  10, true
FROM public.educational_levels el, public.subjects s
WHERE el.code = 'ss_2' AND s.code = 'SS-DSCI';
```

---

## How to Extend the Content Type System

The content type system is defined in two places: the PostgreSQL enum `content_type_enum` and the Dart enum `ContentType`.

### Step 1: Add the PostgreSQL Enum Value

```sql
ALTER TYPE public.content_type_enum ADD VALUE IF NOT EXISTS 'interactive_simulation';
```

### Step 2: Add the Dart Enum Value

```dart
enum ContentType {
  // ... existing values
  interactiveSimulation(value: 'interactive_simulation', label: 'Interactive Simulation');

  // ... rest of enum definition
}
```

### Step 3: Update the Content Item Model

If the new content type requires specialized fields, add them to `content_items.metadata` (JSONB) rather than adding new columns. This keeps the schema flexible:

```dart
// In your use case or provider
final content = ContentItem(
  title: 'Projectile Motion Simulator',
  contentType: ContentType.interactiveSimulation,
  body: 'Interactive simulation of projectile motion under gravity',
  metadata: {
    'simulation_url': 'https://assets.examforge.ai/sims/projectile.html',
    'interaction_type': 'drag_and_drop',
    'required_browsers': ['chrome', 'firefox', 'safari'],
  },
  // ... other required fields
);
```

### Step 4: Add UI Support

Create a dedicated widget or renderer for the new content type in the presentation layer:

```dart
class InteractiveSimulationRenderer extends StatelessWidget {
  final ContentItem content;
  const InteractiveSimulationRenderer({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    final simUrl = content.metadata?['simulation_url'] as String?;
    return WebViewWidget(url: simUrl ?? '');
  }
}
```

### Step 5: Add Content Type Badge

Update `ContentTypeBadge` widget to handle the new type:

```dart
case ContentType.interactiveSimulation:
  return Badge(
    label: Text('Simulation'),
    backgroundColor: Colors.purple,
    icon: Icon(Icons.science),
  );
```

---

## API Integration Patterns

### Supabase Client Initialization

The Supabase client is initialized in `main.dart` and accessed throughout the app:

```dart
await Supabase.initialize(
  url: const String.fromEnvironment('SUPABASE_URL'),
  anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
);
```

### Remote Data Source Pattern

The `CcmsRemoteDataSource` class wraps all Supabase calls and returns plain `Map<String, dynamic>` or `List<Map<String, dynamic>>`:

```dart
class CcmsRemoteDataSourceImpl implements CcmsRemoteDataSource {
  final sb.SupabaseClient _client;

  CcmsRemoteDataSourceImpl(this._client);

  @override
  Future<List<Map<String, dynamic>>> getEducationalLevels() async {
    final response = await _client
        .from('educational_levels')
        .select()
        .eq('is_active', true)
        .order('level_order');
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<List<Map<String, dynamic>>> getSchoolLevels(String schoolId) async {
    final response = await _client.rpc(
      'get_school_levels',
      params: {'p_school_id': schoolId},
    );
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<Map<String, dynamic>> createContent(Map<String, dynamic> data) async {
    final response = await _client
        .from('content_items')
        .insert(data)
        .select()
        .single();
    return Map<String, dynamic>.from(response);
  }
}
```

### Repository Implementation Pattern

The repository converts raw data into domain types and handles error mapping:

```dart
class CcmsRepositoryImpl implements CcmsRepository {
  final CcmsRemoteDataSource _remoteDataSource;

  CcmsRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<List<ContentItem>>> getContentItems({
    String? subjectId,
    String? educationalLevelId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final data = await _remoteDataSource.getContentItems(
        subjectId: subjectId,
        educationalLevelId: educationalLevelId,
        limit: limit,
        offset: offset,
      );
      final items = data.map((e) => ContentItemModel.fromJson(e)).toList();
      return Result.success(items);
    } on ServerException catch (e) {
      return Result.failure(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on NetworkException catch (e) {
      return Result.failure(Failure.network(message: e.message));
    } catch (e) {
      return Result.failure(Failure.server(message: e.toString(), statusCode: 500));
    }
  }
}
```

### Use Case Pattern

Use cases encapsulate a single business operation:

```dart
class GetContentItemsUseCase {
  final CcmsRepository _repository;
  GetContentItemsUseCase(this._repository);

  Future<Result<List<ContentItem>>> call(GetContentItemsParams params) async {
    return await _repository.getContentItems(
      subjectId: params.subjectId,
      educationalLevelId: params.educationalLevelId,
      limit: params.limit,
      offset: params.offset,
    );
  }
}
```

### Provider Pattern (Riverpod)

```dart
@riverpod
class ContentItems extends _$ContentItems {
  @override
  FutureOr<List<ContentItem>> build({
    String? subjectId,
    String? educationalLevelId,
  }) async {
    final useCase = ref.read(getContentItemsUseCaseProvider);
    final result = await useCase(GetContentItemsParams(
      subjectId: subjectId,
      educationalLevelId: educationalLevelId,
    ));
    return result.when(
      success: (items) => items,
      failure: (failure) => throw failure,
    );
  }
}
```

---

## Local Database Patterns

### Sync Engine

The `SyncEngine` at `lib/core/sync/sync_engine.dart` manages offline-first synchronization:

1. **Queue Mutations**: When offline, mutations are stored in a local queue.
2. **Replay on Reconnect**: When connectivity is restored, queued mutations are replayed in order.
3. **Conflict Resolution**: Uses configurable strategies (`server_wins`, `client_wins`, `merge`, `manual`).

### Cache Manager

The `CacheManager` at `lib/core/storage/cache_manager.dart` provides a TTL-based caching layer:

```dart
// Write with 30-minute TTL
await cacheManager.write('levels_$schoolId', jsonData, ttl: Duration(minutes: 30));

// Read (returns null if expired)
final data = await cacheManager.read('levels_$schoolId');
```

### Local Database

The `LocalDatabase` at `lib/core/storage/local_database.dart` uses Hive boxes for structured offline storage:

```dart
// Store content items for offline access
await localDatabase.putBatch<ContentItemModel>(
  boxName: 'content_items',
  items: items,
  keyMapper: (item) => item.id!,
);
```

---

## Testing Guidelines

### Test Structure

Tests mirror the feature structure:

```
test/
├── features/
│   └── ccms/
│       ├── data/
│       │   ├── datasources/ccms_remote_datasource_test.dart
│       │   └── repositories/ccms_repository_impl_test.dart
│       ├── domain/
│       │   └── usecases/content_usecases_test.dart
│       └── presentation/
│           └── providers/ccms_provider_test.dart
```

### Unit Testing Use Cases

```dart
void main() {
  late GetContentItemsUseCase useCase;
  late MockCcmsRepository mockRepository;

  setUp(() {
    mockRepository = MockCcmsRepository();
    useCase = GetContentItemsUseCase(mockRepository);
  });

  test('returns content items on success', () async {
    final items = [ContentItem(...)];
    when(() => mockRepository.getContentItems())
        .thenAnswer((_) async => Result.success(items));

    final result = await useCase(GetContentItemsParams());

    expect(result.isSuccess, true);
    expect(result.data, items);
  });

  test('returns failure on error', () async {
    when(() => mockRepository.getContentItems())
        .thenAnswer((_) async => Result.failure(
              Failure.server(message: 'Server error', statusCode: 500),
            ));

    final result = await useCase(GetContentItemsParams());

    expect(result.isFailure, true);
  });
}
```

### Widget Testing

Use the `pumpApp` helper to wrap widgets with necessary providers:

```dart
testWidgets('ContentLibraryPage renders items', (tester) async {
  when(() => contentItemsProvider(any).build())
      .thenReturn(AsyncValue.data([testContentItem]));

  await tester.pumpApp(const ContentLibraryPage());

  expect(find.text('Test Question'), findsOneWidget);
});
```

### Integration Testing

Run integration tests against a real Supabase instance in the staging environment:

```bash
flutter test integration_test/ --dart-define=SUPABASE_URL=https://staging.supabase.co
```

---

## Code Style Conventions

### File Naming

- `snake_case.dart` for all Dart files
- `{feature}_{layer}_{descriptor}.dart` for feature files (e.g., `ccms_remote_datasource.dart`)

### Class Naming

- `PascalCase` for classes
- Entity classes: bare nouns (`ContentItem`, `Subject`)
- Model classes: suffixed with `Model` (`ContentItemModel`)
- Use case classes: suffixed with `UseCase` (`GetContentItemsUseCase`)
- Parameter classes: suffixed with `Params` (`GetContentItemsParams`)
- Provider classes: suffixed with `Provider` or use Riverpod code-gen

### Formatting

- Maximum line length: **80 characters**
- Use trailing commas for multi-line parameter lists
- One import per line, grouped in order: Dart SDK → Flutter → Packages → Project
- Use `// ─── Section Headers ───` pattern for long files

### Documentation

- All public classes and methods must have dartdoc comments
- Use `///` for documentation comments
- Include code examples in doc comments for non-trivial APIs

### Enum Conventions

- All enums must have `value` and `label` properties
- All enums must have a `fromString` static factory
- The `value` property must match the PostgreSQL enum value exactly

---

## Error Handling Patterns

### Exception Hierarchy

The core exception hierarchy is defined in `lib/core/errors/exceptions.dart`:

| Exception | Use Case |
|-----------|----------|
| `ServerException` | Non-2xx HTTP responses |
| `CacheException` | Local storage read/write failures |
| `AuthException` | Authentication/authorization failures |
| `NetworkException` | No network connectivity |
| `ValidationException` | Input validation failures with field-level errors |
| `NotFoundException` | 404 resource not found |
| `UnauthorizedException` | 401 not authenticated |
| `ForbiddenException` | 403 insufficient permissions |

### Failure Type

The `Failure` sealed class in `lib/core/errors/failures.dart` provides exhaustive pattern matching:

```dart
result.failure.when(
  server: (message, statusCode, data) => showErrorSnackbar('Server error: $message'),
  cache: (message) => showErrorSnackbar('Cache error: $message'),
  auth: (message, code) => navigateToLogin(),
  network: (message) => showOfflineBanner(),
  validation: (message, fieldErrors) => showFieldErrors(fieldErrors),
  notFound: (message) => navigateTo404(),
  unauthorized: (message) => navigateToLogin(),
  forbidden: (message) => showAccessDenied(),
);
```

### Result Type

All asynchronous operations return `Result<T>`:

```dart
sealed class Result<T> {
  const Result();
  factory Result.success(T data) = Success<T>;
  factory Result.failure(Failure failure) = Error<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Error<T>;

  T get data => (this as Success<T>).data;
  Failure get failure => (this as Error<T>).failure;

  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) failure,
  });
}
```

### Error Handling in the UI Layer

Providers catch failures and expose them as `AsyncValue` states:

```dart
@riverpod
class ContentLibrary extends _$ContentLibrary {
  @override
  FutureOr<List<ContentItem>> build() async {
    final result = await ref.read(getContentItemsUseCaseProvider)(
      GetContentItemsParams(limit: 50),
    );
    return result.when(
      success: (items) => items,
      failure: (failure) => throw failure,
    );
  }
}

// In the widget:
class ContentLibraryPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(contentLibraryProvider);
    return state.when(
      data: (items) => ContentList(items: items),
      loading: () => const LoadingSkeleton(),
      error: (error, _) => ErrorBanner(
        message: error is Failure
            ? error.when(
                server: (msg, _, __) => 'Server error: $msg',
                network: (msg) => 'You are offline',
                auth: (msg, _) => 'Please log in again',
                orElse: () => 'Something went wrong',
              )
            : 'Unexpected error',
        onRetry: () => ref.invalidate(contentLibraryProvider),
      ),
    );
  }
}
```

### Audit Trail for Errors

Critical errors should be recorded in the audit trail for debugging:

```dart
await repository.recordAuditEvent(AuditEntry(
  action: AuditAction.update,
  resourceType: 'content_item',
  resourceId: contentId,
  metadata: {'error': error.toString()},
));
```

---

## Appendix: File Quick Reference

| File | Purpose |
|------|---------|
| `supabase/migrations/ccms_enterprise_schema.sql` | Complete database schema with tables, indexes, RLS, functions, triggers |
| `lib/features/ccms/domain/entities/ccms_entities.dart` | All domain entities and enums |
| `lib/features/ccms/domain/repositories/ccms_repository.dart` | Repository contract (50+ methods) |
| `lib/features/ccms/data/datasources/ccms_remote_datasource.dart` | Supabase API calls |
| `lib/features/ccms/data/models/ccms_models.dart` | JSON serialization models |
| `lib/features/ccms/data/repositories/ccms_repository_impl.dart` | Error mapping and Result conversion |
| `lib/core/errors/exceptions.dart` | Exception hierarchy |
| `lib/core/errors/failures.dart` | Failure sealed union |
| `lib/core/utils/result.dart` | Result type |
| `lib/core/sync/sync_engine.dart` | Offline synchronization |
| `lib/core/storage/cache_manager.dart` | TTL-based caching |
| `lib/core/storage/local_database.dart` | Hive-based offline storage |
