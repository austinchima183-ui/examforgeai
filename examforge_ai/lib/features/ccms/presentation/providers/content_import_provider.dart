import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/core.dart';
import '../../domain/entities/ccms_entities.dart';
import '../../domain/usecases/content_import_usecases.dart';

class ContentImportState extends Equatable {
  final List<ContentImport> imports;
  final ContentImport? currentImport;
  final bool isLoading;
  final String? error;

  const ContentImportState({this.imports = const [], this.currentImport, this.isLoading = false, this.error});

  ContentImportState copyWith({List<ContentImport>? imports, ContentImport? currentImport, bool? isLoading, String? error}) {
    return ContentImportState(imports: imports ?? this.imports, currentImport: currentImport ?? this.currentImport, isLoading: isLoading ?? this.isLoading, error: error);
  }

  @override
  List<Object?> get props => [imports, currentImport, isLoading, error];
}

class ContentImportNotifier extends StateNotifier<ContentImportState> {
  final CreateImportUseCase _createImportUseCase;
  final GetImportsUseCase _getImportsUseCase;
  final GetImportByIdUseCase _getImportByIdUseCase;

  ContentImportNotifier({
    required CreateImportUseCase createImportUseCase,
    required GetImportsUseCase getImportsUseCase,
    required GetImportByIdUseCase getImportByIdUseCase,
  })  : _createImportUseCase = createImportUseCase,
        _getImportsUseCase = getImportsUseCase,
        _getImportByIdUseCase = getImportByIdUseCase,
        super(const ContentImportState());

  Future<void> createImport(ContentImport importEntry) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _createImportUseCase(CreateImportParams(importEntry: importEntry));
    result.fold(
      onSuccess: (created) => state = state.copyWith(imports: [...state.imports, created], currentImport: created, isLoading: false),
      onFailure: (failure) => state = state.copyWith(isLoading: false, error: _mapFailureToMessage(failure)),
    );
  }

  Future<void> loadImports({String? schoolId, ImportStatus? status}) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getImportsUseCase(GetImportsParams(schoolId: schoolId, status: status));
    result.fold(
      onSuccess: (imports) => state = state.copyWith(imports: imports, isLoading: false),
      onFailure: (failure) => state = state.copyWith(isLoading: false, error: _mapFailureToMessage(failure)),
    );
  }

  Future<void> loadImportById(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getImportByIdUseCase(GetImportByIdParams(id: id));
    result.fold(
      onSuccess: (importEntry) => state = state.copyWith(currentImport: importEntry, isLoading: false),
      onFailure: (failure) => state = state.copyWith(isLoading: false, error: _mapFailureToMessage(failure)),
    );
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
