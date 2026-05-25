import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/cart_entity.dart';
import '../repositories/i_cart_repository.dart';

class RemoveFromCartUsecase {
  final ICartRepository _repository;

  RemoveFromCartUsecase(this._repository);

  Either<Failure, CartEntity> call(String itemId) {
    return _repository.removeItem(itemId);
  }
}
