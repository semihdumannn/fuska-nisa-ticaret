import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/order_entity.dart';
import '../repositories/i_order_repository.dart';

class GetOrdersUsecase {
  final IOrderRepository _repository;

  GetOrdersUsecase(this._repository);

  Future<Either<Failure, List<OrderEntity>>> call({
    int page = 1,
    int perPage = 20,
    OrderStatus? status,
  }) {
    return _repository.getOrders(
      page: page,
      perPage: perPage,
      status: status,
    );
  }
}
