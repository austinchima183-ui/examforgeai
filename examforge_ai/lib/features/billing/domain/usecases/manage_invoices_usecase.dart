import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/billing_entities.dart';
import '../../domain/repositories/billing_repository.dart';


// ─── Get Invoices ────────────────────────────────────────────────────────────

class GetInvoicesParams {
  const GetInvoicesParams({
    this.userId,
    this.schoolId,
    this.status,
    required this.page,
    required this.perPage,
  });

  final String? userId;
  final String? schoolId;
  final InvoiceStatus? status;
  final int page;
  final int perPage;
}

class GetInvoicesUseCase {
  GetInvoicesUseCase(this._repository);
  final BillingRepository _repository;

  Future<Result<List<InvoiceEntity>>> call(
    GetInvoicesParams params,
  ) async {
    if (params.page < 1) {
      return FailureResult(
        Failure.validation(fieldErrors: const {}, message: 'Page must be at least 1'),
      );
    }
    if (params.perPage < 1) {
      return FailureResult(
        Failure.validation(fieldErrors: const {}, message: 'Per page must be at least 1'),
      );
    }

    return _repository.getInvoices(
      userId: params.userId,
      schoolId: params.schoolId,
      status: params.status,
      page: params.page,
      perPage: params.perPage,
    );
  }
}

// ─── Get Invoice ─────────────────────────────────────────────────────────────

class GetInvoiceParams {
  const GetInvoiceParams({required this.invoiceId});
  final String invoiceId;
}

class GetInvoiceUseCase {
  GetInvoiceUseCase(this._repository);
  final BillingRepository _repository;

  Future<Result<InvoiceEntity>> call(GetInvoiceParams params) async {
    if (params.invoiceId.isEmpty) {
      return FailureResult(
        Failure.validation(fieldErrors: const {}, message: 'Invoice ID cannot be empty'),
      );
    }

    return _repository.getInvoice(params.invoiceId);
  }
}

// ─── Generate Invoice ────────────────────────────────────────────────────────

class GenerateInvoiceParams {
  const GenerateInvoiceParams({
    required this.subscriptionId,
    required this.lineItems,
  });

  final String subscriptionId;
  final List<InvoiceLineItem> lineItems;
}

class GenerateInvoiceUseCase {
  GenerateInvoiceUseCase(this._repository);
  final BillingRepository _repository;

  Future<Result<InvoiceEntity>> call(GenerateInvoiceParams params) async {
    if (params.subscriptionId.isEmpty) {
      return FailureResult(
        Failure.validation(fieldErrors: const {}, message: 'Subscription ID cannot be empty'),
      );
    }
    if (params.lineItems.isEmpty) {
      return FailureResult(
        Failure.validation(fieldErrors: const {}, message: 'Line items cannot be empty'),
      );
    }

    return _repository.generateInvoice(
      subscriptionId: params.subscriptionId,
      lineItems: params.lineItems,
    );
  }
}

// ─── Get Invoice PDF URL ─────────────────────────────────────────────────────

class GetInvoicePdfUrlParams {
  const GetInvoicePdfUrlParams({required this.invoiceId});
  final String invoiceId;
}

class GetInvoicePdfUrlUseCase {
  GetInvoicePdfUrlUseCase(this._repository);
  final BillingRepository _repository;

  Future<Result<String>> call(GetInvoicePdfUrlParams params) async {
    if (params.invoiceId.isEmpty) {
      return FailureResult(
        Failure.validation(fieldErrors: const {}, message: 'Invoice ID cannot be empty'),
      );
    }

    return _repository.getInvoicePdfUrl(params.invoiceId);
  }
}

// ─── Get Receipts ────────────────────────────────────────────────────────────

class GetReceiptsParams {
  const GetReceiptsParams({
    required this.userId,
    required this.page,
    required this.perPage,
  });

  final String userId;
  final int page;
  final int perPage;
}

class GetReceiptsUseCase {
  GetReceiptsUseCase(this._repository);
  final BillingRepository _repository;

  Future<Result<List<ReceiptEntity>>> call(
    GetReceiptsParams params,
  ) async {
    if (params.userId.isEmpty) {
      return FailureResult(
        Failure.validation(fieldErrors: const {}, message: 'User ID cannot be empty'),
      );
    }
    if (params.page < 1) {
      return FailureResult(
        Failure.validation(fieldErrors: const {}, message: 'Page must be at least 1'),
      );
    }
    if (params.perPage < 1) {
      return FailureResult(
        Failure.validation(fieldErrors: const {}, message: 'Per page must be at least 1'),
      );
    }

    return _repository.getReceipts(
      userId: params.userId,
      page: params.page,
      perPage: params.perPage,
    );
  }
}

// ─── Get Receipt PDF URL ─────────────────────────────────────────────────────

class GetReceiptPdfUrlParams {
  const GetReceiptPdfUrlParams({required this.receiptId});
  final String receiptId;
}

class GetReceiptPdfUrlUseCase {
  GetReceiptPdfUrlUseCase(this._repository);
  final BillingRepository _repository;

  Future<Result<String>> call(GetReceiptPdfUrlParams params) async {
    if (params.receiptId.isEmpty) {
      return FailureResult(
        Failure.validation(fieldErrors: const {}, message: 'Receipt ID cannot be empty'),
      );
    }

    return _repository.getReceiptPdfUrl(params.receiptId);
  }
}
