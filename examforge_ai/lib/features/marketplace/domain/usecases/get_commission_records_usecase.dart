import '../../../../../core/errors/failures.dart';
import '../../../../../core/utils/result.dart';
import '../../entities/marketplace_entities.dart';
import '../../repositories/marketplace_repository.dart';

class GetCommissionRecordsParams {
  const GetCommissionRecordsParams({
    required this.sellerId,
    this.limit = 20,
    this.offset = 0,
  });
  final String sellerId;
  final int limit;
  final int offset;
}

class GetCommissionRecordsUseCase {
  GetCommissionRecordsUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<List<CommissionRecordEntity>>> call(GetCommissionRecordsParams params) async {
    if (params.sellerId.isEmpty) {
      return FailureResult(Failure.validation(message: 'Seller ID is required', code: 'EMPTY_ID'));
    }
    return _repository.getCommissionRecords(
      params.sellerId,
      limit: params.limit,
      offset: params.offset,
    );
  }
}
