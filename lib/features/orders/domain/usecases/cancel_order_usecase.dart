import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/order_entity.dart';
import '../repositories/i_order_repository.dart';

class CancelOrderUsecase {
  final IOrderRepository _repository;

  CancelOrderUsecase(this._repository);

  Future<Either<Failure, OrderEntity>> call(int orderId) {
    return _repository.cancelOrder(orderId);
  }
}
