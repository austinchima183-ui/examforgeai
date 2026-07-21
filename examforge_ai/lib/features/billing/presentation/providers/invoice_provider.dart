import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/billing_entities.dart';
import '../../domain/usecases/manage_invoices_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// INVOICE STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the invoice feature.
///
/// Tracks the list of invoices, the currently selected invoice,
/// receipts, PDF URLs, and loading/error states for invoice operations.
class InvoiceState {
  const InvoiceState({
    this.isLoading = false,
    this.invoices = const [],
    this.currentInvoice,
    this.receipts = const [],
    this.invoicePdfUrl,
    this.receiptPdfUrl,
    this.error,
  });

  /// Whether an async operation is in progress.
  final bool isLoading;

  /// The list of invoices.
  final List<InvoiceEntity> invoices;

  /// The currently selected invoice, or `null`.
  final InvoiceEntity? currentInvoice;

  /// The list of receipts.
  final List<ReceiptEntity> receipts;

  /// The PDF URL for the current invoice, or `null`.
  final String? invoicePdfUrl;

  /// The PDF URL for the current receipt, or `null`.
  final String? receiptPdfUrl;

  /// The most recent error message, or `null`.
  final String? error;

  /// Whether a current invoice is loaded.
  bool get hasCurrentInvoice => currentInvoice != null;

  /// Whether an invoice PDF URL is available.
  bool get hasInvoicePdfUrl => invoicePdfUrl != null;

  /// Whether a receipt PDF URL is available.
  bool get hasReceiptPdfUrl => receiptPdfUrl != null;

  /// Creates a copy of this state with the given fields replaced.
  InvoiceState copyWith({
    bool? isLoading,
    List<InvoiceEntity>? invoices,
    InvoiceEntity? currentInvoice,
    List<ReceiptEntity>? receipts,
    String? invoicePdfUrl,
    String? receiptPdfUrl,
    String? error,
  }) {
    return InvoiceState(
      isLoading: isLoading ?? this.isLoading,
      invoices: invoices ?? this.invoices,
      currentInvoice: currentInvoice ?? this.currentInvoice,
      receipts: receipts ?? this.receipts,
      invoicePdfUrl: invoicePdfUrl ?? this.invoicePdfUrl,
      receiptPdfUrl: receiptPdfUrl ?? this.receiptPdfUrl,
      error: error,
    );
  }

  /// Clears the current error message.
  InvoiceState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// INVOICE NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the invoice feature's state.
///
/// Supports loading invoices, viewing a single invoice, generating
/// invoices, loading receipts, and getting PDF URLs.
class InvoiceNotifier extends StateNotifier<InvoiceState> {
  InvoiceNotifier({
    required GetInvoicesUseCase getInvoicesUseCase,
    required GetInvoiceUseCase getInvoiceUseCase,
    required GenerateInvoiceUseCase generateInvoiceUseCase,
    required GetReceiptsUseCase getReceiptsUseCase,
    required GetInvoicePdfUrlUseCase getInvoicePdfUrlUseCase,
    required GetReceiptPdfUrlUseCase getReceiptPdfUrlUseCase,
  })  : _getInvoicesUseCase = getInvoicesUseCase,
        _getInvoiceUseCase = getInvoiceUseCase,
        _generateInvoiceUseCase = generateInvoiceUseCase,
        _getReceiptsUseCase = getReceiptsUseCase,
        _getInvoicePdfUrlUseCase = getInvoicePdfUrlUseCase,
        _getReceiptPdfUrlUseCase = getReceiptPdfUrlUseCase,
        super(const InvoiceState());

  final GetInvoicesUseCase _getInvoicesUseCase;
  final GetInvoiceUseCase _getInvoiceUseCase;
  final GenerateInvoiceUseCase _generateInvoiceUseCase;
  final GetReceiptsUseCase _getReceiptsUseCase;
  final GetInvoicePdfUrlUseCase _getInvoicePdfUrlUseCase;
  final GetReceiptPdfUrlUseCase _getReceiptPdfUrlUseCase;

  // ─── Load Invoices ─────────────────────────────────────────────────

  /// Loads the list of invoices.
  Future<void> loadInvoices({
    String? userId,
    String? schoolId,
    InvoiceStatus? status,
    required int page,
    required int perPage,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getInvoicesUseCase(
      GetInvoicesParams(
        userId: userId,
        schoolId: schoolId,
        status: status,
        page: page,
        perPage: perPage,
      ),
    );

    result.fold(
      onSuccess: (paginatedResult) {
        state = state.copyWith(
          isLoading: false,
          invoices: paginatedResult.items,
          error: null,
        );
        AppLogger.info(
          'Loaded ${paginatedResult.items.length} invoices',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load invoices: $failure');
      },
    );
  }

  // ─── Load Invoice ──────────────────────────────────────────────────

  /// Loads a single invoice by ID.
  Future<void> loadInvoice({required String invoiceId}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getInvoiceUseCase(
      GetInvoiceParams(invoiceId: invoiceId),
    );

    result.fold(
      onSuccess: (invoice) {
        state = state.copyWith(
          isLoading: false,
          currentInvoice: invoice,
          error: null,
        );
        AppLogger.info('Loaded invoice: $invoiceId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load invoice: $failure');
      },
    );
  }

  // ─── Generate Invoice ──────────────────────────────────────────────

  /// Generates a new invoice for a subscription.
  Future<void> generateInvoice({
    required String subscriptionId,
    required List<InvoiceLineItem> lineItems,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _generateInvoiceUseCase(
      GenerateInvoiceParams(
        subscriptionId: subscriptionId,
        lineItems: lineItems,
      ),
    );

    result.fold(
      onSuccess: (invoice) {
        final updatedList = [invoice, ...state.invoices];
        state = state.copyWith(
          isLoading: false,
          invoices: updatedList,
          currentInvoice: invoice,
          error: null,
        );
        AppLogger.info('Generated invoice: ${invoice.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to generate invoice: $failure');
      },
    );
  }

  // ─── Load Receipts ─────────────────────────────────────────────────

  /// Loads the list of receipts.
  Future<void> loadReceipts({
    required String userId,
    required int page,
    required int perPage,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getReceiptsUseCase(
      GetReceiptsParams(
        userId: userId,
        page: page,
        perPage: perPage,
      ),
    );

    result.fold(
      onSuccess: (paginatedResult) {
        state = state.copyWith(
          isLoading: false,
          receipts: paginatedResult.items,
          error: null,
        );
        AppLogger.info(
          'Loaded ${paginatedResult.items.length} receipts',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load receipts: $failure');
      },
    );
  }

  // ─── Get Invoice PDF URL ───────────────────────────────────────────

  /// Gets the PDF URL for an invoice.
  Future<void> getPdfUrl({required String invoiceId}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getInvoicePdfUrlUseCase(
      GetInvoicePdfUrlParams(invoiceId: invoiceId),
    );

    result.fold(
      onSuccess: (pdfUrl) {
        state = state.copyWith(
          isLoading: false,
          invoicePdfUrl: pdfUrl,
          error: null,
        );
        AppLogger.info('Got invoice PDF URL for: $invoiceId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to get invoice PDF URL: $failure');
      },
    );
  }

  // ─── Get Receipt PDF URL ───────────────────────────────────────────

  /// Gets the PDF URL for a receipt.
  Future<void> getReceiptPdfUrl({required String receiptId}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getReceiptPdfUrlUseCase(
      GetReceiptPdfUrlParams(receiptId: receiptId),
    );

    result.fold(
      onSuccess: (pdfUrl) {
        state = state.copyWith(
          isLoading: false,
          receiptPdfUrl: pdfUrl,
          error: null,
        );
        AppLogger.info('Got receipt PDF URL for: $receiptId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to get receipt PDF URL: $failure');
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Maps a [Failure] to a user-friendly error message.
  String _mapFailureToMessage(Failure failure) {
    return failure.when(
      server: (message, _, __) => message,
      cache: (message) => message,
      auth: (message, _) => message,
      network: (message) => message,
      validation: (message, _) => message,
      notFound: (message) => message,
      unauthorized: (message) => message,
      forbidden: (message) => message,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// INVOICE PROVIDER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod provider for the invoice feature.
///
/// The factory accepts all required use cases via named parameters.
final invoiceProvider =
    StateNotifierProvider<InvoiceNotifier, InvoiceState>(
  (ref) => InvoiceNotifier(
    getInvoicesUseCase: ref.watch(getInvoicesUseCaseProvider),
    getInvoiceUseCase: ref.watch(getInvoiceUseCaseProvider),
    generateInvoiceUseCase: ref.watch(generateInvoiceUseCaseProvider),
    getReceiptsUseCase: ref.watch(getReceiptsUseCaseProvider),
    getInvoicePdfUrlUseCase: ref.watch(getInvoicePdfUrlUseCaseProvider),
    getReceiptPdfUrlUseCase: ref.watch(getReceiptPdfUrlUseCaseProvider),
  ),
);
