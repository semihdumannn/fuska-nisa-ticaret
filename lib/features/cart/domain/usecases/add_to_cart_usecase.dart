import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/cart_entity.dart';
import '../entities/cart_item_entity.dart';
import '../repositories/i_cart_repository.dart';

class AddToCartUsecase {
  final ICartRepository _repository;

  AddToCartUsecase(this._repository);

  Either<Failure, CartEntity> call(CartItemEntity item) {
    if (item.quantity <= 0) {
      return const Left(ServerFailure('Miktar 0\'dan büyük olmalı'));
    }
    if (item.unitPrice <= 0) {
      return const Left(ServerFailure('Geçersiz fiyat'));
    }
    return _repository.addItem(item);
  }
}
