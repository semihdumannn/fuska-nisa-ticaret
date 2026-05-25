import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/i_cart_repository.dart';

class ClearCartUsecase {
  final ICartRepository _repository;

  ClearCartUsecase(this._repository);

  Either<Failure, void> call() {
    return _repository.clearCart();
  }
}
