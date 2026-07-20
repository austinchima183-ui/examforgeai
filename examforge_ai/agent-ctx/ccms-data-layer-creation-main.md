# CCMS Data Layer Creation

## Task
Create the Data Layer for the CCMS (Curriculum Content Management System) feature module.

## Files Created

### 1. `lib/features/ccms/data/models/ccms_models.dart`
- **32 model classes** mapping to all domain entities
- Each model has: `fromJson`, `toJson`, `fromEntity`, `toEntity`
- Handles both snake_case (Supabase) and camelCase JSON keys
- Proper nullable field handling
- Nested JSON conversion for `Map<String, dynamic>`, `List<Map<String, dynamic>>`, `List<String>`
- Complex ContentItemModel with all complex fields (options, correctAnswer, markingScheme, bodyRich, learningObjectiveIds, curriculumReferences, tags, mediaUrls, aiGenerationMetadata, metadata, licenseDetails)
- Enum fields convert to/from string values using `.value` property
- Helper functions: `_readField`, `_readDateTime`, `_readNullableDateTime`, `_readListOfMaps`, `_readNullableListOfMaps`, `_readListOfStrings`, `_readNullableListOfStrings`, `_readNullableMap`, `_readMap`, `_readNullableBloomList`

### 2. `lib/features/ccms/data/datasources/ccms_remote_datasource.dart`
- **Abstract class** `CcmsRemoteDataSource` with 60+ method signatures
- **Implementation** `CcmsRemoteDataSourceImpl` using Supabase client
- All methods follow Supabase patterns:
  - Table queries: `_supabase.from('table').select().eq('field', value).order('field')`
  - Inserts: `_supabase.from('table').insert(data).select().single()`
  - Updates: `_supabase.from('table').update(data).eq('id', id).select().single()`
  - Deletes: `_supabase.from('table').delete().eq('id', id)`
  - RPC calls: `_supabase.rpc('function_name', params: {'p_param': value})`
- Error handling via `_handlePostgrestError` mapping PostgrestException codes to custom exceptions
- Dynamic filter building for query methods
- Pagination support via `.range(offset, offset + limit - 1)`

### 3. `lib/features/ccms/data/repositories/ccms_repository_impl.dart`
- Implements `CcmsRepository` from domain layer
- Converts between entities and models
- Maps exceptions to `Failure` types via `_mapException` helper
- All 60+ repository methods fully implemented
- Wraps every operation in try/catch, returning `Result.success` or `FailureResult`
- Maps: AuthException→AuthFailure, ServerException→ServerFailure, NetworkException→NetworkFailure, ValidationException→ValidationFailure, NotFoundException→NotFoundFailure, UnauthorizedException→UnauthorizedFailure, ForbiddenException→ForbiddenFailure, FormatException→ServerFailure(422)

## Domain Layer Reference
- Entities: 32 classes in `ccms_entities.dart` with 15 enums
- Repository: `CcmsRepository` abstract class with 60+ methods across 13 domain areas
- Use Cases: 86 use cases across 13 files

## Architecture
Clean Architecture pattern: Domain → Data (Models, DataSources, RepositoryImpl)
- Models convert to/from domain Entities
- DataSources handle Supabase communication
- RepositoryImpl bridges domain contracts with data layer, handling error mapping
