import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/order_entity.dart';
import '../repositories/i_order_repository.dart';

class CreateOrderInput {
  final List<Map<String, dynamic>> items;
  final int addressId;
  final String? notes;
  final String? couponCode;

  const CreateOrderInput({
    required this.items,
    required this.addressId,
    this.notes,
    this.couponCode,
  });
}

class CreateOrderUsecase {
  final IOrderRepository _repository;

  CreateOrderUsecase(this._repository);

  Future<Either<Failure, OrderEntity>> call(CreateOrderInput input) {
    if (input.items.isEmpty) {
      return Future.value(
        const Left(ServerFailure('Sipariş için en az 1 ürün gerekli')),
      );
    }
    return _repository.createOrder(
      items: input.items,
      addressId: input.addressId,
      notes: input.notes,
      couponCode: input.couponCode,
    );
  }
}
