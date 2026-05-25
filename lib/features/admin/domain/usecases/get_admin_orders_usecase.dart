import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/admin_order_entity.dart';
import '../repositories/i_admin_repository.dart';

class GetAdminOrdersUsecase {
  final IAdminRepository _repository;
  GetAdminOrdersUsecase(this._repository);

  Future<Either<Failure, List<AdminOrderEntity>>> call({
    int page = 1,
    String? status,
    DateTime? from,
    DateTime? to,
  }) =>
      _repository.getOrders(page: page, status: status, from: from, to: to);
}
