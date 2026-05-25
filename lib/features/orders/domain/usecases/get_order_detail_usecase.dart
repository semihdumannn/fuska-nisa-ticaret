import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/order_entity.dart';
import '../repositories/i_order_repository.dart';

class GetOrderDetailUsecase {
  final IOrderRepository _repository;

  GetOrderDetailUsecase(this._repository);

  Future<Either<Failure, OrderEntity>> call(int id) {
    return _repository.getOrderDetail(id);
  }
}
