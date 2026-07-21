import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../data/repositories/marketplace_repository.dart';
import '../../../../features/marketplace/domain/repositories/marketplace_repository.dart';


class GetProductsParams {
  const GetProductsParams({
    this.status,
    this.productType,
    this.categoryId,
    this.sellerId,
    this.subject,
    this.classLevel,
    this.curriculum,
    this.search,
    this.sortBy,
    this.limit = 20,
    this.offset = 0,
  });
  final MarketplaceProductStatus? status;
  final MarketplaceProductType? productType;
  final String? categoryId;
  final String? sellerId;
  final String? subject;
  final String? classLevel;
  final String? curriculum;
  final String? search;
  final String? sortBy;
  final int limit;
  final int offset;
}

class GetProductsUseCase {
  GetProductsUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<List<MarketplaceProductEntity>>> call(GetProductsParams params) async {
    return _repository.getProducts(
      status: params.status,
      productType: params.productType,
      categoryId: params.categoryId,
      sellerId: params.sellerId,
      subject: params.subject,
      classLevel: params.classLevel,
      curriculum: params.curriculum,
      search: params.search,
      sortBy: params.sortBy,
      limit: params.limit,
      offset: params.offset,
    );
  }
}
