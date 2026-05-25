import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/cart_entity.dart';
import '../repositories/i_cart_repository.dart';

class ApplyCouponUsecase {
  final ICartRepository _repository;

  ApplyCouponUsecase(this._repository);

  Future<Either<Failure, CartEntity>> call(String couponCode) {
    if (couponCode.trim().isEmpty) {
      return Future.value(const Left(ServerFailure('Kupon kodu boş olamaz')));
    }
    return _repository.applyCoupon(couponCode.trim().toUpperCase());
  }
}
