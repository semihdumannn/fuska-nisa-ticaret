import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/order_entity.dart';
import '../repositories/i_order_repository.dart';

class UpdateOrderStatusUsecase {
  final IOrderRepository _repository;

  UpdateOrderStatusUsecase(this._repository);

  Future<Either<Failure, OrderEntity>> call({
    required int orderId,
    required OrderStatus newStatus,
    String? note,
  }) {
    return _repository.updateOrderStatus(
      orderId: orderId,
      newStatus: newStatus,
      note: note,
    );
  }
}
