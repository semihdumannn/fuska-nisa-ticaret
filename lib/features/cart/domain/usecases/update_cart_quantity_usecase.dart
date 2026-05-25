import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/cart_entity.dart';
import '../repositories/i_cart_repository.dart';

class UpdateCartQuantityUsecase {
  final ICartRepository _repository;

  UpdateCartQuantityUsecase(this._repository);

  Either<Failure, CartEntity> call(String itemId, int quantity) {
    if (quantity < 0) {
      return const Left(ServerFailure('Miktar negatif olamaz'));
    }
    return _repository.updateQuantity(itemId, quantity);
  }
}
