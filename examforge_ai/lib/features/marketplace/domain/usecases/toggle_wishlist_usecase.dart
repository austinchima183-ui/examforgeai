import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../domain/repositories/marketplace_repository.dart';
import '../../../../features/marketplace/domain/repositories/marketplace_repository.dart';


class ToggleWishlistParams {
  const ToggleWishlistParams({required this.userId, required this.productId});
  final String userId;
  final String productId;
}

class ToggleWishlistUseCase {
  ToggleWishlistUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<WishlistEntity>> call(ToggleWishlistParams params) async {
    final checkResult = await _repository.isInWishlist(params.userId, params.productId);
    return checkResult.fold(
      onSuccess: (isInWishlist) async {
        if (isInWishlist) {
          final wishlistResult = await _repository.getUserWishlist(params.userId);
          return wishlistResult.fold(
            onSuccess: (items) async {
              final match = items.where((i) => i.productId == params.productId).firstOrNull;
              if (match != null) {
                final removeResult = await _repository.removeFromWishlist(match.id);
                return removeResult.fold(
                  onSuccess: (_) => FailureResult<WishlistEntity>(
                    ServerFailure('Removed from wishlist'),
                  ),
                  onFailure: (f) => FailureResult<WishlistEntity>(f),
                );
              }
              return FailureResult<WishlistEntity>(
                ServerFailure('Wishlist item not found'),
              );
            },
            onFailure: (f) => FailureResult<WishlistEntity>(f),
          );
        } else {
          return _repository.addToWishlist(params.userId, params.productId);
        }
      },
      onFailure: (f) async => FailureResult<WishlistEntity>(f),
    );
  }
}
